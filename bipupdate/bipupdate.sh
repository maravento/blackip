#!/bin/bash
# maravento.com
#
################################################################################
#
# BlackIP Update
# log: bipupdate.log (generated in the execution directory)
#
################################################################################

set -uo pipefail

# check no-root
if [ "$(id -u)" == "0" ]; then
    echo "[ERROR] This script should not be run as root."
    exit 1
fi

# prevent overlapping runs
SCRIPT_LOCK="/var/lock/$(basename "$0" .sh).lock"
exec 200>"$SCRIPT_LOCK"
if ! flock -n 200; then
    echo "[ERROR] Script $(basename "$0") is already running"
    exit 1
fi

# DEPENDENCIES
for dep in wget git curl tar unzip zip gzip idn2 grepcidr python3 bind9-host findutils gawk; do
    if ! dpkg -s "$dep" &>/dev/null; then
        echo "ERROR: Required dependency '$dep' is not installed." >&2
        exit 1
    fi
done

# DEPENDENCIES (squid or squid-openssl)
if ! dpkg -s squid &>/dev/null && ! dpkg -s squid-openssl &>/dev/null; then
    echo "ERROR: 'squid' or 'squid-openssl' is not installed." >&2
    exit 1
fi

SQUID_CONF="/etc/squid/squid.conf"

# Edit /etc/squid/squid.conf and add lines:
# acl blackip dst "/path_to/blackip.txt"
# http_access deny blackip
check_squid_acl() {
    if ! grep -qE '^[[:space:]]*acl[[:space:]]+blackip[[:space:]]+dst' "$SQUID_CONF"; then
        echo "ERROR: 'acl blackip dst' not found or commented out in $SQUID_CONF. Aborting."
        exit 1
    fi
    if ! grep -qE '^[[:space:]]*http_access[[:space:]]+deny[[:space:]]+blackip' "$SQUID_CONF"; then
        echo "ERROR: 'http_access deny blackip' not found or commented out in $SQUID_CONF. Aborting."
        exit 1
    fi
}

check_squid_status() {
    squid_is_active() {
        if command -v systemctl &>/dev/null; then
            systemctl is-active --quiet squid
        else
            sudo service squid status &>/dev/null
        fi
    }

    squid_start() {
        if command -v systemctl &>/dev/null; then
            sudo systemctl start squid
        else
            sudo service squid start
        fi
    }

    if ! squid_is_active; then
        echo "Squid is not active. Starting it..."
        squid_start
        for i in $(seq 1 30); do
            squid_is_active && break
            sleep 2
        done
        if ! squid_is_active; then
            echo "ERROR: Squid failed to start. Aborting."
            exit 1
        fi
    fi
}

check_squid_acl
check_squid_status

# Language spa-eng
bip01=("This process can take. Be patient..." "Este proceso puede tardar. Sea paciente...")
bip02=("Downloading IPDeny..." "Descargando IPDeny...")
bip03=("Downloading BlackIP..." "Descargando BlackIP...")
bip04=("Downloading Blocklists..." "Descargando Listas de Bloqueo...")
bip05=("Debugging BlackIP..." "Depurando BlackIP...")
bip06=("1st DNS Lookup..." "1ra Busqueda DNS...")
bip07=("2nd DNS Lookup..." "2da Busqueda DNS...")
bip08=("Squid Reload..." "Reiniciando Squid...")
bip09=("Check SquidErrors.txt" "Verifique SquidErrors.txt")
bip10=("Download and apply IPDeny country zones? [y/N]: " "¿Descargar y aplicar zonas de países IPDeny? [y/N]: ")

lang=$([[ "${LANG,,}" =~ ^es ]] && echo 1 || echo 0)

# VARIABLES
# Absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
LOGFILE="$(basename "$0" .sh).log"
exec > >(tee "$LOGFILE") 2>&1
bipupdate="$SCRIPT_DIR/bipupdate"
# VALIDATION -- one variable per thing validated; use directly with =~
_UH_OCT='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$'
_UH_IPV4='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$'
_UH_CIDR='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])/(3[0-2]|[12][0-9]|[0-9])$'
_UH_NETMASK='^(0\.0\.0\.0|128\.0\.0\.0|192\.0\.0\.0|224\.0\.0\.0|240\.0\.0\.0|248\.0\.0\.0|252\.0\.0\.0|254\.0\.0\.0|255\.0\.0\.0|255\.128\.0\.0|255\.192\.0\.0|255\.224\.0\.0|255\.240\.0\.0|255\.248\.0\.0|255\.252\.0\.0|255\.254\.0\.0|255\.255\.0\.0|255\.255\.128\.0|255\.255\.192\.0|255\.255\.224\.0|255\.255\.240\.0|255\.255\.248\.0|255\.255\.252\.0|255\.255\.254\.0|255\.255\.255\.0|255\.255\.255\.128|255\.255\.255\.192|255\.255\.255\.224|255\.255\.255\.240|255\.255\.255\.248|255\.255\.255\.252|255\.255\.255\.254|255\.255\.255\.255)$'
_UH_DNS='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])(,(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9]))*$'
_UH_UINT='^(0|[1-9][0-9]*)$'
_UH_PREFIX='0.0.0.0:0 128.0.0.0:1 192.0.0.0:2 224.0.0.0:3 240.0.0.0:4 248.0.0.0:5 252.0.0.0:6 254.0.0.0:7 255.0.0.0:8 255.128.0.0:9 255.192.0.0:10 255.224.0.0:11 255.240.0.0:12 255.248.0.0:13 255.252.0.0:14 255.254.0.0:15 255.255.0.0:16 255.255.128.0:17 255.255.192.0:18 255.255.224.0:19 255.255.240.0:20 255.255.248.0:21 255.255.252.0:22 255.255.254.0:23 255.255.255.0:24 255.255.255.128:25 255.255.255.192:26 255.255.255.224:27 255.255.255.240:28 255.255.255.248:29 255.255.255.252:30 255.255.255.254:31 255.255.255.255:32'
reorganize="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wgetd="wget -q -c --show-progress --no-check-certificate --retry-connrefused --timeout=10 --tries=4"
trap 'rm -f capture.txt cleancapture.txt cleancapture2.txt step1.txt step2.txt blackip_preview.txt blackip_tmp.txt cleanip.txt outip.txt sqerror.txt' INT TERM
# path_to_lst (Change it to the directory of your preference)
route="/etc/acl"
# CREATE PATH
if [ ! -d "$route" ]; then sudo mkdir -p "$route"; fi

echo "Blackip Project"
echo "${bip01[$lang]}"

# CHECK dnslookup1.txt
if [ ! -e "$bipupdate"/dnslookup1.txt ]; then

    # DELETE OLD REPOSITORY
    rm -rf "$bipupdate" >/dev/null 2>&1

    # DOWNLOADING GEOZONES (OPTIONAL)
    download_ipdeny() {
        echo "${bip02[$lang]}"
        geopath="/etc/zones"
        url="http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz"
        # create dir
        if [ ! -d "$geopath" ]; then
            sudo mkdir -p "$geopath"
        fi
        # check with curl
        if ! curl -s -f -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "URL Down: $url"
            exit 1
        fi
        # download
        if ! $wgetd "$url" -O all-zones.tar.gz; then
            echo "ERROR: $url"
            exit 1
        fi
        # extract
        if ! sudo tar -C "$geopath" -zxvf all-zones.tar.gz >/dev/null 2>&1; then
            echo "ERROR: all-zones.tar.gz"
            rm -f all-zones.tar.gz
            exit 1
        fi
        # clean
        rm -f all-zones.tar.gz >/dev/null 2>&1
        echo "OK"
    }

    read -r -p "${bip10[$lang]}" ipdeny_opt
    if [[ "$ipdeny_opt" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        download_ipdeny
    fi

    # DOWNLOAD BLACKIP
    echo "${bip03[$lang]}"
    $wgetd https://raw.githubusercontent.com/maravento/vault/master/scripts/python/gitfolder.py -O gitfolder.py
    chmod +x gitfolder.py
    python3 gitfolder.py https://github.com/maravento/blackip/bipupdate || {
        echo "ERROR: gitfolder.py failed to clone the repository."
        exit 1
    }
    rm -f gitfolder.py
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
        local label

        label=$(basename "${url%%\?*}" | sed 's/[^a-zA-Z0-9._-]/_/g')

        if ! curl -k -s -f -I --connect-timeout 5 --retry 1 "$url" >/dev/null; then
            echo "URL Down: $url"
            return 1
        fi

        echo -n "$label ... "
        if $wgetd "$url" -O - 2>/dev/null | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort -u >> capture.txt; then
            echo "OK"
        else
            echo "ERROR: $url"
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
    blips 'https://feodotracker.abuse.ch/downloads/ipblocklist_recommended.txt' && sleep 1
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
            echo "URL Down: $url"
            return 1
        fi
        # Download
        if ! $wgetd "$url" -O "$filename"; then
            echo "ERROR: $url"
            return 1
        fi
        # extract
        if ! gunzip -c -f "$filename" \
             | grep -a -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            echo "ERROR: $filename"
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
            echo "URL Down: $url"
            return 1
        fi
        # download
        if ! $wgetd "$url" -O "$filename"; then
            echo "ERROR: $url"
            return 1
        fi
        # extract
        if ! unzip -p "$filename" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            echo "ERROR: $filename"
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
            echo "URL Down: $url"
            return 1
        fi
        # download
        if ! $wgetd "$url" -O "$filename"; then
            echo "ERROR: $url"
            return 1
        fi
        # extract
        if ! unzip -p "$filename" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            echo "ERROR: $filename"
            rm -f "$filename"
            return 1
        fi
        # clean
        rm -f "$filename"
        return 0
    }
    full_blacklist_database 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip'
    if [ ! -s capture.txt ]; then
        echo "ERROR: capture.txt is empty. Aborting."
        exit 1
    fi
    echo "OK"

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
    ' capture.txt \
    | grep -oP "$_UH_IPV4" \
    | awk -F. '$1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255' \
    | $reorganize > cleancapture.txt
    if [ ! -s cleancapture.txt ]; then
        echo "ERROR: cleancapture.txt is empty. Aborting."
        exit 1
    fi

    # DEBBUGGING BLACKIP
    # First you must edit /etc/squid/squid.conf
    # And add line:
    # acl blackip dst "/path_to_lst/blackip.txt"
    # http_access deny blackip
    grep -vFxf lst/allowip.txt cleancapture.txt | sed -r 's/^\s+*//;s/\s+*$//' | $reorganize > cleancapture2.txt
    if [ ! -s cleancapture2.txt ]; then
        echo "ERROR: cleancapture2.txt is empty. Aborting."
        exit 1
    fi
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
# Number of parallel processes (PROCS) = Logical CPUs x multiplier
# The multiplier (e.g., 2, 4) controls how aggressively to parallelize. More isn't always better.
#
# +-------------------------------------------------------+
# | How to determine your CPU configuration (Linux only): |
# +-------------------------------------------------------+
# Physical cores: grep '^core id' /proc/cpuinfo | sort -u | wc -l
# Logical CPUs (threads): nproc
#
# Recommended:
# PROCS=$(($(nproc))) # Conservative (network-friendly)
# PROCS=$(($(nproc) * 2)) # Balanced
# PROCS=$(($(nproc) * 4)) # Aggressive (default)
# PROCS=$(($(nproc) * 8)) # Extreme (8 or higher, use with caution)
#
# Example: Core i5 with 4 physical cores and 8 threads (Hyper-Threading)
# nproc -> 8
# PROCS=$((8 * 4)) -> 32 parallel queries
#
# Adjust based on:
# - Your CPU
# - Your network (bandwidth/latency)
# - Desired balance between speed and system load
PROCS=$(($(nproc) * 4))

# STEP 1:
if [ ! -e "$bipupdate"/dnslookup2.txt ]; then
    echo "${bip06[$lang]}"
    sed 's/^\.//g' cleancapture2.txt | sort -u > step1.txt
    if [ ! -s step1.txt ]; then
        echo "ERROR: step1.txt is empty. Aborting."
        exit 1
    fi
    total=$(wc -l < step1.txt)
    (
        while sleep 1; do
            processed=$(wc -l < dnslookup1.txt 2>/dev/null)
            percent=$(awk -v p="$processed" -v t="$total" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
            printf "Processed: %d / %d (%s%%)\r" "$processed" "$total" "$percent"
        done
    ) &
    progress_pid=$!
    if [ -s dnslookup1.txt ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup1.txt step1.txt
    else
        cat step1.txt
    fi | xargs -I {} -P "$PROCS" sh -c 'if host -W 1 -- "$1" >/dev/null 2>&1; then echo "HIT $1"; else echo "FAULT $1"; fi' _ {} >> dnslookup1.txt
    kill "$progress_pid" 2>/dev/null
    echo

    sed '/^FAULT/d' dnslookup1.txt | awk '{print $2}' | awk '{print "." $1}' | sort -u > hit.txt
    sed '/^HIT/d' dnslookup1.txt | awk '{print $2}' | awk '{print "." $1}' | sort -u >> fault.txt
    sort -o fault.txt -u fault.txt
    echo "OK"
fi

sleep 5

# STEP 2:
echo "${bip07[$lang]}"
sed 's/^\.//g' fault.txt | sort -u > step2.txt
if [ -s step2.txt ]; then
    total=$(wc -l < step2.txt)
    (
        while sleep 1; do
            processed=$(wc -l < dnslookup2.txt 2>/dev/null)
            percent=$(awk -v p="$processed" -v t="$total" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
            printf "Processed: %d / %d (%s%%)\r" "$processed" "$total" "$percent"
        done
    ) &
    progress_pid=$!
    if [ -s dnslookup2.txt ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup2.txt step2.txt
    else
        cat step2.txt
    fi | xargs -I {} -P "$PROCS" sh -c 'if host -W 2 -- "$1" >/dev/null 2>&1; then echo "HIT $1"; else echo "FAULT $1"; fi' _ {} >> dnslookup2.txt
    kill "$progress_pid" 2>/dev/null
    echo
else
    echo "No FAULTs pending from STEP 1 - skipping STEP 2 lookups."
fi
touch dnslookup2.txt

sed '/^FAULT/d' dnslookup2.txt | awk '{print $2}' | sort -u >> hit.txt
sed '/^HIT/d' dnslookup2.txt | awk '{print $2}' | sort -u > fault.txt
echo "OK"

# RELOAD SQUID-CACHE
echo "${bip08[$lang]}"
sed '/^$/d; /#/d' hit.txt | sed 's/^\.//' | sort -u > blackip_preview.txt
sudo cp -f blackip_preview.txt "$route"/blackip.txt
check_squid_status
sudo bash -c 'squid -k reconfigure' 2> sqerror.txt
sudo bash -c 'grep "$(date +%Y/%m/%d)" /var/log/squid/cache.log' >> sqerror.txt
grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" sqerror.txt | $reorganize | sort -u > cleanip.txt
python3 tools/debugbip.py
cat lst/blockip.txt >> outip.txt
sed -E '/:/d; s/\/[0-9]+//g' outip.txt | grep -oP "$_UH_IPV4" | $reorganize > blackip_tmp.txt
# Remove conflicts (iana.txt, dns.txt)
grepcidr -vf lst/iana.txt blackip_tmp.txt | grep -vFxf <(sed '/^#/d' lst/dns.txt) | $reorganize > blackip.txt
rm -f blackip_tmp.txt
if [ ! -s blackip.txt ]; then
    echo "ERROR: blackip.txt is empty. Aborting."
    exit 1
fi

# COPY ACL TO PATH AND LOG
sudo cp -f blackip.txt "$route"/blackip.txt
check_squid_status
sudo bash -c 'squid -k reconfigure' 2> "$SCRIPT_DIR/SquidErrors.txt"

# DELETE REPOSITORY (Optional)
cd ..
rm -rf "$bipupdate" >/dev/null 2>&1

# END
echo "BlackIP Done: $(date)"
echo "${bip09[$lang]}"
