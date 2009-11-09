#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# prep directory for image creation

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_PREP_IMAGE_DIR" ] ; then
_PREP_IMAGE_DIR="loaded"

# Source the variables
. /tftpboot/etc/variables

# Make sure proc is not mounted in the image directory
umount_proc()
{
  umount -f ${imagedir}/proc > /dev/null 2>&1
}

# Mount /proc in image directory
mount_proc()
{
  mount -t proc none ${imagedir}/proc
}

# Make sure dev is not mounted in the image directory
umount_dev()
{
  umount -f ${imagedir}/dev > /dev/null 2>&1
}

# Mount /dev in image directory
# imagedir may be mounted with nodev option
mount_dev()
{
  mount -t tmpfs /dev ${image_dir}/dev
}

# remove the image directory if requested
remove_imagedir()
{
  #if [ -d "${imagedir}" ] && [ -z "${nodelete}" ] ; then
  if [ -d "${imagedir}" ] ; then
    echo "Removing ${imagedir}"
    rm -rf ${imagedir}
  fi
}

# Create files that are required to build image
make_image_files()
{
  mknod ${image_dir}/dev/null c 1 3
  chmod 666 ${image_dir}/dev/null
}

# Create directories that are required to build image
make_image_dir()
{
  mkdir -p ${imagedir}/proc
  mkdir -p ${imagedir}/dev
  mkdir -p ${imagedir}/etc
  mkdir -p ${imagedir}/var/lib/{rpm,yum}
  mkdir -p ${imagedir}/var/lock/rpm
  mkdir -p ${imagedir}/var/log
}

# Create rpm DB in image directory
init_rpmdb()
{
  rpm --root ${imagedir} --initdb
}

# Call this function to get everything done
prep_image_dir()
{
  umount_proc
  umount_dev
  remove_imagedir
  make_image_dir
  mount_proc
  mount_dev
  make_image_files
  init_rpmdb
}

# Image clean up before tar'ing it up
image_clean_up()
{
  umount_dev
  umount_proc
  # lastlog can sometime be a large sparse file that causes tar issues
  cat /dev/null > ${image_dir}/var/log/lastlog

  # make sure rpm cache is ok
  rm -f ${image_dir}/var/lib/rpm/__*
  chroot ${image_dir} rpm --rebuilddb

  # Make sure ldconfig is run
  chroot ${image_dir} ldconfig
}

fi
