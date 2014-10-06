name             'rds_swiss'
maintainer       'Shlomo Swidler'
maintainer_email 'shlomo.swidler@orchestratus.com'
license          'Apache 2.0'
description      "Dynamically poke holes in EC2-Classic RDS instances' security groups"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports "ubuntu", ">= 12.04"
supports "amazon", ">= 2014.03"

depends "awscli", ">= 0.4.0"

recipe "poke", "open a hole for this server"
recipe "plug", "remove the hole for this server"
