#!/bin/bash
# maravento.com

# BlackIP Update

# Language spa-eng
bip01=("This process can take. Be patient..." "Este proceso puede tardar. Sea paciente...")
bip02=("Downloading IPDeny..." "Descargando IPDeny...")
bip03=("Downloading BlackIP..." "Descargando BlackIP...")
bip04=("Downloading Blocklists..." "Descargando Listas de Bloqueo...")
bip05=("Debugging BlackIP..." "Depurando BlackIP...")
bip06=("1st DNS Loockup..." "1ra Busqueda DNS...")
bip07=("2nd DNS Loockup..." "2da Busqueda DNS...")
bip08=("Squid Reload..." "Reiniciando Squid...")
bip09=("Check Squid-Error" "Verifique Squid-Error")

lang=$([[ "${LANG,,}" =~ ^es ]] && echo 1 || echo 0)

# check no-root
if [ "$(id -u)" == "0" ]; then
    echo "❌ This script should not be run as root."
    exit 1
fi

# check SO
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$UBUNTU_ID" != "ubuntu" || "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "This script requires Ubuntu 24.04. Use at your own risk"
    # exit 1
fi

# VARIABLES
bipupdate="$(pwd)/bipupdate"
wgetd="wget -q -c --show-progress --no-check-certificate --retry-connrefused --timeout=10 --tries=4"
# path_to_lst (Change it to the directory of your preference)
route="/etc/acl"
# CREATE PATH
if [ ! -d "$route" ]; then sudo mkdir -p "$route"; fi
# Absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo
echo "Blackip Project"
echo "${bip01[$lang]}"

# CHECK DNSLOOKUP1
if [ ! -e "$bipupdate"/dnslookup1 ]; then

    # DELETE OLD REPOSITORY
    rm -rf "$bipupdate" >/dev/null 2>&1

    # DOWNLOADING GEOZONES
    echo "${bip02[$lang]}"
    geopath="/etc/zones"
    url="http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz"
    # create dir
    if [ ! -d "$geopath" ]; then
        sudo mkdir -p "$geopath"
    fi
    # check with curl
    if ! curl -s -f -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
        echo "❌ URL Down: $url"
        exit 1
    fi
    # download
    if ! $wgetd "$url" -O all-zones.tar.gz; then
        echo "❌ ERROR: $url"
        exit 1
    fi
    # extract
    if ! sudo tar -C "$geopath" -zxvf all-zones.tar.gz >/dev/null 2>&1; then
        echo "❌ ERROR: all-zones.tar.gz"
        rm -f all-zones.tar.gz
        exit 1
    fi
    # clean
    rm -f all-zones.tar.gz >/dev/null 2>&1
    echo "OK"

    # DOWNLOAD BLACKIP
    echo "${bip03[$lang]}"
    $wgetd https://raw.githubusercontent.com/maravento/vault/master/scripts/python/gitfolderdl.py -O gitfolderdl.py
    chmod +x gitfolderdl.py
    python gitfolderdl.py https://github.com/maravento/blackip/bipupdate
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
    echo "${bip04[$lang]}"
    blips() {
        local url="$1"
        # check with curl
        if ! curl -k -s -f -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "❌ URL Down: $url"
            return 1
        fi
        # download
        if ! $wgetd "$url" -O - | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | uniq >> capture; then
            echo "❌ ERROR: $url"
            return 1
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
    blips 'https://raw.githubusercontent.com/duggytuxy/Data-Shield_IPv4_Blocklist/refs/heads/main/prod_data-shield_ipv4_blocklist.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/duggytuxy/Intelligence_IPv4_Blocklist/refs/heads/main/agressive_ips_dst_fr_be_blocklist.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset' && sleep 1
    blips 'https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset' && sleep 1
    blips 'https://raw.githubusercontent.com/opsxcq/proxy-list/master/list.txt' && sleep 1
    blips 'https://raw.githubusercontent.com/romainmarcoux/malicious-ip/refs/heads/main/full-aa.txt' && sleep 1
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

    uceprotect() {
        local url="$1"
        local filename
        # filename
        filename=$(basename "${url%%\?*}")
        # check with curl
        if ! curl -k -s -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "❌ URL Down: $url"
            return 1
        fi
        # Ddownload
        if ! $wgetd "$url" -O "$filename"; then
            echo "❌ ERROR: $url"
            return 1
        fi
        # extract
        if ! gunzip -c -f "$filename" \
             | grep -a -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture; then
            echo "❌ ERROR: $filename"
            rm -f "$filename"
            return 1
        fi
        # clean
        rm -f "$filename"
        return 0
    }
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz' && sleep 2

    listed_ip_180_all() {
        local url="$1"
        local filename
        # filename
        filename=$(basename "${url%%\?*}")
        # check with curl
        if ! curl -k -s -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "❌ URL Down: $url"
            return 1
        fi
        # download
        if ! $wgetd "$url" -O "$filename"; then
            echo "❌ ERROR: $url"
            return 1
        fi
        # extract
        if ! unzip -p "$filename" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture; then
            echo "❌ ERROR: $filename"
            rm -f "$filename"
            return 1
        fi
        # clean
        rm -f "$filename"
        return 0
    }
    listed_ip_180_all 'https://www.stopforumspam.com/downloads/listed_ip_180_all.zip'

    full_blacklist_database() {
        local url="$1"
        local filename
        # filename
        filename=$(basename "${url%%\?*}")
        # check with curl
        if ! curl -k -s -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "❌ URL Down: $url"
            return 1
        fi
        # download
        if ! $wgetd "$url" -O "$filename"; then
            echo "❌ ERROR: $url"
            return 1
        fi
        # extract
        if ! unzip -p "$filename" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture; then
            echo "❌ ERROR: $filename"
            rm -f "$filename"
            return 1
        fi
        # clean
        rm -f "$filename"
        return 0
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
    #echo "OK"

    echo "${bip05[$lang]}"
    # debug
    sed -r '
        /:/d
        /\/[0-9]*$/d
        /\.0\.0$/d
        s/^[[:space:]]*//
        s/[[:space:]]*$//
        s/[[:space:]].*//
        s/^0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)\.0*([0-9]+)$/\1.\2.\3.\4/
    ' capture \
    | grep -oP '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$' \
    | awk -F. '$1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255' \
    | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u > cleancapture

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
    sed 's:\/.*::' lst/iana.txt >> lst/allowip.txt
    #comm -3 <(sort lst/allowip.txt) <(sort cleancapture) | sed -r 's/^\s+*//;s/\s+*$//' > cleancapture2
    grep -vFf lst/allowip.txt cleancapture | sed -r 's/^\s+*//;s/\s+*$//' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq > cleancapture2
    echo "OK"
  else
    cd "$bipupdate"
fi

# DNS LOOKUP
# FAULT: Nonexistent or failed domain
# HIT: Resolved (existent) domain
#
# WARNING: High resource consumption!
# This script uses parallel DNS queries. Adjust concurrency to avoid saturating your CPU or network (e.g., Starlink).
#
# Xargs Parallel Limit:
# The practical limit for parallel jobs with xargs is usually high (at least 127; check your system with: xargs --show-limits)
#
# Number of parallel processes (PROCS) = Logical CPUs × multiplier
# The multiplier (e.g., 2, 4) controls how aggressively to parallelize. More isn't always better.
#
# ┌───────────────────────────────────────────────────────┐
# │ How to determine your CPU configuration (Linux only): │
# └───────────────────────────────────────────────────────┘
# Physical cores: grep '^core id' /proc/cpuinfo | sort -u | wc -l
# Logical CPUs (threads): nproc
#
# Recommended:
#   PROCS=$(($(nproc)))      # Conservative (network-friendly)
#   PROCS=$(($(nproc) * 2))  # Balanced
#   PROCS=$(($(nproc) * 4))  # Aggressive (default)
#   PROCS=$(($(nproc) * 8))  # Extreme (8 or higher, use with caution)
#
# Example: Core i5 with 4 physical cores and 8 threads (Hyper-Threading)
#   nproc          → 8
#   PROCS=$((8 * 4)) → 32 parallel queries
#
# Adjust based on:
# - Your CPU
# - Your network (bandwidth/latency)
# - Desired balance between speed and system load
PROCS=$(($(nproc) * 4))

# STEP 1:
if [ ! -e "$bipupdate"/dnslookup2 ]; then
    echo "${bip06[$lang]}"
    sed 's/^\.//g' cleancapture2 | sort -u > step1
    total=$(wc -l < step1)
    (
        while sleep 1; do
            processed=$(wc -l < dnslookup1 2>/dev/null)
            percent=$(awk -v p="$processed" -v t="$total" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
            printf "Processed: %d / %d (%s%%)\r" "$processed" "$total" "$percent"
        done
    ) &
    progress_pid=$!
    if [ -s dnslookup1 ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup1 step1
    else
        cat step1
    fi | xargs -I {} -P "$PROCS" sh -c "if host {} >/dev/null; then echo HIT {}; else echo FAULT {}; fi" >> dnslookup1
    kill "$progress_pid" 2>/dev/null
    echo

    sed '/^FAULT/d' dnslookup1 | awk '{print $2}' | awk '{print "." $1}' | sort -u > hit.txt
    sed '/^HIT/d' dnslookup1 | awk '{print $2}' | awk '{print "." $1}' | sort -u >> fault.txt
    sort -o fault.txt -u fault.txt
    echo "OK"
fi

sleep 10

# STEP 2:
echo "${bip07[$lang]}"
sed 's/^\.//g' fault.txt | sort -u > step2
total=$(wc -l < step2)
(
    while sleep 1; do
        processed=$(wc -l < dnslookup2 2>/dev/null)
        percent=$(awk -v p="$processed" -v t="$total" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
        printf "Processed: %d / %d (%s%%)\r" "$processed" "$total" "$percent"
    done
) &
progress_pid=$!
if [ -s dnslookup2 ]; then
    awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup2 step2
else
    cat step2
fi | xargs -I {} -P "$PROCS" sh -c "if host -W 2 {} >/dev/null; then echo HIT {}; else echo FAULT {}; fi" >> dnslookup2
kill "$progress_pid" 2>/dev/null
echo

sed '/^FAULT/d' dnslookup2 | awk '{print $2}' | awk '{print "." $1}' | sort -u >> hit.txt
sed '/^HIT/d' dnslookup2 | awk '{print $2}' | awk '{print "." $1}' | sort -u > fault.txt
echo "OK"

# RELOAD SQUID-CACHE
echo "${bip08[$lang]}"
sed '/^$/d; /#/d' hit.txt | sort -u > blackip.txt
sudo cp -f blackip.txt "$route"/blackip.txt
sudo bash -c 'squid -k reconfigure' 2> sqerror.txt
sudo bash -c 'grep "$(date +%Y/%m/%d)" /var/log/squid/cache.log' >> sqerror.txt
grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" sqerror.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq > squidip.txt
## Remove conflicts from blackip.txt
grep -Fvxf <(cat lst/iana.txt lst/dns.txt | sed '/^#/d') squidip.txt | sort -u > cleanip.txt
cat cleanip.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq > debugip.txt
python tools/debugbip.py
cat lst/blockip.txt >> outip.txt
sed -E '/:/d; s/\/[0-9]+//g' outip.txt | grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | uniq > blackip.txt

# COPY ACL TO PATH AND LOG
sudo cp -f blackip.txt "$route"/blackip.txt
sudo bash -c 'squid -k reconfigure' 2> "$SCRIPT_DIR/SquidErrors.txt"

# DELETE REPOSITORY (Optional)
cd ..
rm -rf "$bipupdate" >/dev/null 2>&1

# END
sudo bash -c 'echo "BlackIP Done: $(date)" | tee -a /var/log/syslog'
echo "${bip09[$lang]}"
