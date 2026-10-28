#!/bin/bash
# maravento.com
#
################################################################################
#
# AllowIP for Reverse Squid
# FILE: bipupdate/tools/aipupdate.sh
#
# USAGE:
# ./aipupdate.sh
#
# LOG: aipupdate.log (generated in the script directory)
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
log_file="$script_dir/aipupdate.log"
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
for dep_pkg in wget curl bind9-host grepcidr findutils grep sed coreutils util-linux iproute2 libc-bin; do
    if ! package_installed "$dep_pkg"; then
        log "ERROR: dependency '$dep_pkg' is not installed -abort"
        exit 1
    fi
done

# check ipv4 interfaces
list_ifaces() {
    ip -br link show 2>/dev/null | awk '$1 != "lo" {sub(/@.*/, "", $1); printf "%s %s\n", $1, ($2 == "UP") ? "UP" : "DOWN"}'
}

list_ipv4_ifaces() {
    local iface state
    while read -r iface state; do
        [ "$state" = UP ] || continue
        if ip -4 -o addr show dev "$iface" scope global 2>/dev/null \
            | awk '$4 != "" {found=1} END {exit !found}'; then
            printf '%s\n' "$iface"
        fi
    done < <(list_ifaces)
}

check_ipv4_interfaces() {
    local max_attempts=24 attempt=1

    while (( attempt <= max_attempts )); do
        if [ -n "$(list_ipv4_ifaces)" ]; then
            return 0
        fi
        if (( attempt == 1 )); then
            log "INFO: waiting for an interface with IPv4..."
        fi
        attempt=$((attempt + 1))
        sleep 5
    done

    log "ERROR: no interface with IPv4 -abort"
    exit 1
}

# check internet
check_internet() {
    local max_attempts=24 attempt=1

    while (( attempt <= max_attempts )); do
        if getent hosts www.google.com >/dev/null 2>&1; then
            return 0
        fi
        if (( attempt == 1 )); then
            log "INFO: waiting for internet..."
        fi
        attempt=$((attempt + 1))
        sleep 5
    done

    log "ERROR: no internet connection -abort"
    exit 1
}

check_ipv4_interfaces
check_internet

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

cd "$script_dir" || { log "ERROR: cannot enter aipupdate path -abort"; exit 1; }
lst_dir="$script_dir/../lst"
allowip_file="$lst_dir/allowip.txt"
acl_tmp="$allowip_file.tmp"
sort_uniq="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n -u"
wget_opts='wget -q -c --no-check-certificate --retry-connrefused --timeout=10 --tries=4'
trap 'rm -f urls.txt out.txt progress.txt dnsplain.txt ianaok.txt aclnew.txt "$acl_tmp"; exit 130' INT TERM

log "EVENT: aipupdate start..."

# ------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------

intacls() {
    local source_url="$1" http_code
    http_code=$(curl -k -s -o /dev/null -w '%{http_code}' -I -L --connect-timeout 5 --max-time 15 --retry 1 "$source_url")
    case "$http_code" in
        2*|405) ;;
        000) log "TIMEOUT: $source_url"; return 1 ;;
        5*)  log "BUSY: $http_code $source_url"; return 1 ;;
        404|410)   log "BROKEN: $source_url"; return 1 ;;
        *)   log "HTTP_ERROR: $http_code $source_url"; return 1 ;;
    esac
    if ! $wget_opts "$source_url" -O - | sed '/^$/d; /#/d' | sed 's:^\.::' | sort -u > urls.txt; then
        log "PARTIAL: $source_url"
        return 1
    fi
    log "SAVED: $(basename "${source_url%%\?*}")"
}
if ! intacls 'https://raw.githubusercontent.com/maravento/blackweb/master/bwupdate/lst/debugwl.txt'; then
    log "ERROR: cannot download allow list -abort"
    exit 1
fi
sleep 1

# debbuging allow whiteIP (CIDR)
log "EVENT: Debugging AllowIP..."
parallel_procs=$(($(nproc) * 4))
if [ ! -s urls.txt ]; then
    log "ERROR: urls.txt is empty -abort"
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
pipe_rc=("${PIPESTATUS[@]}")
kill "$progress_pid" 2>/dev/null
if [ "${pipe_rc[0]}" -ne 0 ] && [ "${pipe_rc[0]}" -ne 123 ]; then
    log "ERROR: cannot resolve domain list -abort"
    exit 1
fi
if [ "${pipe_rc[1]}" -gt 1 ]; then
    log "ERROR: cannot filter resolved addresses -abort"
    exit 1
fi
if [ "${pipe_rc[2]}" -ne 0 ]; then
    log "ERROR: cannot extract resolved addresses -abort"
    exit 1
fi
if [ ! -s out.txt ]; then
    log "ERROR: out.txt is empty -abort"
    exit 1
fi

# Remove conflicts (iana.txt, dns.txt)
for lst_file in "$lst_dir/iana.txt" "$lst_dir/dns.txt"; do
    if [ ! -s "$lst_file" ]; then
        log "ERROR: $(basename "$lst_file") is missing or empty -abort"
        exit 1
    fi
done

if ! sed '/^#/d' "$lst_dir/dns.txt" > dnsplain.txt; then
    log "ERROR: cannot read dns.txt -abort"
    exit 1
fi

grepcidr -vf "$lst_dir/iana.txt" out.txt > ianaok.txt
filter_rc=$?
if [ "$filter_rc" -gt 1 ]; then
    log "ERROR: cannot apply iana.txt exclusions -abort"
    exit 1
fi

grep -vFxf dnsplain.txt ianaok.txt > aclnew.txt
filter_rc=$?
if [ "$filter_rc" -gt 1 ]; then
    log "ERROR: cannot apply dns.txt exclusions -abort"
    exit 1
fi

if [ ! -s aclnew.txt ]; then
    log "ERROR: no address survived exclusions -abort"
    exit 1
fi

if ! $sort_uniq aclnew.txt > "$acl_tmp"; then
    log "ERROR: cannot sort new ACL -abort"
    rm -f "$acl_tmp"
    exit 1
fi

if ! sort -u "$acl_tmp" -o "$acl_tmp"; then
    log "ERROR: cannot deduplicate new ACL -abort"
    rm -f "$acl_tmp"
    exit 1
fi

if [ -f "$allowip_file" ] && ! chmod --reference="$allowip_file" "$acl_tmp"; then
    log "WARNING: cannot preserve $(basename "$allowip_file") mode -alert"
fi

if ! mv -f "$acl_tmp" "$allowip_file"; then
    log "ERROR: cannot write $(basename "$allowip_file") -abort"
    rm -f "$acl_tmp"
    exit 1
fi

# ------------------------------------------------------------------------------
# END
# ------------------------------------------------------------------------------

log "INFO: allowip.txt updated"
rm -f urls.txt out.txt progress.txt dnsplain.txt ianaok.txt aclnew.txt
log "EVENT: aipupdate done"
