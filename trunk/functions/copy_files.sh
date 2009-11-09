#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# Copy files or directories into image directory

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

# single load system
if [ -z "$_COPY_FUNCTIONS" ] ; then
_COPY_FUNCTIONS="loaded"

# Source variables
. /tftpboot/etc/variables

# Read localize files and copy stuff in
copy_files()
{

  pushd ${local_files} >/dev/null

  for FILE in localize localize.${image} localize.${arch}\
              localize.${image}.${arch} ; do
    if [ -f ${FILE} ] ; then
      cat ${FILE} | awk '{sub("#.*","")} $0!~/^[[:space:]]*$/ {print $0}' |
      while read local_line ; do
        [ -z "${local_line}" ] && continue
        local_line=( ${local_line} )

        if [ -e ${local_line[0]} ] ; then
          filename=${local_line[0]}
          destination=${local_line[1]}
          mode=${local_line[2]}
          user=${local_line[3]}
          group=${local_line[4]}
  
          if [ -z "$destination" ] ; then
            destination=${local_line[0]}
          fi

          destname=$(basename $destination)
          destdir=$(dirname $destination)

          #######################################
          # Append file to ${destdir}/${destname}
          #######################################
          if [ "$mode" = "append" ] ; then
            if [ -d ${image_dir}/${destdir}/${destname} ] ; then
              echo "${destdir}/${destname} is a directory, not appending"
            elif [ -d ${filename} ] ; then
              echo "${filename} is a directory, not appending"
            else 
              echo "Appending ${filename} to ${destdir}/${destname}"
              [ ! -d ${image_dir}/${destdir} ] &&
                mkdir -m 755 -p ${image_dir}/${destdir}
              cat ${filename} >> ${image_dir}/${destdir}/${destname}
            fi

          ##################################################
          # Copy file or directory to ${destdir}/${destname}
          ##################################################
          else
            if [ -e ${filename} ] ; then
              echo "Installing ${filename} into ${destdir}"
              [ ! -d ${image_dir}/${destdir} ] &&
                mkdir -m 755 -p ${image_dir}/${destdir}
              if [ ! -d ${filename} ] ; then
                cp -a ${filename} ${image_dir}/${destdir}/${destname}
              elif [ -d ${filename} ] ; then
                mkdir -m 755 -p ${image_dir}/${destdir}/${destname}
                rsync -a ${filename}/ ${image_dir}/${destdir}/${destname}/
              fi

              if [ "$mode" != "-" ] && [ ! -z "$mode" ] ; then
                chmod $mode ${image_dir}/${destination}
              fi
              if [ "$user" != "-" ] && [ ! -z "$user" ] ; then
                chown $user ${image_dir}/${destination}
              fi
              if [ "$group" != "-" ] && [ ! -z "$group" ] ; then
                chgrp $group ${image_dir}/${destination}
              fi
            fi
          fi
        fi
      done
    fi
  done

  popd >/dev/null
}

fi
