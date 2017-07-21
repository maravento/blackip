#!/bin/bash
### BEGIN INIT INFO
# Provides:          Blackip
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Update acl
### END INIT INFO
# by:	             maravento.com and novatoz.com

# PATH
route=/etc/acl
zone=/etc/zones

# CREATE PATH
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

# DOWNLOAD
echo "Download Blackip..."
wget -q -c --retry-connrefused -t 0 https://github.com/maravento/blackip/raw/master/blackip.tar.gz
wget -q -c --retry-connrefused -t 0 https://github.com/maravento/blackip/raw/master/blackip.md5
echo "OK"

echo "Checking Sum..."
a=$(md5sum blackip.tar.gz | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then 
		echo "Sum Matches"
		tar -C $route -xvzf blackip.tar.gz >/dev/null 2>&1
		# ADD OWN LIST
		#sed '/^$/d; / *#/d' /path/blackip_own.txt >> $route/blackip.txt
		# DOWNLOAD GEOZONES
		echo "Download Geozones..."
		wget -q -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
		tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1
		rm -f all-zones.tar.gz >/dev/null 2>&1
		echo "OK"
		date=`date +%d/%m/%Y" "%H:%M:%S`
		echo "Blackip for Ipset: Done $date" >> /var/log/syslog
		rm -rf blackip* all-zones*
		echo "Done"
	else
		echo "Bad Sum. Abort"
		date=`date +%d/%m/%Y" "%H:%M:%S`
		echo "Blackip for Ipset: Abort $date Check Internet Connection" >> /var/log/syslog
		rm -rf blackip* all-zones*
		exit
fi
