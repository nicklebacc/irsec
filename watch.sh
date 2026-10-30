#!/bin/bash
# watch.sh - READ-ONLY comparison against the baseline. e.g. to run watch -n 60 ./watch.sh
# Stop @ 12;00 and 17;00
. "$(dirname "$0")/common.sh"
D=$OUT/baseline; [ -d "$D" ] || { echo "Run baseline.sh first."; exit 1; }
echo "== New listeners =="; ss -tulnH | awk '{print $1,$5}' | sort | diff "$D/listening_ports.txt" - | grep '^>'
echo "== Established connections =="; ss -tnpH state established
echo "== Account changes =="; getent passwd | diff "$D/passwd.txt" - | grep '^[<>]'
echo "== New crontab lines =="
for u in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$u" 2>/dev/null | sed "s/^/$u: /"; done | diff "$D/crontabs.txt" - | grep '^>'
echo "== Files changed since baseline (persistence locations) =="
find /etc/systemd /usr/lib/systemd /etc/cron* /var/spool/cron* /etc/profile.d /etc/ssh /etc/sudoers.d /etc/pam.d /etc/ld.so.preload /root /home \
  -xdev -type f -newer "$D/.stamp" 2>/dev/null | grep -viE 'datadog|\.bash_history|/\.cache/|\.viminfo|/root/blue/'
echo "== /etc files whose hash changed =="
find /etc -type f -exec sha256sum {} + 2>/dev/null | sort -k2 | diff "$D/etc.sha256" - | grep '^>' | grep -vi datadog
echo "== Recent logins =="; last -n 10 -a; w
echo "== Failed SSH (last 10 min) =="
journalctl -u "$SSH_SVC" --since "10 min ago" --no-pager 2>/dev/null | grep -iE 'fail|invalid' | tail
