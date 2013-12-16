#!/system/bin/sh

# This file implements a user-space handler for compressing
# core files and limiting the number of core files.

BASE=/data/core
MAX_NUM_CORE_FILES=3
pid=$1 # process id
uid=$2 # user id
ts=$3  # time stamp
LOG=$BASE/$ts.$pid.$uid.core.gz.log # Log path

# Read /system/build.prop to get the properties: ro.build.type, ro.aa.report
old_ifs=$IFS
IFS="="
while read line; do
  p=($line)
  if [ x"${p[0]}" = x"ro.build.type" ]; then
    buildType=${p[1]}
  elif [ x"${p[0]}" = x"ro.aa.report" ]; then
    roAaReport=${p[1]}
  fi
done < /system/build.prop

IFS=$old_ifs

# Read /proc/cmdline to get ro.sf
target="td.sf="

while read line; do
  for word in $line
  do
    value=${word#*$target}
    if [ "$value" != "$word" ]; then
      roSf=$value
      break
    fi
  done
done < /proc/cmdline

# Trim space
buildType=`echo $buildType`
roAaReport=`echo $roAaReport`
roSf=`echo $roSf`

#
# The following section is used to determine whether
# a ROM is shipping or engineering version.
# (refers to isShippingRom()@/system/core/debuggerd/tombstone.c)
# Skip generating core files if this is a shipping ROM.
#{

if [ -z "$buildType" ]; then
  buildType="user"
fi

if [ -z "$roAaReport" ]; then
  if [ "$buildType" = "user" ]; then
      exit 0
  fi
else
  if [ -n "$roSf" ]; then
    lastCharOfSF=${roSf: -1}
  fi

  #Consider as shipping ROM from all of the following three cases
  # 1.'user' of ro.build.type
  # 2.All cases of ro.aa.report except 'eng'
  # 3.All cases of ro.sf except '0'
  if [ "$buildType" = "user" -a "$roAaReport" != "eng" -a "$lastCharOfSF" != "0" ]; then
      exit 0
  fi
fi
#}


# The following section is used to determine whether it needs to
# generate core file based on its rlimit value of core.
#{
while read line; do
  i=0
  for x in $line; do
    field[$i]=$x
    i=$((i + 1))
  done

  if [ x"${field[1]}" = x"core" ]; then
    i=$((i - 3)) # get "Soft Limit" field.
    s=${field[$i]}
    if [ "0" = "$s" ]; then # 0 means disable coredump
      exit 0
    fi
    /system/bin/mkdir /data/core #create core directory
    chmod /data/core 0766
    echo "Generating core files..."
  fi
done < /proc/$pid/limits
#}

i=0
for c in $BASE/*.gz; do
  i=$((i + 1))
  if [ -z $victim ]; then
    victim=$c
  fi
done

echo "buildType = $buildType. " >> $LOG
echo "roAaReport = $roAaReport. " >> $LOG
echo "roSf = $roSf. " >> $LOG
echo "lastCharOfSF = $lastCharOfSF." >> $LOG
echo "---- $ts ----" >> $LOG
echo "pid = $pid" >> $LOG
echo "uid = $uid" >> $LOG
echo "victim = $victim" >> $LOG
echo "i = $i" >> $LOG

# If the number core files > 3,
# delete the core/process map/log files of the oldest dead process.
if [ $i -ge $MAX_NUM_CORE_FILES ]; then
  /system/bin/rm $victim
  /system/bin/rm $victim.log
fi

/system/bin/gzip -1 > $BASE/$ts.$pid.$uid.core.gz


