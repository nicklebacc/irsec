#!/bin/bash
# persist.sh - READ-ONLY hunt for persistence
# usage: ./persist.sh [verify]    ("verify" also checks files against the package DB; slower)
. "$(dirname "$0")/common.sh"
ND='datadog|dd-agent|ddagentuser'

echo "== Cron entries (all users + system) =="
grep -rEv '^\s*(#|$)' /etc/crontab /etc/cron.d /etc/anacrontab /var/spool/cron 2>/dev/null | grep -viE "$ND"
for u in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$u" 2>/dev/null | grep -Ev '^\s*(#|$)' | sed "s/^/$u: /"; done | grep -viE "$ND"
atq 2>/dev/null

echo "== systemd timers =="; systemctl list-timers --all --no-pager | grep -viE "$ND"

unpackaged() {
  for f in "$@"; do
    { [ -f "$f" ] && [ ! -L "$f" ]; } || continue
    if [ "$FAM" = deb ]; then dpkg -S "$f" >/dev/null 2>&1 || echo "$f"; else rpm -qf "$f" >/dev/null 2>&1 || echo "$f"; fi
  done
}
echo "== Unit / cron / profile / sudoers / pam files that NO package owns =="
unpackaged /etc/systemd/system/*.service /etc/systemd/system/*.timer /etc/systemd/system/*/*.conf \
           /etc/cron.*/* /etc/profile.d/* /etc/sudoers.d/* /etc/pam.d/* | grep -viE "$ND|whiteteam"

echo "== Shell startup files with suspicious content =="
grep -lEi 'nc |ncat|bash -i|/dev/tcp|curl.*\|.*sh|wget.*\|.*sh|base64|socat|python.*socket' \
  /etc/profile /etc/profile.d/* /etc/bash.bashrc /etc/bashrc /root/.bashrc /root/.profile /home/*/.bashrc /home/*/.profile /home/*/.bash_profile /etc/rc.local 2>/dev/null | grep -viE "$ND"

echo "== SUID files not present at baseline =="
find / -xdev -perm -4000 -type f 2>/dev/null | sort | diff "$OUT/baseline/suid.txt" - 2>/dev/null | grep '^>'
echo "== SUID on binaries that should never be SUID =="
find / -xdev -perm -4000 -type f 2>/dev/null | grep -E '/(bash|sh|dash|find|vim|vi|nano|python[0-9.]*|perl|cp|mv|less|more|awk|gawk|env|nmap|tar|zip|node|ruby)$'

echo "== World-writable files in system dirs =="
find /etc /usr /bin /sbin -xdev -type f -perm -0002 2>/dev/null | grep -viE "$ND"

echo "== Processes running from /tmp, /dev/shm, /var/tmp or a deleted binary =="
ls -l /proc/[0-9]*/exe 2>/dev/null | grep -E ' /tmp/| /dev/shm/| /var/tmp/|\(deleted\)' | grep -viE "$ND"

echo "== LD_PRELOAD =="; cat /etc/ld.so.preload 2>/dev/null

echo "== Listening sockets =="; ss -tulpn

if [ "$1" = verify ]; then
  echo "== Package verification (files that differ from their package) =="
  if [ "$FAM" = deb ]; then dpkg --verify 2>/dev/null; else rpm -Va 2>/dev/null; fi | grep -viE "$ND"
fi
