aws_swiss
=========

Dynamically poke holes in EC2 security groups and RDS DB security groups. 

There are many reasons you would want to keep your AWS instances and RDS DB instances running in an EC2-Classic account, even though they are accessed from within EC2-VPC instances. Several reasons:

1. You can access EC2-Classic instances from any other server in the same AWS region. This means you can allow access to the DB instance from multiple AWS accounts.
2. As a corollary, you can therefore easily share DB Snapshots between accounts, such as moving RDS DB Snapshots from Production to Development.
3. It doesn't cost much extra.

Typical approaches to building this setup require that each app server use an Elastic IP, in order to pre-authorize and tightly control the Security Group ingresses. But Elastic IP addresses are scarce commodities, they cost you money when not in use, and they cannot be used effectively with auto-scaling pools of app servers.

aws_swiss allows you to dynamically authorize and revoke CIDR ingresses in a EC2 or DB Security Group, which allows you to operate the above kind of setup securely without resorting to Elastic IP addresses.

Copyright &copy; 2014, Shlomo Swidler.

Licensed under the Apache 2.0 license.

Issues? https://github.com/shlomoswidler/aws_swiss/issues

# Usage

This cookbook provides two Definition `aws_swiss` that can be used directly. This cookbook also provides two convenience recipes, which can be used to poke or plug holes for the current server.

## Definition: aws_swiss

To poke a hole in an EC2 security group, use this definition as follows: 

````
aws_access_key = "AKIA....."
aws_secret_key = "Ssshhhhh."
security_group = "prod-db-swiss"
cidr           = "1.2.3.4/32"

aws_swiss security_group do
  aws_access_key_id     aws_access_key # optional
  aws_secret_access_key aws_secret_key # optional
  port                  3306
  cidr                  cidr
  enable                true           # false to revoke
end

````

To poke a hole in an RDS DB Security Group, specify the `rds_name` attribute and omit the `port` attribute, as follows:

````
aws_access_key = "AKIA....."
aws_secret_key = "Ssshhhhh."
security_group = "db-prod-swiss"
cidr           = "1.2.3.4/32"

aws_swiss security_group do
  aws_access_key_id     aws_access_key # optional
  aws_secret_access_key aws_secret_key # optional
  rds_name              "my-rds-instance-name"
  cidr                  cidr
  enable                true           # false to revoke
end
````

The `security_group` designation can be specified either as a security group name (for EC2 Classic security groups, or for security groups in the default VPC) or as a security group ID (for VPC security groups). It is recommended to use a specially designated Security Group in order to isolate the dynamic ingresses from any others. For example, your instance's "main" Security Group may be named `db-prod` and allow access to your EC2 Security Groups `web` and `jenkins`. Don't use that group in `aws_swiss`. Instead, your instance should also have an additional Security Group such as `db-prod-swiss` in which `aws_swiss` will create and remove holes.

You can omit the `cidr` attribute, in which case the CIDR IP will be the instance's public IP address reported by the AWS Instance Metadata, with a mask of `/32`.

You can omit the `enable` attribute, whose default value is `true`.

You can omit the `aws_access_key_id` and `aws_secret_access_key` attributes, in which case the invocation of the `aws cli` will rely on the instance role's permissions. See below for the exact permissions required.

## Convenience Recipe: poke

The `poke` recipe enables a security group ingress for the current server's public IP address.

## Convenience Recipe: plug

The `plug` recipe revokes the security group ingress for the current server's public IP addess.

# Configuration

The convenience recipes `poke` and `plug` require the following configuration:

````
"aws_swiss": {
  "aws_access_key_id":     "AWS Access Key ID",
  "aws_secret_access_key": "AWS Secret Access Key",
  "security_group":        "security-group-name-or-ID",
  "rds_name":              "short-name-of-rds-instance",
  "port":                  "3306"
}
````
**In the above JSON, only specify one of the `port` or `rds_name` options.**
Also, the `aws_access_key_id` and `aws_secret_access_key` JSON settings are optional.

## AWS Credentials

The AWS credentials used (either specified by the `aws_access_key_id` and `aws_secret_access_key` attributes or used by the `aws cli` via the instance's role) must have the following API actions authorized on the account controlling the security group:

For EC2 Security Groups:

* ec2:AuthorizeSecurityGroupIngress
* ec2:DescribeSecurityGroups
* ec2:RevokeSecurityGroupIngress

For RDS DB Security Groups:

* rds:AuthorizeDBSecurityGroupIngress
* rds:DescribeDBSecurityGroups
* rds:RevokeDBSecurityGroupIngress
