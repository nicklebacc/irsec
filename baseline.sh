#!/bin/bash
# baseline.sh - snapshot of the state at t0.
# NOTE: may not be fully clean
# Run users.sh and persist.sh too.
. "$(dirname "$0")/common.sh"
D=$OUT/baseline; mkdir -p "$D"; touch "$D/.stamp"
getent passwd > "$D/passwd.txt"
getent group  > "$D/group.txt"
ss -tulpnH > "$D/listening.txt"
ss -tulnH | awk '{print $1,$5}' | sort > "$D/listening_ports.txt"
ps -eo pid,ppid,user,args --sort=pid > "$D/ps.txt"
find / -xdev -perm -4000 -type f 2>/dev/null | sort > "$D/suid.txt"
systemctl list-unit-files --state=enabled --no-pager > "$D/enabled_units.txt"
for u in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$u" 2>/dev/null | sed "s/^/$u: /"; done > "$D/crontabs.txt"
find /etc -type f -exec sha256sum {} + 2>/dev/null | sort -k2 > "$D/etc.sha256"
[ -d "$OUT/etc_backup" ] || cp -a /etc "$OUT/etc_backup" 2>/dev/null
echo "Baseline saved in $D (root-only). Do not copy it off the box (rule 12)."
