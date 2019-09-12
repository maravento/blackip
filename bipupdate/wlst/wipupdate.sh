#!/bin/bash
# ------------------------------------
# WhiteIP for Reverse Squid
# By: Alej Calero and Jhonatan Sneider
# ------------------------------------
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd

# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Descargando White URLs..." "Downloading White URLs...")
cm3=("Depurando Whiteip..." "Debugging Whiteip...")
cm4=("Terminado" "Done")
cm5=("Copie whiteip a Squid y elimine los conflictos" "Copy white to Squid and eliminate the conflicts")

test "${LANG:0:2}" == "es"
es=$?
clear
echo
echo "Whiteip Project"
echo "${cm1[${es}]}"
# PATH
wip=$(pwd)/whiteip.txt
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n"
wgetd="wget -q -c --retry-connrefused -t 0"
date=`date +%d/%m/%Y" "%H:%M:%S`

# DOWNLOAD URLS
echo "${cm2[${es}]}"
function intacls() {
        $wgetd "$1" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u >> urls
}
                intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/whiteurls.txt' && sleep 1
                #intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/remoteurls.txt' && sleep 1
                #intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/cloudsync.txt' && sleep 1

# DEBBUGGING WHITEIP (CIDR)
echo
echo "${cm3[${es}]}"
for ip in `cat urls`; do
        for sub in "" "www." "ftp."; do
                host -t a "${sub}${ip}";
        done
done | grep address | awk '{ print $4 }' > out
# add iana cidr
cat ianacidr.txt >> out
# add teamviewer ips
#cat tw.txt  >> out
# reorganize
cat out | $reorganize | uniq > whiteip.txt
echo "OK"
echo
echo "${cm4[${es}]}"
echo "${cm5[${es}]}"
