#!/bin/bash
# Language spa-eng
bip01=("This process can take. Be patient..." "Este proceso puede tardar. Sea paciente...")
bip02=("Downloading IPDeny..." "Descargando IPDeny...")
bip03=("Downloading BlackIP..." "Descargando BlackIP...")
bip04=("Downloading Blocklists..." "Descargando Listas de Bloqueo...")
bip05=("Debugging BlackIP..." "Depurando BlackIP...")
bip06=("1st DNS Loockup..." "1ra Busqueda DNS...")
bip07=("2nd DNS Loockup..." "2da Busqueda DNS...")
bip08=("Squid Reload..." "Reiniciando Squid...")
bip09=("Check on your desktop Squid-Error" "Verifique en su escritorio Squid-Error")
test "${LANG:0:2}" == "en"
en=$?

# VARIABLES
bipupdate=$(pwd)/bipupdate
ipRegExp="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
xdesktop=$(xdg-user-dir DESKTOP)
wgetd='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'
# path_to_lst (Change it to the directory of your preference)
route=/etc/acl
# CREATE PATH
if [ ! -d "$route" ]; then sudo mkdir -p "$route"; fi

clear
echo
echo "Blackip Project"
echo "${bip01[${en}]}"

# DOWNLOADING GEOZONES
echo "${bip02[${en}]}"
geopath="/etc/zones"
if [ ! -d "$geopath" ]; then sudo mkdir -p "$geopath"; fi
$wgetd http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C "$geopath" -zxvf all-zones.tar.gz >/dev/null 2>&1 && rm -f all-zones.tar.gz >/dev/null 2>&1
echo "OK"

# CHECK DNSLOOKUP1
if [ ! -e "$bipupdate"/dnslookup1 ]; then

    # DELETE OLD REPOSITORY
    if [ -d "$bipupdate" ]; then rm -rf "$bipupdate"; fi

    # DOWNLOAD BLACKIP
    echo "${bip03[${en}]}"
    svn export "https://github.com/maravento/blackip/trunk/bipupdate" >/dev/null 2>&1
    echo "OK"
    if [ -d "$bipupdate" ]; then
        cd "$bipupdate" || {
            echo "Access Error: $bipupdate"
            exit 1
        }
    else
        echo "Does not exist: $bipupdate"
        exit 1
    fi

    # DOWNLOADING BLOCKLIST IPS
    echo "${bip04[${en}]}"

    function blips() {
        curl -k -X GET --connect-timeout 10 --retry 1 -I "$1" &>/dev/null

        if [ $? -eq 0 ]; then
            $wgetd "$1" -O - | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq >>capture
        else
            echo ERROR "$1"
        fi
    }
    blips 'http://danger.rulez.sk/projects/bruteforceblocker/blist.php' && sleep 1
    blips 'https://blocklist.greensnow.co/greensnow.txt' && sleep 1
    blips 'https://cdn.ellio.tech/community-feed' && sleep 1
    blips 'https://check.torproject.org/torbulkexitlist?ip=1.1.1.1' && sleep 1
    blips 'https://cinsscore.com/list/ci-badguys.txt' && sleep 1
    blips 'https://danger.rulez.sk/projects/bruteforceblocker/blist.php' && sleep 1
    blips 'https://feeds.dshield.org/block.txt' && sleep 1
    blips 'https://feodotracker.abuse.ch/blocklist/?download=ipblocklist' && sleep 1
    blips 'https://gist.githubusercontent.com/BBcan177/d7105c242f17f4498f81/raw' && sleep 1
    blips 'https://lists.blocklist.de/lists/all.txt' && sleep 1
    blips 'https://myip.ms/files/blacklist/general/latest_blacklist.txt' && sleep 1
    blips 'https://pgl.yoyo.org/adservers/iplist.php?format=&showintro=0' && sleep 1
    blips 'https://raw.githubusercontent.com/BBcan177/minerchk/master/ip-only.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/client9/ipcat/master/datacenters.csv' && sleep 1
    blips 'https://raw.githubusercontent.com/CriticalPathSecurity/Public-Intelligence-Feeds/master/abuse-ch-ipblocklist.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/CriticalPathSecurity/Public-Intelligence-Feeds/master/compromised-ips.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/CriticalPathSecurity/Public-Intelligence-Feeds/master/cps_cobaltstrike_ip.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/CriticalPathSecurity/Public-Intelligence-Feeds/master/log4j.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/CriticalPathSecurity/Public-Intelligence-Feeds/master/tor-exit.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset' && sleep 1
    blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset' && sleep 1
    blips 'https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/ips/ips0.list' && sleep 1
    blips 'https://reputation.alienvault.com/reputation.generic' && sleep 1
    blips 'https://rules.emergingthreats.net/blockrules/compromised-ips.txt' && sleep 1
    blips 'https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt' && sleep 1
    blips 'https://www.binarydefense.com/banlist.txt' && sleep 1
    blips 'https://www.blocklist.de/downloads/export-ips_all.txt' && sleep 1
    blips 'https://www.dan.me.uk/torlist/?exit' && sleep 1
    blips 'https://www.darklist.de/raw.php' && sleep 1
    blips 'https://www.projecthoneypot.org/list_of_ips.php?t=d&rss=1' && sleep 1
    blips 'https://www.spamhaus.org/drop/drop.lasso' && sleep 1

    function uceprotect() {
        curl -k -X GET --connect-timeout 10 --retry 1 -I "$1" &>/dev/null

        if [ $? -eq 0 ]; then
            $wgetd "$1" && gunzip -c -f *uceprotect.net.gz | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq >>capture
        else
            echo ERROR "$1"
        fi
    }
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz' && sleep 2

    function listed_ip_180_all() {
        curl -k -X GET --connect-timeout 10 --retry 1 -I "$1" &>/dev/null

        if [ $? -eq 0 ]; then
            $wgetd "$1" && unzip -p listed_ip_180_all.zip | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq >>capture
        else
            echo ERROR "$1"
        fi
    }
    listed_ip_180_all 'https://www.stopforumspam.com/downloads/listed_ip_180_all.zip'

    function full_blacklist_database() {
        curl -k -X GET --connect-timeout 10 --retry 1 -I "$1" &>/dev/null

        if [ $? -eq 0 ]; then
            $wgetd "$1" && unzip -p full_blacklist_database.zip | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq >>capture
        else
            echo ERROR "$1"
        fi
    }
    full_blacklist_database 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip'

    echo "OK"

    # CIDR2IP (High consumption of system resources)
    #function cidr() {
    #       $wgetd "$1" -O - | sed '/^$/d; /*#/d' | uniq > cidr.txt && sort -o cidr.txt -u cidr.txt >/dev/null 2>&1
    #       python tools/cidr2ip.py cidr.txt >> bip
    #}
    #       cidr 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset'
    #       cidr 'https://www.stopforumspam.com/downloads/toxic_ip_cidr.txt'

    echo "${bip05[${en}]}"
    # debug
    sed -r 's/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/' capture | sed "/:/d" | sed '/\/[0-9]*$/d' | sed 's/^[ \s]*//;s/[ \s]*$//' | sed -r '/\.0\.0$/d' | sed -r 's:\s+.*::g' | awk -F. '$1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255' | grep -oP $ipRegExp | $reorganize | uniq >cleancapture
    # DEBBUGGING BLACKIP
    # First you must edit /etc/squid/squid.conf
    # And add line:
    # acl blackip dst "/path_to_lst/blackip.txt"
    # http_access deny blackip
    # add black ips/cidr
    #sed '/^$/d; /#/d' lst/blackcidr.txt >> cleancapture
    # add iana
    #sed '/^$/d; /#/d' lst/iana.txt >> cleancapture
    # exclude allowip
    sed 's:\/.*::' lst/iana.txt >>lst/allowip.txt
    #comm -3 <(sort lst/allowip.txt) <(sort cleancapture) | sed -r 's/^\s+*//;s/\s+*$//' > cleancapture2
    grep -vFf lst/allowip.txt cleancapture | sed -r 's/^\s+*//;s/\s+*$//' | $reorganize | uniq >cleancapture2
    echo "OK"
  else
    cd "$bipupdate"
fi

# DNS LOCKUP
# FAULT: Unexist/Fail IP
# HIT: Exist IP
# pp = parallel processes (high resource consumption!)
pp="300"

# STEP 1:
if [ ! -e "$bipupdate"/dnslookup2 ]; then
    echo "${bip06[${en}]}"
    sed 's/^\.//g' cleancapture2 | sort -u >step1
    if [ -s dnslookup1 ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup1 step1
    else
        cat step1
    fi | xargs -I {} -P "$pp" sh -c "if host {} >/dev/null; then echo HIT {}; else echo FAULT {}; fi" >>dnslookup1
    sed '/^FAULT/d' dnslookup1 | awk '{print $2}' | awk '{print "." $1}' | sort -u >hit.txt
    sed '/^HIT/d' dnslookup1 | awk '{print $2}' | awk '{print "." $1}' | sort -u >>fault.txt
    sort -o fault.txt -u fault.txt
    echo "OK"
fi

sleep 10

# STEP 2:
echo "${bip07[${en}]}"
sed 's/^\.//g' fault.txt | sort -u >step2
if [ -s dnslookup2 ]; then
    awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup2 step2
else
    cat step2
fi | xargs -I {} -P "$pp" sh -c "if host {} >/dev/null; then echo HIT {}; else echo FAULT {}; fi" >>dnslookup2
sed '/^FAULT/d' dnslookup2 | awk '{print $2}' | awk '{print "." $1}' | sort -u >>hit.txt
sed '/^HIT/d' dnslookup2 | awk '{print $2}' | awk '{print "." $1}' | sort -u >fault.txt
echo "OK"

# RELOAD SQUID-CACHE
echo "${bip08[${en}]}"
sed '/^$/d; /#/d' hit.txt | sort -u > blackip.txt
sudo cp -f blackip.txt "$route"/blackip.txt
sudo bash -c 'squid -k reconfigure' 2>SquidError.txt
sudo bash -c 'grep "$(date +%Y/%m/%d)" /var/log/squid/cache.log' >>SquidError.txt
grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" SquidError.txt | $reorganize | uniq >squidip
## Remove conflicts from blackip.txt
grep -Fvxf <(cat lst/iana.txt lst/dns.txt | sed '/^#/d') squidip | sort -u >cleanip
cat cleanip | $reorganize | uniq >debugip
python tools/debugbip.py
sed -E '/:/d; s/\/[0-9]+//g' outip | grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | $reorganize | uniq >blackip.txt

# COPY ACL TO PATH AND LOG
sudo cp -f blackip.txt "$route"/blackip.txt
sudo bash -c 'squid -k reconfigure' 2>"$xdesktop"/SquidErrors.txt

# DELETE REPOSITORY (Optional)
cd ..
if [ -d "$bipupdate" ]; then rm -rf "$bipupdate"; fi

# END
sudo bash -c 'echo "BlackIP Done: $(date)" | tee -a /var/log/syslog'
echo "${bip09[${en}]}"
