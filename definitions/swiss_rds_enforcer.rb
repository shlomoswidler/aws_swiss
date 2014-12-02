define :swiss_rds_enforcer, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :region => nil, \
  :cidr_list => nil, \
  :security_group => nil, \
  :fallback_group => nil \
do
  if params[:security_group].nil?
    raise "swiss_rds_enforcer definition: security_group must be specified"
  end
  
  security_group_list = [ params[:security_group] ]
  if params[:fallback_group]
    security_group_list << params[:fallback_group]
  end
  cidr_list = params[:cidr_list]
  if cidr_list.is_a? String
    cidr_list = cidr_list.split(',')
  end
  
  ruby_block "enforce rds security group holes for security groups #{security_group_list.join(',')}" do
    block do
      holes = security_group_list.reduce([]) {|result, group|
        result = result + SecurityGroupHoleController.get_rds_cidr_holes(group, params[:region], params[:aws_access_key_id], params[:aws_secret_access_key])
        result
      }
  
      Chef::Log.info("#{holes.size} existing holes: #{holes.sort.join(',')}")
      
      confirmed_holes, extra_holes = holes.partition {|cidr| cidr_list.include?(cidr) }
      more_confirmed_holes, missing_holes = cidr_list.partition {|cidr| holes.include?(cidr) }
      
      Chef::Log.info("Plugging #{extra_holes.size} extra holes: #{extra_holes.sort.join(',')}")
      extra_holes.each { |cidr|
        SecurityGroupHoleController.close_rds_hole_with_fallback(params[:security_group], params[:fallback_group], cidr, params[:region], params[:aws_access_key_id], params[:aws_secret_access_key])
      }
      
      Chef::Log.info("Poking #{missing_holes.size} missing holes: #{missing_holes.sort.join(',')}")
      missing_holes.each { |cidr|
        SecurityGroupHoleController.open_rds_hole_with_fallback(params[:security_group], params[:fallback_group], cidr, params[:region], params[:aws_access_key_id], params[:aws_secret_access_key])
      }
    end
  end
  
  
end
