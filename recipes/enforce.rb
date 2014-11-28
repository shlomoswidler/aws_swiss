if node[:aws_swiss][:port].nil?

  this_layers_cidrs = node[:opsworks][:layers][ node[:opsworks][:instance][:layers].first ][:instances].reduce([]) { |result, instance|
    result << (instance.values.first[:ip] + "/32")
    result
  }
  
  Chef::Log.info("cidrs in this layer: #{this_layers_cidrs.join(',')}")

  swiss_rds_enforcer do
    aws_access_key_id     node[:aws_swiss][:aws_access_key_id]
    aws_secret_access_key node[:aws_swiss][:aws_secret_access_key]
    region                node[:opsworks][:instance][:region]
    cidr_list             this_layers_cidrs
    security_group_list   [ node[:aws_swiss][:security_group], node[:aws_swiss][:fallback_group] ]
  end
end
