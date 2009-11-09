#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# set of parameters manipulation

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

# single load system
if [ -z "$_PARAM_FUNCTIONS" ] ; then
_PARAM_FUNCTIONS="loaded"

# Source the variables
. /tftpboot/etc/variables

# Source functions
. ${yaci_functions}/network

# initialize some variables
mac_info_file=${yaci_etc}/MAC.info


##################################################
# MAC.info parameters
##################################################

# Usage: mac_info_line_seq
# create sequence of line number from MAC.info
mac_info_line_seq()
{
    seq `grep -c $ ${mac_info_file}`
}

# Usage: mac_info_line line_number
# extract one definition line from MAC.info file
mac_info_line()
{
    sed -n ${1}p ${mac_info_file}
}

# Usage: mac_info_line_is_comment line_number
# check if a line from MAC.info is a comment
mac_info_line_is_comment()
{
    local line=`mac_info_line $1`

    if [ -z "$line" ] || [ ${line[0]:0:1} = '#' ] ; then
        echo true
    else
        echo false
    fi
}

# Usage: mac_info_line_number hostname
# get the line number of a definition
mac_info_line_number()
{
    local line=`grep -i -n $1 ${mac_info_file} | awk -F ':' '{ print $1 }'`
    if [ ! -z "$line" ] ; then
        echo $line
    fi
}

# Usage: mac_info_hostname line_number
# extract the hostname of one definition line from MAC.info file
mac_info_hostname()
{
    mac_info_line $1 | awk '{ print $1 }'
}

# Usage: mac_info_mac line_number
# extract the MAC address of one definition line from MAC.info file
mac_info_mac()
{
    mac_info_line $1 | awk '{ print $2 }'
}

# Usage: mac_info_image line_number
# extract the image of one definition line from MAC.info file
mac_info_image()
{
    mac_info_line $1 | awk '{ print $3 }'
}


##################################################
# Node specific MAC.info parameters
##################################################

# Usage: mac_info_my_data attr
# extract one attribute of the current node from MAC.info file
mac_info_my_data()
{
    eth=`running_interface`

    # search my definition line
    local my_line_number=$(mac_info_line_number `inet_mac ${eth}`)

    # retrieve the field
    if [ ! -z "$my_line_number" ] ; then
        mac_info_${1} $my_line_number
    fi
}

# Usage: mac_info_my_image
# extract image name of the current node from MAC.info file
mac_info_my_image()
{
    mac_info_my_data "image"
}

# Usage: mac_info_my_hostname
# extract hostname of the current node from MAC.info file
mac_info_my_hostname()
{
    mac_info_my_data "hostname"
}

fi
