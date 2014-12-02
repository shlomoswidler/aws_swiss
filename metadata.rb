name             'aws_swiss'
maintainer       'Shlomo Swidler'
maintainer_email 'shlomo.swidler@orchestratus.com'
license          'Apache 2.0'
description      "Dynamically poke holes in EC2 and RDS security groups"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.3.0'

supports "ubuntu", ">= 12.04"

depends "awscli", ">= 0.4.0"

recipe "poke", "open a hole for this server"
recipe "plug", "remove the hole for this server"
recipe "enforce", "enforce a CIDR list on the security groups"
