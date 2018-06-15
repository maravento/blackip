#!/bin/bash
### BEGIN INIT INFO
# Provides:          blackip
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

# VARIABLES
route=/etc/acl
bip=$(pwd)/bip
date=`date +%d/%m/%Y" "%H:%M:%S`

# DEL OLD REPOSITORY
if [ -d $bip ]; then rm -rf $bip; fi

# CREATE PATH
if [ ! -d $route ]; then mkdir -p $route; fi

# DOWNLOAD
clear
echo
echo "Download Blackip..."
svn export "https://github.com/maravento/blackip/trunk/bip" >/dev/null 2>&1
cd $bip
cat blackip.tar.gz* | tar xzf -
echo "OK"
echo
echo "Checking Sum..."
a=$(md5sum blackip.txt | awk '{print $1}')
b=$(cat blackip.md5 | awk '{print $1}')
        if [ "$a" = "$b" ]
        then
                echo "Sum Matches"
		# ADD OWN LIST
		#sed '/^$/d; / *#/d' /path/blackip_own.txt >> blackip.txt
		cp -f  blackip.txt $route/blackip.txt >/dev/null 2>&1
		echo
		echo "OK"
		echo "Blackip: Done $date" >> /var/log/syslog
		cd
		rm -rf $bip
        echo
		echo "Done"
		else
		echo "Bad Sum"
		echo "Blackip: Abort $date Check Internet Connection" >> /var/log/syslog
		cd
		rm -rf $bip
		echo
		echo "Abort"
		exit
fi
