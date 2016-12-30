#!/bin/bash
### BEGIN INIT INFO
# Provides:          Blackip for Ipset
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       capture cidr from acl
# Authors:           Maravento.com
### END INIT INFO
# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Verifique su conexion a internet y reinicie el script" "Check your internet connection and restart the script")
test "${LANG:0:2}" == "es"
es=$?

clear
echo
echo "Blackip Project"
echo "${cm1[${es}]}"
echo
# PATH
route=/etc/acl
zone=/etc/zones
bip=~/blackip

# DEL OLD REPOSITORY
if [ -d $bip ]; then rm -rf $bip; fi

# GIT CLONE BLACKIP
echo "Download Blackip..."
git clone https://github.com/maravento/blackip.git >/dev/null 2>&1
echo "OK"

# CREATE $zone and $route
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

echo "Checking Sum..."
a=$(md5sum $bw/blackip.tar.gz | awk '{print $1}')
b=$(cat $bw/blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then 
		echo "Sum Matches"
		cd $bip
		tar -xvzf blackip.tar.gz >/dev/null 2>&1
		echo "OK"
	else
		echo "Bad Sum. Abort"
		echo "${cm2[${es}]}"
		rm -rf $bw
		exit
fi

# DOWNLOAD GEOZONES
echo "Download GeoIps..."
wget -q -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

# BLACKIPS
cd $bip
echo "Download Blacklist IPs..."
ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

function downloadbl() {
    wget -q -c --retry-connrefused -t 0 "$1" -O - | grep -oP "$ipRegExp" | sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/' >> blackip.txt
}
downloadbl 'https://zeustracker.abuse.ch/blocklist.php?download=badips' && sleep 1
downloadbl 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset' && sleep 1
downloadbl 'http://blocklist.greensnow.co/greensnow.txt' && sleep 1
downloadbl 'https://lists.blocklist.de/lists/all.txt' && sleep 1
downloadbl 'https://www.openbl.org/lists/base.txt' && sleep 1
downloadbl 'http://cinsscore.com/list/ci-badguys.txt' && sleep 1
downloadbl 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt' && sleep 1
downloadbl 'https://www.spamhaus.org/drop/drop.lasso' && sleep 1
downloadbl 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php' && sleep 1
downloadbl 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt' && sleep 1
downloadbl 'https://check.torproject.org/exit-addresses' && sleep 1
downloadbl 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist' && sleep 1
downloadbl 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt' && sleep 1
downloadbl 'https://www.maxmind.com/es/proxy-detection-sample-list' && sleep 1
downloadbl 'http://www.projecthoneypot.org/list_of_ips.php' && sleep 1
downloadbl 'https://myip.ms/files/blacklist/general/latest_blacklist.txt' && sleep 1
downloadbl 'http://www.openbl.org/lists/base.txt' && sleep 1
downloadbl 'https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1' && sleep 1
downloadbl 'http://www.unsubscore.com/blacklist.txt' && sleep 1
downloadbl 'http://malc0de.com/bl/IP_Blacklist.txt' && sleep 1

cd $bip
function blzip() {
    wget -q -c --retry-connrefused -t 0 "$1" && unzip -p full_blacklist_database.zip >/dev/null 2>&1 > tmp.txt && grep -oP "$ipRegExp" tmp.txt >> blackip.txt
}
blzip 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip' && sleep 1
echo "OK"

# BLACKIP DEBUGGING
echo "Blackip Debugging..."
cd $bip
# ADD OWN LIST
#sed '/^$/d; / *#/d' /path/blackip_own.txt >> blackip.txt
# CLEAN BLACKIP
awk -F'[.]' '{w=$1+0; x=$2+0; y=$3+0; z=$4+0; print w"."x"."y"."z}' blackip.txt > capture.txt && sort -u capture.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > blackip.txt
echo "OK"

# LOG
date=`date +%d/%m/%Y" "%H:%M:%S`
echo "Blackip for Ipset $date" >> /var/log/syslog.log

# END
cp -f $bip/blackip.txt $route
rm -rf $bip
echo "Done"
