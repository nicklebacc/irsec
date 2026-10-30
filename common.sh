#!/bin/bash
# common.sh - sourced by every script. Detects distro + team number and defines what is OUT OF SCOPE.
# Only run during active periods
# run as admin
[ "$EUID" -eq 0 ] || { echo "Run as root"; exit 1; }
. /etc/os-release
case "$ID" in
  debian|ubuntu) FAM=deb; SSH_SVC=ssh;  ADMIN_GRP=sudo;  NFT_MAIN=/etc/nftables.conf ;;
  rocky|rhel|centos|almalinux) FAM=rpm; SSH_SVC=sshd; ADMIN_GRP=wheel; NFT_MAIN=/etc/sysconfig/nftables.conf ;;
  *) echo "Unknown distro: $ID"; exit 1 ;;
esac

# Team number X from our own IP (10.X.1.x on LAN boxes, 192.168.X.x on cloud boxes).
# Docker bridges are skipped (they also use 192.168.x.x). Override with: TEAM=7 ./script.sh
if [ -z "$TEAM" ]; then
  TEAM=$(ip -4 -o addr show scope global | awk '$2 !~ /^(docker|br-|veth)/ {print $4}' \
    | sed -nE 's#^10\.([0-9]+)\.1\.[0-9]+/.*#\1#p; s#^192\.168\.([0-9]+)\.[0-9]+/.*#\1#p' | head -1)
fi
[ -n "$TEAM" ] || { echo "Cannot detect team number. Run: TEAM=<n> $0"; exit 1; }

# ---- OUT OF SCOPE: never block, modify, rotate, kill or delete ----
MGMT_NET=172.16.1.0/24          # management network
NETBIRD_IP=10.$TEAM.1.99        # NetBird egress
BARRIER_IP=10.$TEAM.1.254       # pfSense (carries barrier -> timing syslog on 514)
PROTECTED_USERS='whiteteam|dd-agent|ddagentuser'
# Datadog: also anything with "datadog" in a service/file/dir name -> filter with grep -vi datadog
LAN_NET=10.$TEAM.1.0/24
CLOUD_NET=192.168.$TEAM.0/24

OUT=/root/blue; mkdir -p "$OUT"; chmod 700 "$OUT"
# Banner: host + time on every run
echo "[$(date '+%F %T')] $(hostname) | $(basename "$0") | team $TEAM | $PRETTY_NAME"
