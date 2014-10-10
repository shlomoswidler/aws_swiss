aws_swiss node[:aws_swiss][:security_group] do
  aws_access_key_id     node[:aws_swiss][:aws_access_key_id]
  aws_secret_access_key node[:aws_swiss][:aws_secret_access_key]
  rds_name              node[:aws_swiss][:rds_name] # May be nil - but at least one of 'ports' or 'rds_name' must be given
  ports                 node[:aws_swiss][:ports]    # May be nil - but at least one of 'ports' or 'rds_name' must be given
  enable                true
end
