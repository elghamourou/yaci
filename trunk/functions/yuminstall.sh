#!/bin/bash

###############################################################################
# $URL: https://yaci.googlecode.com/svn/trunk/functions/prep_image_dir $
# $Author: tdhooge@harco.com $
# $Date: 2009-11-09 10:11:27 -0800 (Mon, 09 Nov 2009) $
# $Rev: 13 $
###############################################################################

# create image using yum

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_YUM_INSTALL" ] ; then
_YUM_INSTALL="loaded"

# Source the variables
. /tftpboot/etc/variables

# install image with yum
yum_install()
{
  if [ ${#} -lt 2 ]; then
    echo "USAGE: $0 yum_install_type package(s)|groups(s)"
    return 1;
  fi
  
  # yum install type
  local yuminstall=$1 && shift

  # image name
  local packages="$@"

  yum -d 0 clean all

  if [ "${yuminstall}" == group ] ; then
    install_cmd="groupinstall"
  elif [ "${yuminstall}" == rpm ] ; then
    install_cmd="install"
  else
    echo "${yuminstall} not valid, please use group or rpm"
    return 1
  fi

  yum ${install_cmd} -y --installroot ${imagedir} ${packages}
}

fi
