#!/bin/bash
# users_audit.sh -> AUDIT ONLY
# Never touches whiteteam / dd-agent / ddagentuser
. "$(dirname "$0")/common.sh"

# Takes no arguments. Refuse any so a typo can't be misread.
if [ $# -gt 0 ]; then
  echo "Usage: $0"
  exit 1
fi

protected() { echo "$1" | grep -Eq "^($PROTECTED_USERS)$"; }
EXPECTED="root|$PROTECTED_USERS|scrutineer|techdirector|crewchief|firecrew|jackcrew|garagecrew|celebrity|pitlaner|reserve|gunners"

echo "== UID 0 accounts (expect root; leave whiteteam alone if it appears) =="
awk -F: '$3==0{print $1}' /etc/passwd

echo "== Empty passwords =="
awk -F: '$2==""{print $1}' /etc/shadow

echo "== Login-shell users (out-of-scope ones marked) =="
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1":"$3":"$7}' /etc/passwd \
  | sed -E "s/^($PROTECTED_USERS):/[LEAVE ALONE] &/"

echo "== Login users NOT in the packet's user list (investigate before touching) =="
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1}' /etc/passwd | grep -Ev "^($EXPECTED)$"

echo "== Admin / docker group members =="
getent group "$ADMIN_GRP" docker

echo "== sudoers rules (whiteteam hidden) =="
grep -rEv '^\s*(#|$)' /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v whiteteam | grep -Ei 'nopasswd|ALL='

echo "== authorized_keys files (whiteteam / datadog hidden) =="
find / -xdev \( -name authorized_keys -o -name authorized_keys2 \) -type f 2>/dev/null | grep -vi datadog | while read -r f; do
  o=$(stat -c %U "$f"); protected "$o" && continue
  echo "-- $f (owner: $o)"; ssh-keygen -lf "$f" 2>/dev/null
done
