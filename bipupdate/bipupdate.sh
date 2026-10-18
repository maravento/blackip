#!/bin/bash
# maravento.com
#
################################################################################
#
# BlackIP Update
# FILE: bipupdate/bipupdate.sh
#
# USAGE:
# ./bipupdate.sh
#
# LOG: bipupdate.log (generated in the script directory)
#
################################################################################

set -uo pipefail

# ------------------------------------------------------------------------------
# REQUIREMENTS
# ------------------------------------------------------------------------------

# no-root check
if [ "$(id -u)" == "0" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: This script should not be run as root -abort" >&2
    exit 1
fi

# prevent overlapping runs
script_lock="/var/lock/$(basename "$0" .sh).lock"
(umask 077; : >> "$script_lock") || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: cannot open $(basename "$script_lock") -abort" >&2
    exit 1
}
exec 200>"$script_lock"
if ! flock -n 200; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: script $(basename "$0") is already running -abort" >&2
    exit 1
fi

# logging
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_file="$script_dir/bipupdate.log"
{ > "$log_file"; } 2>/dev/null || true
log() {
    local log_msg="$(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$log_msg" >> "$log_file" 2>/dev/null || true
    if [[ "$1" == ERROR:* ]]; then
        echo "$log_msg" >&2
    else
        echo "$log_msg"
    fi
}

# Function: Report whether a package is installed, not merely residual
package_installed() {
    [ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" = installed ]
}

# dependencies
for dep_pkg in wget git curl tar unzip zip gzip idn2 grepcidr python3 bind9-host findutils grep sed coreutils util-linux sudo; do
    if ! package_installed "$dep_pkg"; then
        log "ERROR: dependency '$dep_pkg' is not installed -abort"
        exit 1
    fi
done

# dependencies (squid or squid-openssl)
if ! package_installed squid && ! package_installed squid-openssl; then
    log "ERROR: 'squid' or 'squid-openssl' is not installed -abort"
    exit 1
fi

# ------------------------------------------------------------------------------
# CHECKS
# ------------------------------------------------------------------------------

squid_conf="/etc/squid/squid.conf"

# Edit /etc/squid/squid.conf and add lines:
# acl blackip dst "/path_to/blackip.txt"
# http_access deny blackip
check_squid_acl() {
    if ! grep -qE '^[[:space:]]*acl[[:space:]]+blackip[[:space:]]+dst([[:space:]]|$)' "$squid_conf"; then
        log "ERROR: 'acl blackip dst' not found -abort"
        exit 1
    fi
    if ! grep -qE '^[[:space:]]*http_access[[:space:]]+deny[[:space:]]+blackip([[:space:]]|$)' "$squid_conf"; then
        log "ERROR: 'http_access deny blackip' not found -abort"
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
        log "INFO: squid is not active, starting it"
        squid_start
        for wait_attempt in $(seq 1 30); do
            squid_is_active && break
            sleep 2
        done
        if ! squid_is_active; then
            log "ERROR: squid failed to start -abort"
            exit 1
        fi
        log "INFO: squid was not active, started -fixed"
    fi
}

check_squid_acl
check_squid_status

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

cd "$script_dir" || { log "ERROR: cannot enter bipupdate path -abort"; exit 1; }
repo_dir="$script_dir/bipupdate"
# validation -- one variable per thing validated; use directly with =~
UH_IPV4='^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])$'
sort_uniq="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wget_opts="wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4"
trap 'rm -f blackip_preview.txt blackip_tmp.txt cleanip.txt outip.txt sqerror.txt; exit 130' INT TERM
# path_to_lst (Change it to the directory of your preference)
acl_dir="/etc/acl"
if [ ! -d "$acl_dir" ]; then
    sudo mkdir -p "$acl_dir" || {
        log "ERROR: cannot create $acl_dir -abort"
        exit 1
    }
fi

log "bipupdate start..."

# ------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------

# check dnslookup1.txt
if [ ! -e "$repo_dir"/dnslookup1.txt ]; then

    # delete old repository
    rm -rf "$repo_dir" >/dev/null 2>&1

    # download geozones (optional)
    download_ipdeny() {
        local http_code
        zones_dir="/etc/zones"
        source_url="http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz"
        # create dir
        if [ ! -d "$zones_dir" ]; then
            sudo mkdir -p "$zones_dir" || {
                log "ERROR: cannot create $zones_dir -abort"
                exit 1
            }
        fi
        # check with curl
        http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
        case "$http_code" in
            2*|405) ;;
            000) log "TIMEOUT: $source_url"; exit 1 ;;
            5*)  log "BUSY: $http_code $source_url"; exit 1 ;;
            404|410)   log "BROKEN: $http_code $source_url"; exit 1 ;;
            *)   log "HTTP_ERROR: $http_code $source_url"; exit 1 ;;
        esac
        # download
        if ! $wget_opts "$source_url" -O all-zones.tar.gz; then
            log "PARTIAL: $source_url"
            exit 1
        fi
        log "SAVED: all-zones.tar.gz"
        # extract
        if ! sudo tar -C "$zones_dir" -zxvf all-zones.tar.gz >/dev/null 2>&1; then
            log "ERROR: cannot extract all-zones.tar.gz -abort"
            rm -f all-zones.tar.gz
            exit 1
        fi
        # clean
        rm -f all-zones.tar.gz >/dev/null 2>&1
    }

    read -r -p "Download IPDeny country zones? [y/N]: " ipdeny_answer
    if [[ "$ipdeny_answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        download_ipdeny
    fi

    # download blackip
    if ! $wget_opts https://raw.githubusercontent.com/maravento/vault/master/scripts/python/gitfolder.py -O gitfolder.py; then
        log "PARTIAL: https://raw.githubusercontent.com/maravento/vault/master/scripts/python/gitfolder.py"
        exit 1
    fi
    log "SAVED: gitfolder.py"
    chmod +x gitfolder.py
    python3 gitfolder.py https://github.com/maravento/blackip/bipupdate || {
        log "ERROR: gitfolder.py failed to clone bipupdate -abort"
        exit 1
    }
    rm -f gitfolder.py
    if [ -d "$repo_dir" ]; then
        cd "$repo_dir" || {
            log "ERROR: cannot enter bipupdate path -abort"
            exit 1
        }
    else
        log "ERROR: $(basename "$repo_dir") does not exist -abort"
        exit 1
    fi

    # downloading blocklists
    blips() {
        local source_url="$1"
        local source_label http_code

        source_label=$(basename "${source_url%%\?*}" | sed 's/[^a-zA-Z0-9._-]/_/g')

        http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
        case "$http_code" in
            2*|405) ;;
            000) log "TIMEOUT: $source_url"; return 1 ;;
            5*)  log "BUSY: $http_code $source_url"; return 1 ;;
            404|410)   log "BROKEN: $http_code $source_url"; return 1 ;;
            *)   log "HTTP_ERROR: $http_code $source_url"; return 1 ;;
        esac

        if $wget_opts "$source_url" -O - 2>/dev/null | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort -u >> capture.txt; then
            log "SAVED: $source_label"
        else
            log "PARTIAL: $source_url"
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
        local source_url="$1"
        local download_file http_code
        # filename
        download_file=$(basename "${source_url%%\?*}")
        # check with curl
        http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
        case "$http_code" in
            2*|405) ;;
            000) log "TIMEOUT: $source_url"; return 1 ;;
            5*)  log "BUSY: $http_code $source_url"; return 1 ;;
            404|410)   log "BROKEN: $http_code $source_url"; return 1 ;;
            *)   log "HTTP_ERROR: $http_code $source_url"; return 1 ;;
        esac
        # Download
        if ! $wget_opts "$source_url" -O "$download_file"; then
            log "PARTIAL: $source_url"
            return 1
        fi
        log "SAVED: $download_file"
        # extract
        if ! gunzip -c -f "$download_file" \
             | grep -a -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            log "WARNING: cannot extract $download_file -alert"
            rm -f "$download_file"
            return 1
        fi
        # clean
        rm -f "$download_file"
        return 0
    }
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-1.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-2.uceprotect.net.gz' && sleep 2
    uceprotect 'http://wget-mirrors.uceprotect.net/rbldnsd-all/dnsbl-3.uceprotect.net.gz' && sleep 2

    listed_ip_180_all() {
        local source_url="$1"
        local download_file http_code
        # filename
        download_file=$(basename "${source_url%%\?*}")
        # check with curl
        http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
        case "$http_code" in
            2*|405) ;;
            000) log "TIMEOUT: $source_url"; return 1 ;;
            5*)  log "BUSY: $http_code $source_url"; return 1 ;;
            404|410)   log "BROKEN: $http_code $source_url"; return 1 ;;
            *)   log "HTTP_ERROR: $http_code $source_url"; return 1 ;;
        esac
        # download
        if ! $wget_opts "$source_url" -O "$download_file"; then
            log "PARTIAL: $source_url"
            return 1
        fi
        log "SAVED: $download_file"
        # extract
        if ! unzip -p "$download_file" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            log "WARNING: cannot extract $download_file -alert"
            rm -f "$download_file"
            return 1
        fi
        # clean
        rm -f "$download_file"
        return 0
    }
    listed_ip_180_all 'https://www.stopforumspam.com/downloads/listed_ip_180_all.zip'

    full_blacklist_database() {
        local source_url="$1"
        local download_file http_code
        # filename
        download_file=$(basename "${source_url%%\?*}")
        # check with curl
        http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
        case "$http_code" in
            2*|405) ;;
            000) log "TIMEOUT: $source_url"; return 1 ;;
            5*)  log "BUSY: $http_code $source_url"; return 1 ;;
            404|410)   log "BROKEN: $http_code $source_url"; return 1 ;;
            *)   log "HTTP_ERROR: $http_code $source_url"; return 1 ;;
        esac
        # download
        if ! $wget_opts "$source_url" -O "$download_file"; then
            log "PARTIAL: $source_url"
            return 1
        fi
        log "SAVED: $download_file"
        # extract
        if ! unzip -p "$download_file" \
             | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" \
             | sort -u >> capture.txt; then
            log "WARNING: cannot extract $download_file -alert"
            rm -f "$download_file"
            return 1
        fi
        # clean
        rm -f "$download_file"
        return 0
    }
    full_blacklist_database 'https://myip.ms/files/blacklist/general/full_blacklist_database.zip'
    if [ ! -s capture.txt ]; then
        log "ERROR: capture.txt is empty -abort"
        exit 1
    fi

    log "Debugging BlackIP..."
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
    | grep -oP "$UH_IPV4" \
    | awk -F. '$1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255' \
    | $sort_uniq > cleancapture.txt
    pipe_status=("${PIPESTATUS[@]}")
    if [ "${pipe_status[0]}" -ne 0 ] || [ "${pipe_status[1]}" -gt 1 ] ||
        [ "${pipe_status[2]}" -ne 0 ] || [ "${pipe_status[3]}" -ne 0 ]; then
        log "ERROR: cannot debug capture.txt -abort"
        exit 1
    fi
    if [ ! -s cleancapture.txt ]; then
        log "ERROR: cleancapture.txt is empty -abort"
        exit 1
    fi

    # DEBBUGGING BLACKIP
    # First you must edit /etc/squid/squid.conf
    # And add line:
    # acl blackip dst "/path_to_lst/blackip.txt"
    # http_access deny blackip
    grep -vFxf lst/allowip.txt cleancapture.txt | sed -r 's/^\s+*//;s/\s+*$//' | $sort_uniq > dnsinput.txt
    pipe_status=("${PIPESTATUS[@]}")
    if [ "${pipe_status[0]}" -gt 1 ] || [ "${pipe_status[1]}" -ne 0 ] ||
        [ "${pipe_status[2]}" -ne 0 ]; then
        log "ERROR: cannot apply allowip.txt to cleancapture.txt -abort"
        exit 1
    fi
    if [ ! -s dnsinput.txt ]; then
        log "ERROR: dnsinput.txt is empty -abort"
        exit 1
    fi
else
    cd "$repo_dir" || {
        log "ERROR: cannot enter bipupdate path -abort"
        exit 1
    }
fi

# ------------------------------------------------------------------------------
# DNS LOOKUP
# ------------------------------------------------------------------------------

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
# parallel_procs=$(($(nproc))) # Conservative (network-friendly)
# parallel_procs=$(($(nproc) * 2)) # Balanced
# parallel_procs=$(($(nproc) * 4)) # Aggressive (default)
# parallel_procs=$(($(nproc) * 8)) # Extreme (8 or higher, use with caution)
#
# Example: Core i5 with 4 physical cores and 8 threads (Hyper-Threading)
# nproc -> 8
# parallel_procs=$((8 * 4)) -> 32 parallel queries
#
# Adjust based on:
# - Your CPU
# - Your network (bandwidth/latency)
# - Desired balance between speed and system load
parallel_procs=$(($(nproc) * 4))

# Function: Stop the progress indicator before continuing or aborting
stop_progress() {
    kill "$progress_pid" 2>/dev/null
    echo
}

# step 1:
if [ ! -e "$repo_dir"/dnslookup2.txt ]; then
    log "1st DNS Lookup..."
    if ! { sed 's/^\.//g' dnsinput.txt | sort -u > step1.txt; }; then
        log "ERROR: cannot process dnsinput.txt into step1.txt -abort"
        exit 1
    fi
    if [ ! -s step1.txt ]; then
        log "ERROR: step1.txt is empty -abort"
        exit 1
    fi
    total_domains=$(wc -l < step1.txt)
    (
        while sleep 1; do
            processed_count=$(wc -l < dnslookup1.txt 2>/dev/null)
            percent_done=$(awk -v p="$processed_count" -v t="$total_domains" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
            printf "Processed: %d / %d (%s%%)\r" "$processed_count" "$total_domains" "$percent_done"
        done
    ) &
    progress_pid=$!
    if ! { if [ -s dnslookup1.txt ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup1.txt step1.txt
    else
        cat step1.txt
    fi | xargs -I {} -P "$parallel_procs" sh -c 'if host -W 1 -- "$1" >/dev/null 2>&1; then echo "HIT $1"; else echo "FAULT $1"; fi' _ {} >> dnslookup1.txt; }; then
        stop_progress
        log "ERROR: 1st DNS lookup failed -abort"
        exit 1
    fi
    stop_progress

    if ! { sed '/^FAULT/d' dnslookup1.txt | awk '{print $2}' | awk '{print "." $1}' | sort -u > hit.txt &&
        sed '/^HIT/d' dnslookup1.txt | awk '{print $2}' | awk '{print "." $1}' | sort -u >> fault.txt &&
        sort -o fault.txt -u fault.txt; }; then
        log "ERROR: cannot classify DNS results as hit or fault -abort"
        exit 1
    fi
fi

sleep 5

# step 2:
log "2nd DNS Lookup..."
if ! { sed 's/^\.//g' fault.txt | sort -u > step2.txt; }; then
    log "ERROR: cannot prepare step2.txt -abort"
    exit 1
fi
if [ -s step2.txt ]; then
    total_domains=$(wc -l < step2.txt)
    (
        while sleep 1; do
            processed_count=$(wc -l < dnslookup2.txt 2>/dev/null)
            percent_done=$(awk -v p="$processed_count" -v t="$total_domains" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
            printf "Processed: %d / %d (%s%%)\r" "$processed_count" "$total_domains" "$percent_done"
        done
    ) &
    progress_pid=$!
    if ! { if [ -s dnslookup2.txt ]; then
        awk 'FNR==NR {seen[$2]=1;next} seen[$1]!=1' dnslookup2.txt step2.txt
    else
        cat step2.txt
    fi | xargs -I {} -P "$parallel_procs" sh -c 'if host -W 2 -- "$1" >/dev/null 2>&1; then echo "HIT $1"; else echo "FAULT $1"; fi' _ {} >> dnslookup2.txt; }; then
        stop_progress
        log "ERROR: 2nd DNS lookup failed -abort"
        exit 1
    fi
    stop_progress
else
    log "INFO: no unresolved domains from 1st lookup -skip"
fi
touch dnslookup2.txt

if ! { sed '/^FAULT/d' dnslookup2.txt | awk '{print $2}' | sort -u >> hit.txt &&
    sed '/^HIT/d' dnslookup2.txt | awk '{print $2}' | sort -u > fault.txt; }; then
    log "ERROR: cannot classify DNS results as hit or fault -abort"
    exit 1
fi

# ------------------------------------------------------------------------------
# RELOAD
# ------------------------------------------------------------------------------

log "Squid Reload..."
if ! { sed '/^$/d; /#/d' hit.txt | sed 's/^\.//' | sort -u > blackip_preview.txt; }; then
    log "ERROR: cannot build blackip_preview.txt -abort"
    exit 1
fi
sudo cp -f blackip_preview.txt "$acl_dir"/blackip.txt || {
    log "ERROR: cannot copy blackip_preview.txt to $acl_dir -abort"
    exit 1
}
check_squid_status
sudo bash -c 'squid -k reconfigure' 2> sqerror.txt || {
    log "ERROR: squid reconfigure failed with preview list -abort"
    exit 1
}
# a day without entries is normal here; only a read error aborts
sudo bash -c 'grep "$(date +%Y/%m/%d)" /var/log/squid/cache.log' >> sqerror.txt
if [ "$?" -gt 1 ]; then
    log "ERROR: cannot read /var/log/squid/cache.log -abort"
    exit 1
fi
# a search without matches is normal here; only a real error aborts
grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}" sqerror.txt | grep -oP "$UH_IPV4" | $sort_uniq | sort -u > cleanip.txt
pipe_status=("${PIPESTATUS[@]}")
if [ "${pipe_status[0]}" -gt 1 ] || [ "${pipe_status[1]}" -gt 1 ] ||
    [ "${pipe_status[2]}" -ne 0 ] || [ "${pipe_status[3]}" -ne 0 ]; then
    log "ERROR: cannot extract IPs of sqerror.txt -abort"
    exit 1
fi
if ! python3 tools/debugbip.py; then
    log "ERROR: debugbip.py failed -abort"
    exit 1
fi
cat lst/blockip.txt >> outip.txt || {
    log "ERROR: cannot append blockip.txt to outip.txt -abort"
    exit 1
}
sed -E '/:/d; s/\/[0-9]+//g' outip.txt | grep -oP "$UH_IPV4" | $sort_uniq > blackip_tmp.txt
pipe_status=("${PIPESTATUS[@]}")
if [ "${pipe_status[0]}" -ne 0 ] || [ "${pipe_status[1]}" -gt 1 ] ||
    [ "${pipe_status[2]}" -ne 0 ]; then
    log "ERROR: cannot normalize outip.txt -abort"
    exit 1
fi
# remove conflicts (iana.txt, dns.txt)
dns_filter="$(mktemp)" || {
    log "ERROR: cannot create dns.txt filter -abort"
    exit 1
}
if ! sed '/^#/d' lst/dns.txt > "$dns_filter"; then
    rm -f "$dns_filter"
    log "ERROR: cannot read dns.txt -abort"
    exit 1
fi
grepcidr -vf lst/iana.txt blackip_tmp.txt | grep -vFxf "$dns_filter" | $sort_uniq > blackip.txt
pipe_status=("${PIPESTATUS[@]}")
rm -f "$dns_filter"
if [ "${pipe_status[0]}" -gt 1 ] || [ "${pipe_status[1]}" -gt 1 ] ||
    [ "${pipe_status[2]}" -ne 0 ]; then
    log "ERROR: cannot remove iana.txt and dns.txt conflicts -abort"
    exit 1
fi
rm -f blackip_tmp.txt
if [ ! -s blackip.txt ]; then
    log "ERROR: blackip.txt is empty -abort"
    exit 1
fi

# copy acl to path and log
sudo cp -f blackip.txt "$acl_dir"/blackip.txt || {
    log "ERROR: cannot copy blackip.txt to $acl_dir -abort"
    exit 1
}
check_squid_status
sudo bash -c 'squid -k reconfigure' 2> "$script_dir/SquidErrors.txt" || {
    log "ERROR: squid reconfigure failed with blackip.txt -abort"
    exit 1
}

cd .. || {
    log "ERROR: cannot enter bipupdate path -abort"
    exit 1
}

# ------------------------------------------------------------------------------
# END
# ------------------------------------------------------------------------------

log "bipupdate done at: $(date '+%Y-%m-%d %H:%M:%S')"
log "INFO: Check SquidErrors.txt"
