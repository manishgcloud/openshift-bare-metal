text
eula --agreed
install
cdrom
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone Etc/UTC --isUtc
rootpw Dell0SS!
auth --enableshadow --passalgo=sha512
services --enabled="chronyd"
firstboot --enable
%include /tmp/clearpart
zerombr
%include /tmp/bootdrive
volgroup vg00 pv.01
logvol swap --vgname=vg00 --name=swapvol --fstype=swap --size=4000
logvol / --vgname=vg00  --fstype=xfs  --size=80000 --name=lv_root
reboot

%pre
bootdrive=`readlink -f /dev/disk/by-id/*BOSS* | head -n 1`
echo clearpart --all --initlabel --drives=$bootdrive > /tmp/clearpart
echo part /boot --fstype ext4 --size=500 --ondisk=$bootdrive > /tmp/bootdrive
echo part /boot/efi --fstype vfat --size=200 --ondisk=$bootdrive >> /tmp/bootdrive
echo part pv.01 --size=100000 --grow --ondisk=$bootdrive >> /tmp/bootdrive
mdadm --create -R /dev/md0 --metadata=0.90 --level=1 --raid-devices=2 /dev/nvme0n1 /dev/nvme1n1 >> /tmp/dockerstorage
sed -i s/"md_component_detection = 1"/"md_component_detection = 0"/ /etc/lvm/lvm.conf >> /tmp/dockerstorage
pvcreate /dev/md0 >> /tmp/dockerstorage
vgcreate docker-vg /dev/md0 >> /tmp/dockerstorage
%end

%packages
@^minimal
@core
chrony
kexec-tools
net-tools
wget
git
tcpdump
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

%post --erroronfail
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0
ONBOOT=yes
BOOTPROTO=none
IPADDR=192.168.20.42
NETMASK=255.255.255.0
USERCTL=no
NM_CONTROLLED=yes
PEERDNS=yes
BONDING_OPTS="mode=802.3ad miimon=100 xmit_hash_policy=layer3+4 lacp_rate=1"
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0.421
DEVICE=bond0.421
IPADDR=100.82.42.42
NETMASK=255.255.255.0
GATEWAY=100.82.42.1
DNS1=100.82.42.8
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
USERCTL=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0.10
DEVICE=bond0.10
IPADDR=192.168.10.10
NETMASK=255.255.255.0
GATEWAY=192.168.10.1
ONBOOT=yes
VLAN=yes
BOOTPROTO=none
USERCTL=no
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
DEVICE=em1
ONBOOT=yes
MASTER=bond0
BOOTPROTO=none
SLAVE=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em2
DEVICE=em2
ONBOOT=yes
MASTER=bond0
BOOTPROTO=none
SLAVE=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-p2p1
DEVICE=p2p1
ONBOOT=yes
MASTER=bond0
BOOTPROTO=none
SLAVE=yes
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-p2p2
DEVICE=p2p2
ONBOOT=yes
MASTER=bond0
BOOTPROTO=none
SLAVE=yes
EOF

cat << EOF > /etc/hostname
bastion.example.com
EOF
%end
