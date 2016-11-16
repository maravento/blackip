#!/bin/bash
### BEGIN INIT INFO
# Provides:          Blackip for Ipset
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       capture cidr from acl
# Authors:           Maravento.com and Novatoz.com
# used:              host -t a or dig +short -f
### END INIT INFO
clear
echo
# PATH
route=/etc/acl
zone=/etc/zones
blip=~/blackip

# GIT CLONE BLACKIP
echo "Descargando Proyecto Blackip..."
git clone https://github.com/maravento/blackip.git
echo "OK"

# CREATE $zone and $route
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

# DOWNLOAD GEOZONES
echo "Download GeoIps for Ipset..."
wget -q -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

function downloadbl() {
    wget -q -c --retry-connrefused -t 0 "$1" -O - | grep -oP "$ipRegExp" | sort -u >> $blip/blackip.txt
}

# BLACKIPS
echo "Download Blacklist IPs..."
downloadbl 'https://zeustracker.abuse.ch/blocklist.php?download=badips' 
downloadbl 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset'
downloadbl 'http://blocklist.greensnow.co/greensnow.txt'
downloadbl 'https://lists.blocklist.de/lists/all.txt'
downloadbl 'https://www.openbl.org/lists/base.txt'
downloadbl 'http://cinsscore.com/list/ci-badguys.txt'
downloadbl 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt'
downloadbl 'https://www.spamhaus.org/drop/drop.lasso'
downloadbl 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php'
downloadbl 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt'
downloadbl 'https://check.torproject.org/exit-addresses'
downloadbl 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist'
downloadbl 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt'
downloadbl 'https://www.maxmind.com/es/proxy-detection-sample-list'
downloadbl 'http://www.projecthoneypot.org/list_of_ips.php'
downloadbl 'http://malc0de.com/bl/IP_Blacklist.txt'

# BLZIP
function blzip() {
    wget -q -c --retry-connrefused -t 0 "$1" && unzip -p full_blacklist_database.zip > $blip/bltmp && grep -oP "$ipRegExp" $blip/bltmp | sort -u >> $blip/blackip.txt
}
blzip 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip'
echo "OK"

echo "Download Whiteip (exclude)..."
wget -q -c --retry-connrefused -t 0 https://github.com/maravento/whiteip/raw/master/whiteip.txt -O $blip/whiteip.txt
echo "OK"

# ADD OWN LIST
# cat $blip/blackip.txt /path/black_ip_user.txt > $blip/tmp.txt && sed '/^$/d; / *#/d' $blip/tmp.txt | sort -u | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $blip/blackip.txt

# DEBUGGED
echo "Debugged Blackip..."
cd $blip
chmod +x filter.py
python filter.py whiteip.txt | grep -Fxvf - blackip.txt > tmp.txt
sort -u tmp.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > blackip.txt
echo "OK"

# LOG
date=`date +%d/%m/%Y" "%H:%M:%S`
echo "Blackip for Ipset: $date" >> /var/log/syslog.log

# END
cp -f $blip/blackip.txt $route
rm -rf $blip
echo "Done"
