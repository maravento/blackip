#!/bin/bash
# ------------------------------------
# Update Blackweb
# By: Alej Calero and Jhonatan Sneider
# maravento.com
# ------------------------------------
# Language spa-eng
cm1=("Este proceso puede tardar mucho tiempo. Sea paciente..." "This process can take a long time. Be patient...")
cm2=("Descargando Blackip..." "Downloading Blackip...")
cm3=("Descargando GeoIP..." "Downloading GeoIP...")
cm4=("Descargando Listas Negras..." "Downloading Blacklists...")
cm5=("Depurando Blackip..." "Debugging Blackip...")
cm6=("Depurando IANA..." "Debugging IANA...")
cm7=("Terminado" "Done")
cm8=("Verifique en su escritorio Squid-Error.txt" "Check on your desktop Squid-Error.txt")

test "${LANG:0:2}" == "es"
es=$?

# VARIABLES
bipupdate=$(pwd)/bipupdate
ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n -k 6,6n -k 7,7n -k 8,8n -k 9,9n"
date=`date +%d/%m/%Y" "%H:%M:%S`
wgetd="wget -q -c --retry-connrefused -t 0"
xdesktop=$(xdg-user-dir DESKTOP)
# path_to_lst (Change it to the directory of your preference)
route=/etc/acl
zone=/etc/zones

# DELETE OLD REPOSITORY
if [ -d $bipupdate ]; then rm -rf $bipupdate; fi
# CREATE PATH
if [ ! -d $route ]; then mkdir -p $route; fi

clear
echo
echo "Blackip Project"
echo "${cm1[${es}]}"
# DOWNLOAD BLACKIP
echo
echo "${cm2[${es}]}"
svn export "https://github.com/maravento/blackip/trunk/bipupdate" >/dev/null 2>&1
cd $bipupdate
echo "OK"

# DOWNLOADING GEOZONES
echo
echo "${cm3[${es}]}"
if [ ! -d $zone ]; then mkdir -p $zone; fi
        $wgetd http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C $zone -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

# DOWNLOADING BLACKIPS
echo
echo "${cm4[${es}]}"

function blips() {
	$wgetd "$1" -O - | grep -oP "$ipRegExp" | uniq >> bip
}
        blips 'http://blocklist.greensnow.co/greensnow.txt' && sleep 1
        blips 'http://cinsscore.com/list/ci-badguys.txt' && sleep 1
        blips 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php' && sleep 1
        blips 'http://malc0de.com/bl/IP_Blacklist.txt' && sleep 1
        blips 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt' && sleep 1
        blips 'http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt' && sleep 1
        blips 'https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=1.1.1.1' && sleep 1
        blips 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist' && sleep 1
        blips 'https://hosts.ubuntu101.co.za/ips.list' && sleep 1
        blips 'https://lists.blocklist.de/lists/all.txt' && sleep 1
        blips 'https://myip.ms/files/blacklist/general/latest_blacklist.txt' && sleep 1
        blips 'https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0' && sleep 1
        blips 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt' && sleep 1
        blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset' && sleep 1
        blips 'https://www.dan.me.uk/torlist/?exit' && sleep 1
        blips 'https://www.malwaredomainlist.com/hostslist/ip.txt' && sleep 1
        blips 'https://www.maxmind.com/es/proxy-detection-sample-list' && sleep 1
        blips 'https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1' && sleep 1
        blips 'https://www.spamhaus.org/drop/drop.lasso' && sleep 1
        blips 'https://zeustracker.abuse.ch/blocklist.php?download=badips' && sleep 1
        blips 'http://www.unsubscore.com/blacklist.txt' && sleep 1

$wgetd 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz'
$wgetd 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz'
$wgetd 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz'
gunzip -c *.gz  | grep -oP "$ipRegExp" | uniq >> bip

$wgetd 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip'
unzip -p full_blacklist_database.zip | grep -oP "$ipRegExp" | uniq >> bip

$wgetd 'https://www.stopforumspam.com/downloads/listed_ip_180_all.zip'
unzip -p listed_ip_180_all.zip | grep -oP "$ipRegExp" | uniq >> bip

# CIDR2IP (High consumption of system resources)
#function cidr() {
#       $wgetd "$1" -O - | sed '/^$/d; / *#/d' | uniq > cidr.txt && sort -o cidr.txt -u cidr.txt >/dev/null 2>&1
#       python tools/cidr2ip.py cidr.txt >> bip
#}
#       cidr 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset'
#       cidr 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt'
echo "OK"

echo
echo "${cm5[${es}]}"
sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/' bip | sed "/:/d" | sed '/\/[0-9]*$/d' | sed 's/^[ \s]*//;s/[ \s]*$//'| $reorganize | uniq | sed -r '/\.0\.0$/d' > blackip.txt
echo "OK"

# DEBBUGGING BLACKIP
# First you must edit /etc/squid/squid.conf
# And add line:
# acl blackip dst "/path_to_lst/blackip.txt"
# http_access deny blackip
echo
echo "${cm6[${es}]}"
# add blackcidr
#sed '/^$/d; /#/d' blst/bextra.txt >> blackip.txt
# add tw
#sed '/^$/d; /#/d' wlst/tw.txt >> blackip.txt
# add iana cidr
sed '/^$/d; /#/d' wlst/ianacidr.txt >> blackip.txt && sort -o blackip.txt -u blackip.txt
## Reload Squid with Out
cp -f blackip.txt $route/blackip.txt
squid -k reconfigure 2> SquidError.txt
grep "$(date +%Y/%m/%d)" /var/log/squid/cache.log >> SquidError.txt
grep -oP "$ipRegExp" SquidError.txt | $reorganize | uniq > clean.txt
## Remove conflicts from blackip.txt
grep -Fvxf <(cat wlst/ianacidr.txt) clean.txt | sort -u > cleanip.txt
python tools/debugbip.py
sed '/\//d' biptmp.txt | $reorganize | uniq > blackip.txt
# COPY ACL TO PATH AND LOG
cp -f blackip.txt $route/blackip.txt
squid -k reconfigure 2> $xdesktop/SquidError.txt
echo "BlackIP $date" >> /var/log/syslog
# END
echo "${cm7[${es}]}"
echo "${cm8[${es}]}"
