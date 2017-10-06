#!/bin/bash
### BEGIN INIT INFO
# Provides:	     blackip
# Required-Start:    $local_fs $remote_fs $network $syslog $named
# Required-Stop:     $local_fs $remote_fs $network $syslog $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts blackip
# Description:       starts blackip using start-stop-daemon
### END INIT INFO

# by:	maravento.com and novatoz.com

# DATE
date=`date +%d/%m/%Y" "%H:%M:%S`
# PATH
route=/etc/acl
zone=/etc/zones

# CREATE PATH
if [ ! -d $zone ]; then mkdir -p $zone; fi
if [ ! -d $route ]; then mkdir -p $route; fi

# DOWNLOAD
echo "Download Blackip..."
wget -q -c --retry-connrefused -t 0 https://raw.githubusercontent.com/maravento/blackip/master/blackip.tar.gz
wget -q -c --retry-connrefused -t 0 https://raw.githubusercontent.com/maravento/blackip/master/blackip.md5
echo "OK"

echo "Checking Sum..."
a=$(md5sum blackip.tar.gz | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
	if [ "$a" = "$b" ]
	then 
		echo "Sum Matches"
		tar -C $route -xvzf blackip.tar.gz >/dev/null 2>&1
		# DOWNLOAD GEOZONES
		echo "Download Geozones..."
		wget -q -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
		tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1
		rm -f all-zones.tar.gz >/dev/null 2>&1
		echo "OK"
		echo "Blackip: Done $date" >> /var/log/syslog
		rm -rf blackip* all-zones*
		echo "Done"
	else
		echo "Bad Sum. Abort"
		echo "Blackip: Abort $date Check Internet Connection" >> /var/log/syslog
		rm -rf blackip* all-zones*
		exit
fi
