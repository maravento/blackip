#!/bin/bash
# ------------------------------------
# AllowIP for Reverse Squid
# https://unix.stackexchange.com/questions/550796/bash-to-launching-multiple-queries-with-xargs
# ------------------------------------
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd

# Language spa-eng
cm1=("This process can take a long time. Be patient..." "Este proceso puede tardar mucho tiempo. Sea paciente...")
cm2=("Downloading Allow URLs..." "Descargando Allow URLs...")
cm3=("Debugging AllowIP..." "Depurando AllowIP...")
cm4=("Copy Allow IP to Squid and eliminate the conflicts" "Copie Allow IP a Squid y elimine los conflictos")
test "${LANG:0:2}" == "en"
en=$?

clear
#echo -e "\n"
echo "AllowIP Project"
echo "${cm1[${en}]}"

# VARIABLES
wip=$(pwd)/allowip.txt
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
wgetd='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'

# DOWNLOAD URLS
echo "${cm2[${en}]}"
function intacls() {
        $wgetd "$1" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u >> urls
}
        intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/allowurls.txt' && sleep 1
        #intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/remote.txt' && sleep 1


# DEBBUGGING Allow WhiteIP (CIDR)
echo "${cm3[${en}]}"
pp="100"
cat urls | xargs -I {} -P "$pp" bash -c 'for sub in "" "www." "ftp."; do host -t a "${sub}{}" ; done ' | grep "has address" | awk '{ print $4 }' > out
# add iana
# cat iana.txt out > outfile.tmp && mv outfile.tmp out
# add teamviewer ips
#cat tw.txt >> out
# reorganize
cat out | $reorganize | uniq > "$wip"

# END
echo "${bip07[${en}]}"
echo "AllowIP Done: $(date)"
notify-send "AllowIP Update Done" "$(date)" -i checkbox
