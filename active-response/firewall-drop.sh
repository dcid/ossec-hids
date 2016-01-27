#!/bin/sh
# Adds an IP to the iptables drop list (if linux)
# Requirements: Linux with iptables, Solaris/FreeBSD/NetBSD with ipfilter
# Expect: srcip
# Author: Ahmet Ozturk (ipfilter and IPSec)
# Author: Daniel B. Cid (iptables)
# Last modified: Feb 14, 2006

UNAME=`uname`
ECHO="/bin/echo"
GREP="/bin/grep"
IPTABLES=""
IP4TABLES="/sbin/iptables"
IP6TABLES="/sbin/ip6tables"
IPFILTER="/sbin/ipf"
if [ "X$UNAME" = "XSunOS" ]; then
    IPFILTER="/usr/sbin/ipf"
fi    
GENFILT="/usr/sbin/genfilt"
LSFILT="/usr/sbin/lsfilt"
MKFILT="/usr/sbin/mkfilt"
RMFILT="/usr/sbin/rmfilt"
ARG1=""
ARG2=""
RULEID=""
ACTION=$1
USER=$2
IP=$3
PWD=`pwd`
LOCK="${PWD}/fw-drop"
LOCK_PID="${PWD}/fw-drop/pid"
OSVERSION=""

if [ -f /etc/redhat-release ]; then
   OSVERSION="cut -d' ' -f4 /etc/redhat-release | cut -d '.' -f1"
fi

LOCAL=`dirname $0`;
cd $LOCAL
cd ../
echo "`date` $0 $1 $2 $3 $4 $5" >> ${PWD}/../logs/active-responses.log


# Checking for an IP
if [ "x${IP}" = "x" ]; then
   echo "$0: <action> <username> <ip>" 
   exit 1;
fi

case "${IP}" in
    *:* ) IPTABLES=$IP6TABLES;;
    *.* ) IPTABLES=$IP4TABLES;;
    * ) echo "`date` Unable to run active response (invalid IP)." >> ${PWD}/../logs/active-responses.log && exit 1;;
esac


# Blocking IP
if [ "x${ACTION}" != "xadd" -a "x${ACTION}" != "xdelete" ]; then
   echo "$0: invalid action: ${ACTION}"
   exit 1;
fi

# add -w to wait for ipt lock to prevent rule from failing to add/delete ips on busy boxes
IPTWAIT=""
if [ "x${OSVERSION}" = "x7" ]; then
        IPTWAIT="-w"
fi

# We should run on linux
if [ "X${UNAME}" = "XLinux" ]; then
   if [ "x${ACTION}" = "xadd" ]; then
      ARG1="-I INPUT ${IPTWAIT} -s ${IP} -j DROP"
      ARG2="-I FORWARD ${IPTWAIT} -s ${IP} -j DROP"
   else
      ARG1="-D INPUT ${IPTWAIT} -s ${IP} -j DROP"
      ARG2="-D FORWARD ${IPTWAIT} -s ${IP} -j DROP"
   fi
   
   # Checking if iptables is present
   if [ ! -x ${IPTABLES} ]; then
      IPTABLES="/usr"${IPTABLES}
      if [ ! -x ${IPTABLES} ]; then
         exit 0;
      fi
   fi

   # Executing and exiting - try to run twice.
   ${IPTABLES} ${ARG1}
   RES=$?
   # running with -w caused it to return 2, so we ignore it as it will always work
   if [ ! $RES = 0 ] && [ ! $RES = 2 ]; then
       echo "`date` Unable to run (iptables returning != $RES): $COUNT - $0 $1 $2 $3 $4 $5" >> ${PWD}/../logs/active-responses.log     
       sleep 1;
       ${IPTABLES} ${ARG1}
       if [ ! $? = 0 ] && [ ! $RES = 2 ]; then
           echo "`date` Gave up. Unable to run (iptables returning != $RES): $COUNT - $0 $1 $2 $3 $4 $5" >> ${PWD}/../logs/active-responses.log
       fi
   fi

   exit 0;
   
   
# FreeBSD, SunOS or NetBSD with ipfilter
elif [ "X${UNAME}" = "XFreeBSD" -o "X${UNAME}" = "XSunOS" -o "X${UNAME}" = "XNetBSD" ]; then
   
   # Checking if ipfilter is present
   ls ${IPFILTER} >> /dev/null 2>&1
   if [ $? != 0 ]; then
      exit 0;
   fi    

   # Checking if echo is present
   ls ${ECHO} >> /dev/null 2>&1
   if [ $? != 0 ]; then
       exit 0;
   fi    
   
   if [ "x${ACTION}" = "xadd" ]; then
      ARG1="\"@1 block out quick from any to ${IP}\""
      ARG2="\"@1 block in quick from ${IP} to any\""
      IPFARG="${IPFILTER} -f -"
   else
      ARG1="\"@1 block out quick from any to ${IP}\""
      ARG2="\"@1 block in quick from ${IP} to any\""
      IPFARG="${IPFILTER} -rf -"
   fi
  
   # Executing it 
   eval ${ECHO} ${ARG1}| ${IPFARG}       
   eval ${ECHO} ${ARG2}| ${IPFARG}
   
   exit 0;


else
    exit 0;
fi

