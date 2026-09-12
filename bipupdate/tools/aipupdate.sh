#!/bin/bash
# maravento.com
#
################################################################################
#
# AllowIP for Reverse Squid
# log: aipupdate.log (generated in the execution directory)
# 
# used:	host -t a / or / dig +short -f
# dig example.com +nostats +nocomments +nocmd
#
################################################################################

set -uo pipefail

# ------------------------------------------------------------------------------
# REQUIREMENTS
# ------------------------------------------------------------------------------

# logging
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_file="$script_dir/aipupdate.log"
{ > "$log_file"; } 2>/dev/null || true
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$log_file" 2>/dev/null || true
}

# check no-root
if [ "$(id -u)" == "0" ]; then
    log "ERROR: This script should not be run as root -- abort"
    exit 1
fi

# prevent overlapping runs
script_lock="/var/lock/$(basename "$0" .sh).lock"
(umask 077; : >> "$script_lock")
exec 200>"$script_lock"
if ! flock -n 200; then
    log "ERROR: script $(basename "$0") is already running -- abort"
    exit 1
fi

# dependencies
for dep_pkg in wget curl bind9-host grepcidr findutils grep sed coreutils util-linux; do
    if ! dpkg -s "$dep_pkg" &>/dev/null; then
        log "ERROR: '$dep_pkg' is not installed -- abort"
        exit 1
    fi
done

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

cd "$script_dir" || { log "ERROR: cannot cd to $(basename "$script_dir") -- abort"; exit 1; }
lst_dir="$script_dir/../lst"
allowip_file="$lst_dir/allowip.txt"
sort_uniq="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wget_opts='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'
trap 'rm -f urls.txt out.txt progress.txt; exit 130' INT TERM

log "aipupdate start..."
log "This process can take a long time. Be patient..."

# ------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------

log "Downloading Allow URLs..."
intacls() {
    local source_url="$1" http_code
    http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
    case "$http_code" in
        2*|405) ;;
        000) log "TIMEOUT: $source_url"; return 1 ;;
        5*)  log "BUSY: $source_url"; return 1 ;;
        *)   log "BROKEN: $source_url"; return 1 ;;
    esac
    if ! $wget_opts "$source_url" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u > urls.txt; then
        log "PARTIAL: $source_url"
        return 1
    fi
    log "SAVED: $(basename "${source_url%%\?*}")"
}
intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/debugwl.txt' && sleep 1
log "OK"

# debbuging allow whiteIP (CIDR)
log "Debugging AllowIP..."
parallel_procs=$(($(nproc) * 4))
if [ ! -s urls.txt ]; then
    log "ERROR: urls.txt is empty -- abort"
    exit 1
fi
total_domains=$(wc -l < urls.txt)
: > progress.txt
(
    while sleep 1; do
        processed_count=$(wc -l < progress.txt 2>/dev/null)
        percent_done=$(awk -v p="$processed_count" -v t="$total_domains" 'BEGIN { if (t > 0) printf "%.2f", (p/t)*100; else print 100 }')
        printf "Processed: %d / %d (%s%%)\r" "$processed_count" "$total_domains" "$percent_done"
    done
) &
progress_pid=$!
xargs -I {} -P "$parallel_procs" bash -c 'for host_prefix in "" "www." "ftp."; do host -t a "${host_prefix}$1"; done; echo >> progress.txt' _ {} <urls.txt | grep "has address" | awk '{ print $4 }' > out.txt
kill "$progress_pid" 2>/dev/null
log "OK"
# Remove conflicts (iana.txt, dns.txt)
grepcidr -vf "$lst_dir/iana.txt" out.txt | grep -vFxf <(sed '/^#/d' "$lst_dir/dns.txt") | $sort_uniq > "$allowip_file"
sort -u "$allowip_file" -o "$allowip_file"

# ------------------------------------------------------------------------------
# END
# ------------------------------------------------------------------------------

log "Copy Allow IP to Squid and eliminate the conflicts"
rm -f urls.txt out.txt progress.txt
log "aipupdate done at: $(date)"
command -v notify-send &>/dev/null && notify-send "AllowIP Update Done" "$(date)" -i checkbox
