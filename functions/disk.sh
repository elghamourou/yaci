#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# set of disk device manipulation

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_DISK_FUNCTIONS" ] ; then
_DISK_FUNCTIONS="loaded"

# Source the variables
. /tftpboot/etc/variables

find_disk_device()
{
    # find the device of the boot partition
    part_device=$1

    # find the disk device related to this partition
    let dev_filename_length=${#part_device}-1
    if [ $dev_filename_length -le 0 ] ; then
        return 1
    fi

    # find it by reducing the name of the partition device
    # (eg. /dev/hda1 > /dev/hda, /dev/cciss/c0d0p1 > /dev/cciss/c0d0)
    until [ -b ${part_device:0:dev_filename_length} ] \
      || [ $dev_filename_length -le 0 ] ; do
        let dev_filename_length--;
    done

    if [ $dev_filename_length -le 0 ] ; then
        DEVICE=""
        return 1
    else
        DEVICE=${part_device:0:dev_filename_length}
        return 0
    fi
}

fi
