rds_swiss
=========

Dynamically poke holes in EC2-Classic RDS instances' security groups. There are many reasons you would want to keep your AWS RDS DB instances running in an EC2-Classic account, even though they are accessed from within EC2-VPC instances. Several reasons:

1. You can access EC2-Classic RDS DB instances from any other server in the same AWS region. This means you can allow access to the DB instance from multiple AWS accounts.
2. As a corrolary, you can therefore easily share DB Snapshots between accounts, such as moving RDS DB Snapshots from Production to Development.
3. It doesn't cost much extra.

Copyright &copy; 2014 Shlomo Swidler.

Licensed under the Apache 2.0 license.

Issues? https://github.com/shlomoswidler/rds_swiss/issues

# Usage


# Configuration
