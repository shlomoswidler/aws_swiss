if node[:aws_swiss][:port].nil?
  
  # get cidrs for all instances in this OpsWorks Stack
  this_stacks_cidrs = []
  node[:opsworks][:layers].each { | layer_shortname, layer_desc|
    layer_desc[:instances].values.each{ |instance|
      cidr = instance[:elastic_ip]
      if cidr.nil?
        cidr = instance[:ip]
      end
      this_stacks_cidrs << (cidr + "/32")
    }
  }
  this_stacks_cidrs.sort!.uniq!
  
  Chef::Log.info("#{this_stacks_cidrs.size} cidrs in this stack: #{this_stacks_cidrs.join(',')}")

  swiss_rds_enforcer do
    aws_access_key_id     node[:aws_swiss][:aws_access_key_id]
    aws_secret_access_key node[:aws_swiss][:aws_secret_access_key]
    region                node[:opsworks][:instance][:region]
    cidr_list             this_stacks_cidrs
    security_group        node[:aws_swiss][:security_group]
    fallback_group        node[:aws_swiss][:fallback_group]
  end
end
