rds_swiss node[:rds_swiss][:rds_name] do
  aws_access_key_id     node[:rds_swiss][:aws_access_key_id]
  aws_secret_access_key node[:rds_swiss][:aws_secret_access_key]
  db_security_group     node[:rds_swiss][:db_security_group]
  enable                false
end
