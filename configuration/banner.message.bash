message="\
--------------------------------------------------------------------------------\n\
The system with ip |$ip_address| will be bootstrapped. During this process\n\
it will create a partitioning scheme, create filesystems,... until the\n\
installation is ready to be continued by a real configuration automation\n\
framework like 'Puppet' or 'Chef'.\n\n\
Variables and function loaded:\n\
------------------------------\n\
Ip address target host: ${ip_address}.\n\
General file location: ${file_location}.\n\
Files specified:\n\
  - ${stage}.\n\
  - ${contents}.\n\
  - ${digest}.\n\
Downloader and args to be used: ${downloader}.\n\
--------------------------------------------------------------------------------\
";

