#/bin/bash
if [ -z "$(command -v ceph-deploy)" ]
then
  echo "ceph-deploy is not installed on this node"
  exit
fi

if [ -z $1 ]
then
  fs="cephfs"
  data="cephfs_data"
  meta="cephfs_meta"
else
  fs="$1"
  data="$1_data"
  meta="$1_meta"
fi

wget https://raw.githubusercontent.com/ggpwnkthx/coach/master/services/ceph/admin.sh -O services_ceph_admin.sh
chmod +x services_ceph_admin.sh
./services_ceph_admin.sh

cd ~/ceph
ceph-deploy mds create $HOSTNAME

if [ -z "$(sudo ceph fs ls | grep -w $fs)" ]
then
  if [ -z "$(sudo ceph osd pool ls | gerp $data)" ]
  then
    sudo ceph osd pool create $data 128
  fi
  if [ -z "$(sudo ceph osd pool ls | grep $meta)" ]
  then
    sudo ceph osd pool create $meta 128
  fi
  sudo ceph fs new $fs $meta $data
fi