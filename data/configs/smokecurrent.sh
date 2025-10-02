#! /bin/sh
#
# smokecurrent.sh: written by ./tsconfigsmoke.pl v0.103
# on 2025-10-02T14:10:15+0200
# NOTE: Changes made in this file will be \*lost\*
#       after rerunning /tmp/smoke/Test-Smoke/bin/tsconfigsmoke.pl
#
# cron: 25 22 * * * '/tmp/smoke/configs/smokecurrent.sh'
# renice 0
cd /tmp/smoke/Test-Smoke/bin
CFGNAME=/tmp/smoke/configs/smokecurrent_config
/usr/bin/perl /tmp/smoke/Test-Smoke/bin/tshandlequeue.pl - "$CFGNAME"
LOCKFILE=${LOCKFILE:-smokecurrent.lck}
continue=''
if test -f "$LOCKFILE" && test -s "$LOCKFILE" ; then
    echo "We seem to be running (or remove $LOCKFILE)" >& 2
    exit 200
fi
echo "$CFGNAME" > "$LOCKFILE"


umask 0
/usr/bin/perl /tmp/smoke/Test-Smoke/bin/tssmokeperl.pl -c "$CFGNAME" $continue $* > "/tmp/smoke/logs/smokecurrent.log" 2>&1

rm "$LOCKFILE"
