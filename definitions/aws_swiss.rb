define :aws_swiss, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :cidr => nil, \
  :port => nil, \
  :enable => true, \
  :fallback_group => nil \
do

  security_group = params[:name]
  cidr = params[:cidr]
  port = params[:port]
  fallback_group = params[:fallback_group]
  
  if !port.nil?
    port = port.to_s
  end
  
  is_group_name = security_group[/sg-([0-9a-f]{8})/, 1].nil?
  if is_group_name
    group_arg_name = "group-name"
  else
    group_arg_name = "group-id"
  end
  if !fallback_group.nil?
    fallback_is_group_name = fallback_group[/sg-([0-9a-f]{8})/, 1].nil?
    if fallback_is_group_name
      fallback_group_arg_name = "group-name"
    else
      fallback_group_arg_name = "group-id"
    end
  end
  
  aws_instance_metadata_url = "http://169.254.169.254/latest/meta-data"
  region=%x"curl --silent #{aws_instance_metadata_url}/placement/availability-zone/"[0..-2]
  cidr=%x"curl --silent #{aws_instance_metadata_url}/public-ipv4"+'/32' if cidr.nil? || cidr.size==0
  
  command_base = ""
  if !params[:aws_access_key_id].nil? && !params[:aws_secret_access_key].nil?
    command_base = "AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} "
  end
  command_base << "/usr/local/bin/aws --region #{region} "

  target_name = "CIDR #{cidr}" + (port.nil? ? "" : " port #{port}") + " to " +
    (port.nil? ? "RDS DB " : "") +  "security group #{security_group}"

  include_recipe "awscli"
  require 'json'
  
  if params[:enable] # authorize
    if port.nil? # RDS security group
      ruby_block "authorize RDS ingress for #{target_name}" do
        block do
          if !SecurityGroupHoleController.open_rds_hole_if_necessary(security_group, cidr, region, params[:aws_access_key_id], params[:aws_secret_access_key])
            # failed to poke hole in specified security group
            if !fallback_group.nil?
              Chef::Log.info("Trying to poke hole in fallback security group #{fallback_group}")
              if !SecurityGroupHoleController.open_rds_hole_if_necessary(fallback_group, cidr, region, params[:aws_access_key_id], params[:aws_secret_access_key])
                # failed fallback also
                raise "Failed to poke hole in fallback security group #{fallback_group}"
              end
            else
              # no fallback security group
              raise "Failed to poke hole in RDS security group #{security_group} and no fallback group specified"
            end
          end
        end
      end
    else # EC2 security group
      ruby_block "authorize EC2 ingress for #{target_name}" do
        block do
          system(command_base + "ec2 authorize-security-group-ingress --#{group_arg_name} #{security_group} --cidr #{cidr} --protocol tcp --port #{port}")
        end
        only_if do
          str=%x^#{command_base} ec2 describe-security-groups --#{group_arg_name}s #{security_group} --query 'SecurityGroups[0].IpPermissions[*].{FromPort:FromPort, ToPort:ToPort, Protocol:IpProtocol, CIDRs:IpRanges[*].CidrIp}'^
          json=JSON.parse(str)
          json.none? { |hole|
            hole['ToPort']==port.to_i && hole['FromPort']==port.to_i && hole['Protocol']="tcp" && hole['CIDRs'].include?(cidr)
          }
        end
      end
    end
  else # revoke
    if port.nil? # RDS security group
      ruby_block "revoke RDS ingress for #{target_name}" do
        block do
          system(command_base + "rds revoke-db-security-group-ingress --db-security-group-name #{security_group} --cidrip #{cidr}")
        end
        only_if do
          str=%x^#{command_base} rds describe-db-security-groups --db-security-group-name #{security_group}^
          json=JSON.parse(str)
          json['DBSecurityGroups'].first['IPRanges'].any? { | cidrHash | 
            cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
          }
        end
      end
    else # EC2 security group
      ruby_block "revoke EC2 ingress for #{target_name}" do
        block do
          system(command_base + "ec2 revoke-security-group-ingress --#{group_arg_name} #{security_group} --cidr #{cidr} --protocol tcp --port #{port}")
        end
        # non-existent ingress can be revoked without any error, so no only_if guard here
      end
    end
  end

end
