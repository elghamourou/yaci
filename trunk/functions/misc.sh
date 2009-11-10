#!/bin/bash

###############################################################################
# $URL: https://yaci.googlecode.com/svn/trunk/functions/prep_image_dir $
# $Author: tdhooge@harco.com $
# $Date: 2009-11-09 10:11:27 -0800 (Mon, 09 Nov 2009) $
# $Rev: 13 $
###############################################################################

# misc functions that don't go with anything else

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_MISC_STUFF" ] ; then
_MISC_STUFF="loaded"

# Source the variables
. /tftpboot/etc/variables

# Run post create script
post_create()
{

  if [ ${#} -lt 2 ]; then
    echo "USAGE: $0 imagedir post_create_script"
    return 1;
  fi
  
  # image name
  local imagedir=$1
  
  # post create script
  local postcreate=$2

  if [ ! -e "${postcreate}" ]; then
    echo -e "\nCan not find post create script ${postcreate}\n"
    return 1;
  else
    cp -p ${postcreate} ${image_dir}/tmp/POST_CREATE
    if [ -x ${postcreate} ] ; then
      chroot ${image_dir} /tmp/POST_CREATE
    else
      chroot ${image_dir} /bin/bash /tmp/POST_CREATE
    fi
    rm ${image_dir}/tmp/POST_CREATE
  fi
}

# Create ramdisk for use by YACI and a static kernel
create_ramdisk()
{
if [ "${BUILD_RAMDISK}" = "YES" -o "${BUILD_RAMDISK}" = "yes" ] ; then
    echo "Creating ramdisk."
    pushd ${yaci_ramdisk} > /dev/null 2>&1
    ./create_ramdisk > /dev/null 2>&1
    popd  > /dev/null 2>&1
fi
}

fi
