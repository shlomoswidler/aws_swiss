define :swiss_rds_enforcer, \
  :aws_access_key_id => nil, \
  :aws_secret_access_key => nil, \
  :region => nil, \
  :cidr_list => nil, \
  :security_group_list => nil \
do

  security_group_list = params[:security_group_list]
  if security_group_list.is_a? String
    security_group_list = security_group_list.split(',')
  end
  cidr_list = params[:cidr_list]
  if cidr_list.is_a? String
    cidr_list = cidr_list.split(',')
  end
  
  ruby_block "enforce rds security group holes for security groups #{security_group_list.join(',')}" do
    block do
      holes = security_group_list.reduce([]) {|result, group|
        result << SecurityGroupHoleController.get_rds_cidr_holes(group, params[:region], params[:aws_access_key_id], params[:aws_secret_access_key])
        result
      }
  
      Chef::Log.info("#{holes.size} existing holes: #{holes.sort.join(',')}")
      
      confirmed_holes, extra_holes = holes.partition {|cidr| cidr_list.include?(cidr) }
      more_confirmed_holes, missing_holes = cidr_list.partition {|cidr| holes.include?(cidr) }
      
      # TODO: plug extra_holes (may require moving functionality into the library module)
      Chef::Log.info("#{extra_holes.size} extra holes: #{extra_holes.sort.join(',')}")
      
      # TODO: poke missing_holes (likewise)
      Chef::Log.info("#{missing_holes.size} missing holes: #{missing_holes.sort.join(',')}")
      
    end
  end
  
  
end
