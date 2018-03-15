#!/bin/bash
### BEGIN INIT INFO
# Provides:          bipdupdate
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon
### END INIT INFO

# by:	maravento.com and novatoz.com

# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Descargando Blackip..." "Downloading Blackip...")
cm3=("Chequeando Suma" "Checking Sum...")
cm4=("Suma Coincide" "Sum Matches")
cm5=("Suma No Coincide. Abortado" "Bad Sum. Abort")
cm6=("Verifique su conexion a internet" "Check your internet connection")
cm7=("Descargando GeoIP..." "Downloading GeoIP...")
cm8=("Descargando Listas Negras..." "Downloading Blacklists...")
cm9=("Depurando Blackip..." "Debugging Blackip...")
cm10=("Depurando IANA..." "Debugging IANA...")
cm11=("Recargando Squid..." "Squid Reload...")
cm12=("Terminado" "Done")
test "${LANG:0:2}" == "es"
es=$?

clear
echo
echo "Blackip Project"
echo "${cm1[${es}]}"
echo

# VARIABLES
route=/etc/acl
zone=/etc/zones
bipd=$(pwd)/blackip
ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n"
date=`date +%d/%m/%Y" "%H:%M:%S`
wgetd="wget -q -c --retry-connrefused -t 0"

# DELETE OLD REPOSITORY
if [ -d $bipd ]; then rm -rf $bipd; fi

# CREATE PATH
if [ ! -d $route ]; then mkdir -p $route; fi

# GIT CLONE BLACKIP
echo "${cm2[${es}]}"
git clone --depth=1 https://github.com/maravento/blackip.git >/dev/null 2>&1
echo "OK"

# CHECKING SUM
echo
echo "${cm3[${es}]}"
cd $bipd/bipupdate
cat blackip.tar.gz* | tar xzf -
a=$(md5sum blackip.txt | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then
		echo "${cm4[${es}]}"
		echo "OK"
	else
		echo "${cm5[${es}]}"
		echo "${cm6[${es}]}"
		cd
		rm -rf $bipd
		exit
fi

# DOWNLOADING GEOZONES
echo
echo "${cm7[${es}]}"
if [ ! -d $zone ]; then mkdir -p $zone; fi
$wgetd http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

# DOWNLOADING BLACKIPS
echo
echo "${cm8[${es}]}"

function blips() {
    $wgetd "$1" -O - | grep -oP "$ipRegExp" >> blackip.txt
}
blips 'http://blocklist.greensnow.co/greensnow.txt' && sleep 1
blips 'http://cinsscore.com/list/ci-badguys.txt' && sleep 1
blips 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php' && sleep 1
blips 'http://malc0de.com/bl/IP_Blacklist.txt' && sleep 1
blips 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt' && sleep 1
blips 'https://check.torproject.org/exit-addresses' && sleep 1
blips 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist' && sleep 1
blips 'https://lists.blocklist.de/lists/all.txt' && sleep 1
blips 'https://myip.ms/files/blacklist/general/latest_blacklist.txt' && sleep 1
blips 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt' && sleep 1
blips 'https://www.malwaredomainlist.com/hostslist/ip.txt' && sleep 1
blips 'https://www.maxmind.com/es/proxy-detection-sample-list' && sleep 1
blips 'https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1' && sleep 1
blips 'https://zeustracker.abuse.ch/blocklist.php?download=badips' && sleep 1
blips 'http://www.unsubscore.com/blacklist.txt' && sleep 1
blips 'https://www.spamhaus.org/drop/drop.lasso' && sleep 1
blips 'https://hosts.ubuntu101.co.za/ips.list' && sleep 1
# blips 'https://www.openbl.org/lists/base.txt' # SERVER DOWN

# CIDR2IP consumes all the resources of the PC and collapses
#function cidr() {
#    $wgetd "$1" -O - | sed '/^$/d; / *#/d' | $reorganize | uniq >> cidrtmp.txt
#    python cidr2ip.py cidrtmp.txt >> blackip.txt
#}
#cidr 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset'
#cidr 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt'

function cidr2() {
    $wgetd "$1" -O - | sed '/^$/d; / *#/d' | sed '/\//d' | $reorganize | uniq >> blackip.txt
}
cidr2 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset' && sleep 1

function myip() {
    $wgetd "$1" && unzip -o full_blacklist_database.zip >/dev/null 2>&1 > full_blacklist_database.txt
	grep -oP "$ipRegExp" full_blacklist_database.txt >> blackip.txt
}
myip 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip' && sleep 1

# ADD OWN LIST
#sed '/^$/d; / *#/d' /path/blackip_own.txt >> blackip.txt
echo "OK"
echo
echo "${cm9[${es}]}"
sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/' blackip.txt | sed "/:/d" | sed '/\/[0-9]*$/d' | sed 's/^[ \s]*//;s/[ \s]*$//' > bl.txt
$reorganize bl.txt | uniq > blackip.txt
echo "OK"

# DEBBUGGING BLACKIP and IANA (CIDR)

# IMPORTANT:
# First you must edit /etc/squid/squid.conf
# And add line:
# acl blackip dst "/etc/acl/blackip.txt"
# http_access deny blackip

echo
echo "${cm10[${es}]}"
## Add ianacidr.txt to blackip.txt
cat ianacidr.txt >> blackip.txt
## Reload Squid with Out
cp -f blackip.txt $route/blackip.txt
squid -k reconfigure 2> squiderror.txt
## Debbugging squiderror.txt
grep -oP "$ipRegExp" squiderror.txt | $reorganize | uniq > clean.txt
## Remove conflicts from blackip.txt
python debugbip.py
sed '/\//d' biptmp.txt | $reorganize | uniq > blackip.txt
# COPY ACL TO PATH
cp -f blackip.txt $route/blackip.txt

echo "OK"

# RELOAD SQUID
echo
echo "${cm11[${es}]}"
squid -k reconfigure
echo "Blackip $date" >> /var/log/syslog

echo "OK"

# END
cd
rm -rf $bipd
echo
echo "${cm12[${es}]}"
