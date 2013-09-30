#/bin/bash

# Define some constants
ENFORCE_FLAG='--enforce';
KEY_NAME='installer';
HIGHLIGHT='tput setaf 3'
RESET_COLOR='tput sgr0';

## TODO: Get variables from a configuration file
# Define some variables
ip_address='192.168.56.101';
file_location='http://mirror.leaseweb.com/gentoo/releases/amd64/current-stage3/';
stage='stage3-amd64-20130822.tar.bz2';
contents="${stage}.CONTENTS";
digest="${stage}.DIGESTS";
downloader='curl -O --continue-at -';


# TODO: Elaborate more on the scripts functionality
message="\
--------------------------------------------------------------------------------\n\
The system with ip |$ip_address| will be bootstrapped. During this process\n\
it will create a partitioning scheme, create filesystems,... until the\n\
installation is ready to be continued by a real configuration automation\n\
framework like 'Puppet' or 'Chef'.\n\
--------------------------------------------------------------------------------\
";

echo -e $message;
[ "$1" == $ENFORCE_FLAG ] || {
  echo -e "\nPlease use the $ENFORCE_FLAG to apply the bootstrap.";
  exit 0;
};

# Create a key to drop into the live environment
echo 'First things first, lets create a key for our client to connect during
the installation: that way you only need to specify your password once.';

rm -iv ./$KEY_NAME ./${KEY_NAME}.pub;

echo $KEY_NAME | ssh-keygen -t rsa -q || {
  echo 'Failed creating a new key, exitting!';
  exit 1;
};

# Put it onto the environment
ssh-copy-id -i ./$KEY_NAME root@$ip_address || {
  echo 'Failed to copy the key to the live environment, exitting!';
  exit 1;
};

# Define a set commands to issue at the live environment
## TODO: Get partition variables from sysfiles
# cat /sys/block/sdb/queue/optimal_io_size
# cat /sys/block/sdb/queue/minimum_io_size
# cat /sys/block/sdb/alignment_offset
# cat /sys/block/sdb/queue/physical_block_size
## Add optimal_io_size to alignment_offset and divide the result by physical_block_size = startsector
## TODO: Add a sum to check on downloaded files...
## TODO: Look into the GCC optimization files...
parted="parted --align optimal --script /dev/sda --";
make_conf='/mnt/gentoo/etc/portage/make.conf';
declare -A setup_lines=(
  ['create_partition_partition_table']="$parted mklabel msdos mkpart primary 2048s 206848s set 1 boot on  mkpart primary 208896s 100%"
  ['create_filesystem']='mkfs.ext4 /dev/sda1; mkfs.ext4 /dev/sda2'
  ['mount_filesystems']="mkdir -pv /mnt/gentoo; mount /dev/sda2 /mnt/gentoo; mkdir -pv /mnt/gentoo/boot; mount /dev/sda1 /mnt/gentoo/boot"
  ['set_timestamp']="date $( date '+%m%d%H%M%y' )"
  ['install_stage']="cd /mnt/gentoo; $downloader $file_location$stage && $downloader $file_location$contents && $downloader $file_location$digest; tar xjpf stage3-*.tar.bz2; cd -;"
  ['configure_compile_options']="sed 's/CFLAGS=\"-O2 -pipe\"/CFLAGS=\"-march=native -O2  -pipe\"/g' $make_conf && echo 'MAKEOPTS=\"-j9\"' | tee --append $make_conf"
  ['add_mirror']="echo 'SYNC=\"rsync://rsync.nl.gentoo.org/gentoo-portage\"' | tee --append $make_conf"
  ['copy_dns']="cp -L /etc/resolv.conf /mnt/gentoo/etc/"
  ['mount_fses']="mount -v -t proc none /mnt/gentoo/proc && mount -v --rbind /sys /mnt/gentoo/sys && mount -v --rbind /dev /mnt/gentoo/dev"
);

order=(
  'create_partition_partition_table'
  'create_filesystem'
  'mount_filesystems'
  'set_timestamp'
  'install_stage'
  'configure_compile_options'
  'add_mirror'
  'copy_dns'
  'mount_fses'
);

## TODO: Adds failure check
for cmd in "${!order[@]}"; do
  rule=${order["$cmd"]};
  line=${setup_lines["$rule"]};

  $HIGHLIGHT;
  echo -e "[$rule] start >>";
  $RESET_COLOR;

  ssh -i ./$KEY_NAME root@$ip_address "$line";
  last=$?;

  $HIGHLIGHT;
  echo -e "[$rule] <<  stop";
  $RESET_COLOR;
  [ $last ] || exit $last;
done;

## TODO: Look into some clean chrooting options
scp -i ./$KEY_NAME ./chroot/configure_portage.bash root@$ip_address:/mnt/gentoo/;
ssh -i ./$KEY_NAME root@$ip_address "chmod +x /mnt/gentoo/configure_portage.bash";
ssh -i ./$KEY_NAME root@$ip_address "chroot /mnt/gentoo /configure_portage.bash";
