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

# PATH
route=/etc/acl
zone=/etc/zones
blackIpPath=blackip/blackip.txt

# GIT CLONE BLACKIP
echo "Descargando Proyecto Blackip..."
git clone https://github.com/maravento/blackip

# CREATE $zone and $route
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"

function downloadbl() {
    wget -c --retry-connrefused -t 0 "$1" -O - 2>/dev/null | grep -oP "$ipRegExp" | sort -u >> $blackIpPath
}

# DOWNLOAD GEOZONES
echo "Download GeoIps for Ipset..."
wget -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz 2>/dev/null && tar -C $zone -zxvf all-zones.tar.gz 2>/dev/null && rm -f all-zones.tar.gz 2>/dev/null

# BLACKIPS
echo "Download Blacklist..."
downloadbl 'https://zeustracker.abuse.ch/blocklist.php?download=badips' 
downloadbl 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset'
downloadbl 'http://blocklist.greensnow.co/greensnow.txt'
downloadbl 'https://lists.blocklist.de/lists/all.txt'
downloadbl 'https://www.openbl.org/lists/base.txt'
downloadbl 'http://cinsscore.com/list/ci-badguys.txt'
downloadbl 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt'
downloadbl 'https://www.maxmind.com/es/proxy-detection-sample-list'
downloadbl 'http://www.projecthoneypot.org/list_of_ips.php'
downloadbl 'https://www.spamhaus.org/drop/drop.lasso'
downloadbl 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php'
downloadbl 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt'
downloadbl 'https://check.torproject.org/exit-addresses'
downloadbl 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist'
downloadbl 'http://malc0de.com/bl/IP_Blacklist.txt'

wget -c --retry-connrefused -t 0 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip' 2>/dev/null && unzip full_blacklist_database.zip 2>/dev/null && grep -oP "$ipRegExp" full_blacklist_database.txt 2>/dev/null | sort -u >> $blackIpPath && rm -f full_blacklist_database* 2>/dev/null
#wget -c --retry-connrefused -t 0 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt' 2>/dev/null >> $blackIpPath

# DEBUGGED
echo "Debugged blackip (exclude whiteip)..."
wget -c --retry-connrefused -t 0 https://github.com/maravento/whiteip/raw/master/whiteip.txt -O blackip/whiteip.txt 2>/dev/null
# ADD OWN LIST
# cat $blackIpPath /ruta/blacklist_propia.txt > blackip/tmp.txt && # sed '/^$/d; / *#/d' blackip/tmp.txt | sort -u | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $blackIpPath
chmod +x blackip/filter.py && python blackip/filter.py blackip/whiteip.txt | grep -Fxvf - $blackIpPath | > blackip/tmp.txt
sort -u blackip/tmp.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n > $blackIpPath

# LOG
date=`date +%d/%m/%Y" "%H:%M:%S`
echo "Blackip for Ipset: ejecucion $date" >> /var/log/syslog.log

# END
cp -f $blackIpPath $route
rm -rf blackip
echo "Done"
