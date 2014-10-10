define :aws_swiss, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :cidr => nil, \
  :ports => nil, \
  :rds_name => nil, \
  :enable => true \
do

  security_group = params[:name]
  rds_name = params[:rds_name]
  cidr = params[:cidr]
  ports = params[:ports]
  
  raise "Illegal use of aws_swiss definition: only one of 'ports' and 'rds_name' must be specified" if rds_name.nil? == ports.nil?
  
  from_port = port.to_s
  to_port = port.to_s
  if ports=="all"
    from_port = "1"
    to_port = "65535"
  else if ports[/([0-9]+)-([0-9]+)/, 1] && ports[/([0-9]+)-([0-9]+)/, 2]
    from_port = ports[/([0-9]+)-([0-9]+)/, 1]
    to_port = ports[/([0-9]+)-([0-9]+)/, 2]
  end
  
  is_group_name = security_group[/sg-([0-9a-f]{8})/, 1].nil?
  if is_group_name
    group_arg_name = "group-name"
  else
    group_arg_name = "group-id"
  end
  
  target_name = "CIDR #{cidr}" + (ports.nil? ? "" : " ports #{ports}") + " to " +
    (ports.nil? ? "rds instance #{rds_name} " : "") +  "security group #{security_group}"

  aws_instance_metadata_url = "http://169.254.169.254/latest/meta-data"

  include_recipe "awscli"
  require 'json'
  
  if params[:enable]
    ruby_block "authorize ingress for #{target_name}" do
      block do
        region=%x^curl --silent #{aws_instance_metadata_url}/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent #{aws_instance_metadata_url}/public-ipv4^+"/32" if cidr.nil?
        if ports.nil?
          system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds authorize-db-security-group-ingress --db-security-group-name #{security_group} --cidrip #{cidr}")
        else
          system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} ec2 authorize-security-group-ingress --#{group_arg_name} #{security_group} --cidr #{cidr} --protocol tcp --from-port #{from_port} --to-port #{to_port}")
        end
      end
      only_if do
        region=%x^curl --silent #{aws_instance_metadata_url}/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent #{aws_instance_metadata_url}/public-ipv4^+"/32" if cidr.nil?
        if ports.nil?
          str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds describe-db-security-groups --db-security-group-name #{security_group}^
          json=JSON.parse(str)
          json['DBSecurityGroups'].first['IPRanges'].none? { | cidrHash | 
            cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
          }
        else
          str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} ec2 describe-security-groups --#{group_arg_name}s #{security_group}^
          json=JSON.parse(str)
          json['SecurityGroups'].first['IpPermissions'].none? { |hole|
            hole['ToPort']==to_port && hole['FromPort']==from_port && hole['IpProtocol']="tcp" && hole['IpRanges'].any? { |cidrMap| cidrMap['CidrIp']=cidr}
          }
        end
      end
    end
  else
     ruby_block "revoke ingress for #{target_name}" do
      block do
        region=%x^curl --silent #{aws_instance_metadata_url}/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent #{aws_instance_metadata_url}/public-ipv4^+"/32" if cidr.nil?
        if ports.nil?
          system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds revoke-db-security-group-ingress --db-security-group-name #{security_group} --cidrip #{cidr}")
        else
          system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} ec2 revoke-security-group-ingress --#{group_arg_name} #{security_group} --cidr #{cidr} --protocol tcp --from-port #{from_port} --to-port #{to_port}")
        end
      end
      only_if do
        region=%x^curl --silent#{aws_instance_metadata_url}/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent #{aws_instance_metadata_url}/public-ipv4^+"/32" if cidr.nil?
        if ports.nil?
          str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds describe-db-security-groups --db-security-group-name #{security_group}^
          json=JSON.parse(str)
          json['DBSecurityGroups'].first['IPRanges'].any? { | cidrHash | 
            cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
          }
        else
          str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} ec2 describe-security-groups --#{group_arg_name}s #{security_group}^
          json=JSON.parse(str)
          json['SecurityGroups'].first['IpPermissions'].any? { |hole|
            hole['ToPort']==to_port && hole['FromPort']==from_port && hole['IpProtocol']="tcp" && hole['IpRanges'].any? { |cidrMap| cidrMap['CidrIp']=cidr}
          }
        end
      end
    end
  end

end
