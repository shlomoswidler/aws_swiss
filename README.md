rds_swiss
=========

Dynamically poke holes in EC2-Classic RDS instances' security groups. There are many reasons you would want to keep your AWS RDS DB instances running in an EC2-Classic account, even though they are accessed from within EC2-VPC instances. Several reasons:

1. You can access EC2-Classic RDS DB instances from any other server in the same AWS region. This means you can allow access to the DB instance from multiple AWS accounts.
2. As a corrolary, you can therefore easily share DB Snapshots between accounts, such as moving RDS DB Snapshots from Production to Development.
3. It doesn't cost much extra.

The holes poked (and plugged) enable access to a CIDR.

Copyright &copy; 2014, Shlomo Swidler.

Licensed under the Apache 2.0 license.

Issues? https://github.com/shlomoswidler/rds_swiss/issues

# Usage

This cookbook provides a Definition `rds_swiss` that can be used directly. This cookbook also provides two convenience recipes, which can be used to poke or plug holes for the current server.

## Definition: rds_swiss

Use this definition inside a recipe as follows:

````

````

## Convenience Recipe: poke

The `poke` recipe enables a security group ingress for the current server's public IP address.

## Convenience Recipe: plug

The `plug` recipe revokes the security group ingress for the current server's public IP addess.

# Configuration

The convenience recipes `poke` and `plug` require the following configuration:

````
"rds_swiss": {
  "aws_access_key_id":     "AWS Access Key ID",
  "aws_secret_access_key": "AWS Secret Access Key",
  "db_security_group":     "name-of-the-db-security-group"
}
````
The AWS credentials specified in `[:rds_swiss][:aws_access_key_id]` and `[:rds_swiss][:aws_secret_access_key]` must have the following API actions authorized on the account controlling the RDS DB instance:

*  rds:AuthorizeDBSecurityGroupIngress
*  rds:DescribeDBSecurityGroups
*  rds:RevokeDBSecurityGroupIngress

For `db_security_group` it is recommended to use a specially designated DB security Group in order to isolate the dynamic authorizations from any others. For example, your RDS DB instance's "main" DB security Group may be named `db-prod` and allow access to your EC2 Security Groups `web` and `jenkins`. Don't use that group in rds_swiss. Instead, your RDS DB instance should also have an additional DB Security Group `db-prod-swiss`, which should be used by rds_swiss. 
