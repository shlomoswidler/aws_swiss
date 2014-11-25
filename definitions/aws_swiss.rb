define :aws_swiss, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :cidr => nil, \
  :port => nil, \
  :rds_name => nil, \
  :enable => true, \
  :fallback_group => nil \
do

  security_group = params[:name]
  rds_name = params[:rds_name]
  cidr = params[:cidr]
  port = params[:port]
  fallback_group = params[:fallback_group]
  
  raise "Illegal use of aws_swiss definition: only one of 'port' and 'rds_name' must be specified" if rds_name.nil? == port.nil?
  
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
    (port.nil? ? "rds instance #{rds_name} " : "") +  "security group #{security_group}"

  include_recipe "awscli"
  require 'json'
  
  if params[:enable] # authorize
    if port.nil? # RDS security group
      ruby_block "authorize RDS ingress for #{target_name}" do
        block do
          str=%x^#{command_base} rds describe-db-security-groups --db-security-group-name #{security_group}^
          json=JSON.parse(str)
          if json['DBSecurityGroups'].first['IPRanges'].none? { | cidrHash | 
            cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
            }
            shell = Mixlib::ShellOut.new(command_base + "rds authorize-db-security-group-ingress --db-security-group-name #{security_group} --cidrip #{cidr}")
            shell.run_command
            if !shell.exitstatus
              # failed to poke hole.
              if !fallback_group.nil?
                Chef::Log.info('STDOUT:' + shell.stdout)
                Chef::Log.info('STDERR:'+ shell.stderr)
                Chef::Log.info("There are #{json['DBSecurityGroups'].first['IPRanges'].size} holes in the security group #{security_group}")
                # try the fallback SG
                shell = Mixlib::ShellOut.new(command_base + "rds authorize-db-security-group-ingress --db-security-group-name #{fallback_group} --cidrip #{cidr}")
                shell.run_command
              end
              if !shell.exitstatus
                # failed to poke hole and fallback not specified or also failed.
                Chef::Log.info('STDOUT' + shell.stdout)
                Chef::Log.fatal('STDERR' + shell.stderr)
                Chef::Log.info("There are #{json['DBSecurityGroups'].first['IPRanges'].size} holes in the security group #{security_group}")
                false
              end
            end
            if shell.exitstatus
              Chef::Log.info(shell.stdout)
              true
            end
          else
            Chef::Log.info("RDS ingress for #{target_name} already exists.")
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
