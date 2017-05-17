#!/bin/bash
if [ ! -f ceph_preflight.sh ]
then
  wget https://raw.githubusercontent.com/ggpwnkthx/coach/master/docker/ceph/preflight.sh -O ceph_preflight.sh
fi
chmod +x ceph_preflight.sh
./ceph_preflight.sh
sudo apt-get -y install ceph-common
ceph_mon_ls=($(sudo ceph mon dump | grep mon | awk '{print $2}' | awk '{split($0,a,"/"); print a[1]}'))
ceph_mons=""
for i in ${ceph_mon_ls[@]}
do
  if [ -z $ceph_mons ]
  then
    ceph_mons="$i"
  else
    ceph_mons="$ceph_mons,$i"
  fi
done
if [ ! -d "/mnt" ]
then
  sudo mkdir /mnt
fi
if [ ! -d "/mnt/ceph" ]
then
  sudo mkdir /mnt/ceph
fi
if [ ! -d "/mnt/ceph/fs" ]
then
  sudo mkdir /mnt/ceph/fs
fi
if [ ! -z "$(systemctl | grep ceph_client.service)" ]
then
  sudo systemctl disable ceph_client.service
fi
sudo wget https://raw.githubusercontent.com/ggpwnkthx/coach/master/docker/ceph/client.service -O /etc/systemd/system/ceph_client.servic
sudo systemctl daemon-reload
sudo systemctl enable ceph_client.service
secret=$(sudo ceph-authtool -p /etc/ceph/ceph.client.admin.keyring)
if [ ! -z "$(systemctl | grep mnt-ceph-fs.automount)" ]
then
  sudo systemctl stop mnt-ceph-fs.automount
  sudo systemctl disable mnt-ceph-fs.automount
fi
sudo rm /etc/systemd/system/mnt-ceph-fs.automount
echo "[Unit]" | sudo tee /etc/systemd/system/mnt-ceph-fs.automount
echo "Description=Mount CephFS" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
echo "After=ceph_client.service" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
echo "[Mount]" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.mount
echo "What=$ceph_mons:/" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
echo "Where=/mnt/ceph/fs" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
echo "Type=ceph" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
echo "Options=name=admin,secret=$secret" | sudo tee --append /etc/systemd/system/mnt-ceph-fs.automount
sudo systemctl daemon-reload
sudo systemctl enable mnt-ceph-fs.automount
sudo systemctl start mnt-ceph-fs.automount