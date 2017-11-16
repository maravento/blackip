#!/bin/bash
### BEGIN INIT INFO
# Provides:	     blackip
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts blackip update
# Description:       starts blackip using start-stop-daemon
### END INIT INFO

# by:	maravento.com and novatoz.com

# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Verifique su conexion a internet" "Check your internet connection")
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

# DELETE OLD REPOSITORY
if [ -d $bip ]; then rm -rf $bip; fi

# GIT CLONE BLACKIP
echo "Git Clone Blackip..."
git clone --depth=1 https://github.com/maravento/blackip.git
echo "OK"

# CREATE PATH
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

echo
echo "Checking Sum..."
cd $bip
a=$(md5sum blackip.tar.gz | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then 
		echo "Sum Matches"
		tar -xvzf blackip.tar.gz >/dev/null 2>&1
		echo "OK"
	else
		echo "Bad Sum. Abort"
		echo "${cm2[${es}]}"
		rm -rf $bip
		exit
fi

# DOWNLOADING GEOZONES
echo
echo "Downloading GeoIps..."
wget -q -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

# DOWNLOADING BLACKIPS
echo
echo "Downloading Blacklist IPs..."
ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

function blips() {
    wget -q -c --retry-connrefused -t 0 "$1" -O - | grep -oP "$ipRegExp" >> blackip.txt
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
#blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset' && sleep 1
#blips 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt' && sleep 1
#blips 'https://www.openbl.org/lists/base.txt' # SERVER DOWN

function myip() {
    wget -q -c --retry-connrefused -t 0 "$1" && unzip -p full_blacklist_database.zip >/dev/null 2>&1 > tmp.txt
	grep -oP "$ipRegExp" tmp.txt >> blackip.txt
}
myip 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip' && sleep 1

# ADD OWN LIST
#sed '/^$/d; / *#/d' /path/blackip_own.txt >> blackip.txt

echo "OK"

# DEBBUGGING BLACKIP
echo
echo "Debugging Blackip..."
sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/' blackip.txt | sed "/:/d" | sed '/\/[0-9]*$/d' | sed 's/^[ \s]*//;s/[ \s]*$//' > bl.txt
sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n bl.txt | uniq > blackip.txt
echo "OK"

# COPY ACL TO PATH
cp -f blackip.txt $route/blackip.txt

# LOG
date=`date +%d/%m/%Y" "%H:%M:%S`
echo "Blackip $date" >> /var/log/syslog

# END
cd
rm -rf $bip
echo
echo "Done"
