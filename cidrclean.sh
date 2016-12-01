#!/bin/bash
### BEGIN INIT INFO
# Provides:          CIDR Clean
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# From http://stackoverflow.com/a/35114656/3776858
### END INIT INFO
clear
echo "CIDR Clean..."

common() {


  D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
  declare -i c=0                              # set integer attribute

  # read and convert IPs to binary
  IFS=./ read -r a1 a2 a3 a4 m <<< "$1"
  b1="${D2B[$a1]}${D2B[$a2]}${D2B[$a3]}${D2B[$a4]}"

  IFS=./ read -r a1 a2 a3 a4 m <<< "$2"
  b2="${D2B[$a1]}${D2B[$a2]}${D2B[$a3]}${D2B[$a4]}"

  # find number of same bits ($c) in both IPs from left, use $c as counter
  for ((i=0;i<32;i++)); do
    [[ ${b1:$i:1} == ${b2:$i:1} ]] && c=c+1 || break
  done    

  # create string with zeros
  for ((i=$c;i<32;i++)); do
    fill="${fill}0"
  done    

  # append string with zeros to string with identical bits to fill 32 bit again
  new="${b1:0:$c}${fill}"

  # convert binary $new to decimal IP with netmask
  new="$((2#${new:0:8})).$((2#${new:8:8})).$((2#${new:16:8})).$((2#${new:24:8}))/$c"
  echo "$new"
}

cidr="$1"
grep -vxFf <(
  grep -v / "$cidr" | while IFS= read -r ip1; do
    grep / "$cidr" | while IFS=/ read -r ip2 mask2; do
      out=$(common "$ip2/$mask2" "$ip1/32")
      out_mask="${out#*/}"
      if [[ $out_mask -ge $mask2 ]]; then   # -ge: greater-than-or-equal
        echo "$ip1"
      fi
    done
  done
) "$cidr" > cidrclean.txt
