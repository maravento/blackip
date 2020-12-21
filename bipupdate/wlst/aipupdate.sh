#!/bin/bash
# ------------------------------------
# AllowIP for Reverse Squid
# https://unix.stackexchange.com/questions/550796/bash-to-launching-multiple-queries-with-xargs
# ------------------------------------
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd

# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Descargando Allow URLs..." "Downloading Allow URLs...")
cm3=("Depurando Allowip..." "Debugging Allowip...")
cm4=("Terminado" "Done")
cm5=("Copie allowip a Squid y elimine los conflictos" "Copy allowip to Squid and eliminate the conflicts")
test "${LANG:0:2}" == "es"
es=$?

clear
echo -e "\n"
echo "AllowIP Project"
echo "${cm1[${es}]}"
# PATH
wip=$(pwd)/allowip.txt
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n"
wgetd="wget -q -c --retry-connrefused -t 0"
date=`date +%d/%m/%Y" "%H:%M:%S`

# DOWNLOAD URLS
echo -e "\n"
echo "${cm2[${es}]}"
function intacls() {
        $wgetd "$1" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u >> urls
}
        intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/allowurls.txt' && sleep 1
         #intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/add/remote.txt' && sleep 1

# DEBBUGGING allowip (CIDR)
echo -e "\n"
echo "${cm3[${es}]}"
pp="300"
cat urls | xargs -I {} -P $pp bash -c 'for sub in "" "www." "ftp."; do host -t a "${sub}{}" ; done ' | grep "has address" | awk '{ print $4 }' > out
# add iana
# cat iana.txt out > outfile.tmp && mv outfile.tmp out
# add teamviewer ips
#cat tw.txt >> out
# reorganize
cat out | $reorganize | uniq > allowip.txt
echo "OK"
echo -e "\n"
echo "${cm4[${es}]}"
echo "${cm5[${es}]}"
echo Done
notify-send "AllowIP Update: Done"
