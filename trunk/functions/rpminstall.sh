#!/bin/bash

###############################################################################
# $URL: https://yaci.googlecode.com/svn/trunk/functions/prep_image_dir $
# $Author: tdhooge@harco.com $
# $Date: 2009-11-09 10:11:27 -0800 (Mon, 09 Nov 2009) $
# $Rev: 13 $
###############################################################################

# create image using rpmlist

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_RPM_INSTALL" ] ; then
_RPM_INSTALL="loaded"

# Source the variables
. /tftpboot/etc/variables

# Mount /proc in image directory
rpm_install()
{
  if [ ${#} -lt 2 ]; then
    echo "USAGE: $0 rpmlist image_dir"
    return 1;
  fi
  
  # image name
  local rpmlist=$1

  # image dir
  local image_dir=$2

  rpms=`cat ${rpmlist} | sort | uniq | paste -s -d ' '`

  pushd ${rpm_dir} >/dev/null && \
  rpm --nosignature -iv --root ${image_dir} ${rpms}
  popd >/dev/null
}

verify_rpms()
{
  if [ ${#} -lt 1 ]; then
    echo "USAGE: $0 rpmlist"
    return 1;
  fi
  
  # image name
  local rpmlist=$1

  cat ${rpmlist} |
  while read rpm ; do
    for r in ${rpm_dir}/${rpm} ; do
      if [ ! -r "$r" ] && [ ! -h "$r" ] ; then
        badrpm=( ${badrpm[@]} $rpm )
      fi
    done
  done

  if [ ! -z "${badrpm}" ]; then
    echo -e"\nMISSING RPMS\n"
    for a in `seq 0 ${#badrpm}` ; do
      echo "${badrpm[$a]}"
    done
    return 1
  fi
}

fi
