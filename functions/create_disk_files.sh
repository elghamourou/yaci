#!/bin/bash
################################################################################
# create_disk_files,v 1.21 2004/10/28 18:08:26 tdhooge Exp
################################################################################
#  Copyright (C) 2001-2002 The Regents of the University of California.
#  Produced at Lawrence Livermore National Laboratory (cf, DISCLAIMER).
#  Written by Makia Minich <makia@llnl.gov> and Trent D'Hooge <tdhooge@llnl.gov>
#  UCRL-CODE-2003-024.
#  
#  This file is part of YACI, a cluster installation tool.
#  For details, see <http://www.llnl.gov/linux/yaci/>.
#  
#  YACI is free software; you can redistribute it and/or modify it under
#  the terms of the GNU General Public License as published by the Free
#  Software Foundation; either version 2 of the License, or (at your option)
#  any later version.
#  
#  YACI is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
#  details.
#  
#  You should have received a copy of the GNU General Public License along
#  with YACI; if not, write to the Free Software Foundation, Inc.,
#  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA.
################################################################################
#
# create_disk_files
# Parse the partition list and create a useable fstab and sfdisk file.
#

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

if [ -z "$_CREATE_DISK_FILES" ] ; then
_CREATE_DISK_FILES="loaded"

# Source local variables
. /tftpboot/etc/variables

# The INFILE
INFILE="${yaci_etc}/partition_list.${image}"

# make image directory
mkdir -p ${yaci_etc}/${image}

generate_device_filename()
{
    device_base=$1
    partition_number=$2

    # generate block filename related to the given device
    case "$device_base" in
      cciss*)
        device_filename="${device_base}p${partition_number}"
        ;;
      none)
        device_filename="${device_base}"
        ;;
      *)
        device_filename="${device_base}${partition_number}"
        ;;
    esac
}

print_fstab_line()
{
    current_line=( `echo $1` )

    # need block filename
    generate_device_filename ${current_line[0]} ${current_line[5]}

    if [ ${current_line[0]} = "none" ] ; then
        local device=${device_filename}
    elif [ ${current_line[1]} = "swap" ] ; then
        local device=/dev/${device_filename}
    elif [ ${current_line[2]} = "fat16" ] ||
         [ ${current_line[2]} = "vfat" ] ; then
        local device=/dev/${device_filename}
    else
        local device="LABEL=${current_line[1]}"
        local altname=/dev/${device_filename}
    fi

    #if [ ${current_line[4]} = "raid" ] ; then
        #local device="/dev/md0"
        #local altname="/dev/md0"
    #fi

    local flags=${current_line[7]}
    local  dump=${current_line[8]}
    local  pass=${current_line[9]}
    local    mp=${current_line[1]}
    local  type=${current_line[2]}

    if [ -z ${fstab_outfile} ] ; then
        case "${current_line[0]}" in
            hd*)
                fstab_outfile=${yaci_etc}/${image}/fstab
                ;;
            sd*)
                fstab_outfile=${yaci_etc}/${image}/fstab
                ;;
            cciss*)
                fstab_outfile=${yaci_etc}/${image}/fstab
                ;;
        esac
        echo "# This fstab has been created by YACI." > ${fstab_outfile}
        rm -f ${yaci_etc}/${image}/fstab_mapping
    fi
    [ ! -z "${altname}" ] && \
    echo "${device} ${altname}" >> ${yaci_etc}/${image}/fstab_mapping

    [ ${mp} = "/" ] && root_partition=${altname}

    printf "%-20s%-20s%-15s%-20s%-3s%s\n" ${device} ${mp} ${type} ${flags} \
                                          ${dump} ${pass} >> ${fstab_outfile}
}

print_sfdisk_line()
{
    current_line=( `echo "$1"` )

    # need block filename
    generate_device_filename ${current_line[0]} ${current_line[5]}

    local device=/dev/${device_filename}
    local size=${current_line[3]}
    local type=${current_line[6]}
    local boot=${current_line[4]}

    # must translate device name, because it can be contained in directory
    local sfdisk_ext=`echo ${current_line[0]} | tr \/ .`
    sfdisktype="${yaci_etc}/${image}/sfdisk.${sfdisk_ext}"

    if [ ! -f ${sfdisktype} ] ; then
        echo "# This SFDISK has been created by YACI." > ${sfdisktype}
    fi

    [ ${size} = "rest" ] && unset size
    [ ${current_line[5]} = 1 ] && local start='0' || local start=''

    outline="${device} : start= ${start}, size=${size}, Id=${type}"
    [ ${boot} = 'y' ] && outline="${outline}, bootable"

    echo $outline >> ${sfdisktype}
}

print_parted_line()
{
   current_line=( `echo "$1"` )

   local device=/dev/${current_line[0]}
   local size=${current_line[3]}
   local type=${current_line[2]}
   local boot=${current_line[4]}
   local part=${current_line[5]}
   local mp=${current_line[1]}

   # File creation
   if [ -z ${parted_outfile} ] ; then
      parted_outfile=${yaci_etc}/${image}/parted
      echo "#!/bin/sh" > ${parted_outfile} 
      echo "# This PARTED script has been created by YACI." >> ${parted_outfile} 
   fi

   # Another device
   if [ $part = 1 ] ; then
      # Clears the beginning of the disk and creates the partition table
      cat << EOF >> ${parted_outfile}

### ${device}
dd if=/dev/zero of=${device} count=2 bs=1024
parted -s ${device} mklabel gpt
EOF
   fi

   case "$type" in
      *fat*) type="fat16" ;;
      ext3)  type="ext2" ;;
      swap)  type="linux-swap" ;;
   esac

   # Compute the partition positions
   start=$end
   if [ "${mount_line[3]}" = "rest" ] ; then
      end="-0"
      endl=$end
   else
      end=$((${start} + $size))
      endl=$end.016
   fi

   # Creates the partition and filesystem
   cat << EOF >> ${parted_outfile}
parted -i ${device} << EE
mkpart primary $type ${start}.017 ${endl}
quit
EE
EOF

   # Bootable partition
   [ "$boot" = 'y' ] &&
      echo "parted -s ${device} set 1 boot on" >> ${parted_outfile}
   # Partition label
   [ "$type" != "linux-swap" ] &&
      echo "parted -s ${device} name ${part} ${mp}" >> ${parted_outfile}
}

check_extended()
{
    current_line=( `echo "$1"` )

    # must translate device name, because it can be contained in directory
    local sfdisk_ext=`echo ${current_line[0]} | tr \/ .`
    disktype="${yaci_etc}/${image}/sfdisk.${sfdisk_ext}"

    if [ -f ${disktype} ] ; then
        NUM=`cat ${disktype} | grep -v "^#" | wc -l`
    else
        # must reset partition number after each configured device
       NUM=0
    fi

    if [ ! -z "${NUM}" ] && [ ${NUM} = 3 ] ; then
        new_line=("${current_line[@]}")

        new_line[3]=rest
        new_line[5]=4
        new_line[6]=5

        print_sfdisk_line "`echo ${new_line[@]}`"
        current_line[5]=5

        return ${current_line[5]}
    fi

    return `expr ${NUM} + 1`
}

create_disk_files()
{
# mount_line is an array with the following setup:
# 0) device
# 1) mount point
# 2) type
# 3) sizeMB
# 4) bootable?
# 5) partition number
# 6) stype

start=0
end=0
current_partition=0
old_device="wrong"

if [ "${USE_PARTED}" = "NO" -o "${USE_PARTED}" = "no" ] ; then
    rm -f ${yaci_etc}/${image}/sfdisk*
else
    rm -f ${yaci_etc}/${image}/parted
fi

for x in $(seq `grep -c $ ${INFILE}`) ; do
    x=$((${x}))
    mount_line="`sed -n ${x}p ${INFILE} | sed 's/\*/y/g'`"

    [ ${mount_line:0:1} = '#' ] && continue

    mount_line=(${mount_line})
    [ -z ${mount_line[4]} ] && mount_line[4]=n

    # Reset the flags when device changes
    if [ ! $old_device = ${mount_line[0]} ] ; then
        current_partition=1
        old_device="${mount_line[0]}" 
        start=0
        end=0
    else
        current_partition=$((${current_partition} + 1))
    fi

    mount_line=( ${mount_line[@]} ${current_partition} 83 )

    if [ "${USE_PARTED}" = "NO" -o "${USE_PARTED}" = "no" ] ; then
        check_extended "`echo ${mount_line[@]}`"
        current_partition=$?
    fi
    mount_line[5]=${current_partition}

    if [ ${mount_line[1]} = "swap" ] ; then
        mount_line[6]=82
        print_fstab_line "`echo ${mount_line[@]}` defaults 0 0"
    elif [ ${mount_line[4]} = "raid" ] ; then
        mount_line[6]=fd
        print_fstab_line "`echo ${mount_line[@]}` defaults 1 3"
    elif [ ${mount_line[4]} = "PPC" ] ; then
        mount_line[6]=41
    else
        if [ ${mount_line[1]} = "/" ] ; then
            print_fstab_line "`echo ${mount_line[@]}` defaults 1 1"
        else
            print_fstab_line "`echo ${mount_line[@]}` defaults 1 2"
        fi
    fi

    if [ "${USE_PARTED}" = "NO" -o "${USE_PARTED}" = "no" ] ; then
        print_sfdisk_line "`echo ${mount_line[@]}`"
    else
        print_parted_line "`echo ${mount_line[@]}`"
    fi
done

# Reorder the fstab file (if needed)
MOUNT_POINTS=( $(cat ${yaci_etc}/${image}/fstab | egrep -v "(\#|swap|none)" | awk '{print $2}') )
COMPARISONS=$((${#MOUNT_POINTS[@]} - 1))

# "Quick" bubble sort to get the list into order
while [ $COMPARISONS -gt 0 ] ; do
   index=0

   while [ $index -lt $COMPARISONS ] ; do
      if [ ${MOUNT_POINTS[$index]} \> ${MOUNT_POINTS[$(($index + 1))]} ] ; then
         temp=${MOUNT_POINTS[$index]}
         MOUNT_POINTS[$index]=${MOUNT_POINTS[$(($index + 1))]}
         MOUNT_POINTS[$(($index + 1))]=$temp
      fi
      index=$(($index + 1))
   done

   COMPARISONS=$(($COMPARISONS - 1))
done

rm -f ${yaci_etc}/${image}/fstab.tmp
for mp in ${MOUNT_POINTS[@]} ; do
   md=$(grep " ${mp} " ${yaci_etc}/${image}/fstab)
   echo "$md" >> ${yaci_etc}/${image}/fstab.tmp
done
grep " swap " ${yaci_etc}/${image}/fstab >> ${yaci_etc}/${image}/fstab.tmp

mv ${yaci_etc}/${image}/fstab.tmp ${yaci_etc}/${image}/fstab

print_fstab_line "none /dev/pts devpts NULL NULL NULL NULL gid=5,mode=620 0 0"
print_fstab_line "none /proc proc NULL NULL NULL NULL defaults 0 0"
print_fstab_line "none /dev/shm tmpfs NULL NULL NULL NULL defaults 0 0"

# Complete the fstab file with dedicated file if available
if [ -r "${yaci_etc}/fstab.append.${image}" ]; then
   cat ${yaci_etc}/fstab.append.${image} >> ${yaci_etc}/${image}/fstab
fi

if [ "${USE_PARTED}" = "NO" -o "${USE_PARTED}" = "no" ] ; then
    boot_partition=`egrep "Id=41|bootable" ${yaci_etc}/${image}/sfdisk.* | awk '{print $1}' | head -1`
else
    boot_partition=`awk '/set 1 boot on/ { print $3}' ${yaci_etc}/${image}/parted`
fi

# adapt grub.conf in function of variables, but preserve original version
if [ -z "${USE_SERIAL}" ] ; then
    mv ${yaci_etc}/grub.conf ${yaci_etc}/grub.conf.orig
    cat ${yaci_etc}/grub.conf.orig | grep -v "serial" \
      > ${yaci_etc}/grub.conf
    chmod 444 ${yaci_etc}/grub.conf
fi

for CONF in grub elilo yaboot
do
    cat ${yaci_etc}/${CONF}.conf | sed -e "s|<ROOT>|${root_partition}|" \
                                           -e "s|<BOOT>|${boot_partition}|" \
                                           -e "s|<CONSOLE>|${CONSOLE}|" \
                                           -e "s|<BAUD>|${BAUD}|" \
                                           > ${yaci_etc}/${image}/${CONF}.conf
done

# restore original version
if [ -z "${USE_SERIAL}" ] ; then
    mv ${yaci_etc}/grub.conf.orig ${yaci_etc}/grub.conf
fi
}

fi
