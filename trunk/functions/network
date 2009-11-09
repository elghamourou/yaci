#!/bin/bash

###############################################################################
# $URL$
# $Author$
# $Date$
# $Rev$
###############################################################################

# set of network manipulation

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/tmp

umask 022

# single load system
if [ -z "$_NETWORK_FUNCTIONS" ] ; then
_NETWORK_FUNCTIONS="loaded"

# Source the variables
. /tftpboot/etc/variables

# Usage: ip_to_hex ip_addr
# convert ip address to its hexadecimal format
ip_to_hex()
{
    for i in $(echo ${1} | tr '.' ' ') ; do
        printf "%02x" $i
    done | tr '[a-z]' '[A-Z]'
}

# Usage: inet_ip interface
# extract IP address of an inet interface
inet_ip()
{
    # extract definition
    local ip_def=`ifconfig $1 | grep "inet " | awk '{print $2}'`

    # only print the address
    echo ${ip_def#*:}
}

# Usage: inet_netmask interface
# extract IP netmask of an inet interface
inet_netmask()
{
    # extract definition
    local netmask_def=`ifconfig $1 | grep "inet " | awk '{print $4}'`

    # only print the address
    echo ${netmask_def#*:}
}

# Usage: inet_mac interface
# extract MAC address of an inet interface
inet_mac()
{
    echo `ifconfig $1 | grep HWaddr | awk '{print $5}'`
}

# Usage: running_interface
# Get device name of interface that is running
running_interface()
{
    echo `ifconfig | grep HWaddr | awk '{print $1}'`
}

fi
