define :rds_swiss, \
  :rds_name => nil, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :db_security_group => nil, \
  :cidr => nil, \
  :enable => true \
do

  rds_name = params[:name]
  cidr = params[:cidr]

  include_recipe "awscli"
  require 'json'
  
  if params[:enable]
    ruby_block "authorize ingress for CIDR #{cidr} on #{rds_name}" do
      block do
        region=%x^curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent http://169.254.169.254/latest/meta-data/public-ipv4^+"/32" if cidr.nil?
        system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds authorize-db-security-group-ingress --db-security-group-name #{params[:db_security_group]} --cidrip #{cidr}")
      end
      only_if do
        region=%x^curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent http://169.254.169.254/latest/meta-data/public-ipv4^+"/32" if cidr.nil?
        str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds describe-db-security-groups --db-security-group-name #{params[:db_security_group]}^
        json=JSON.parse(str)
        json['DBSecurityGroups'].first['IPRanges'].none? { | cidrHash | 
          cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
        }
      end
    end
  else
     ruby_block "revoke ingress for CIDR #{cidr} on #{rds_name}" do
      block do
        region=%x^curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent http://169.254.169.254/latest/meta-data/public-ipv4^+"/32" if cidr.nil?
        system("AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds revoke-db-security-group-ingress --db-security-group-name #{params[:db_security_group]} --cidrip #{cidr}")
      end
      only_if do
        region=%x^curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone/^[0..-2]
        cidr=%x^curl --silent http://169.254.169.254/latest/meta-data/public-ipv4^+"/32" if cidr.nil?
        str=%x^AWS_ACCESS_KEY_ID=#{params[:aws_access_key_id]} AWS_SECRET_ACCESS_KEY=#{params[:aws_secret_access_key]} /usr/local/bin/aws --region #{region} rds describe-db-security-groups --db-security-group-name #{params[:db_security_group]}^
        json=JSON.parse(str)
        json['DBSecurityGroups'].first['IPRanges'].any? { | cidrHash | 
          cidrHash['CIDRIP'] == cidr && ["authorized", "authorizing"].include?(cidrHash['Status'])
        }
      end
    end
  end

end
