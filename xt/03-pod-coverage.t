#! perl -w
use strict;

use Test::Pod::Coverage;

my @options = sort {
    length($b) <=> length($a) ||
    $a cmp $b
} map {chomp($_); $_} <DATA>;

all_pod_coverage_ok({trustme => \@options});


__DATA__
adir
archive
archiver_config
bcc
cc
ccp5p_onfail
cdir
cfg
commit_sha
curlargs
curlbin
ddir
defaultenv
fdir
force_c_locale
from
fsync
ftphost
ftpport
gitbin
gitbranchfile
gitdfbranch
gitdir
gitbare
gitorigin
handlequeue_config
harness3opts
harness_destruct
harnessonly
hasharness3
hdir
hostname
is56x
is_vms
is_win32
jsnfile
killtime
lfile
locale
mail
mail_type
mailbin
mailer_config
mailxbin
makeopt
max_reports
mdir
mserver
mspass
msport
msuser
opt_continue
outfile
patchlevel
perl5lib
perl5opt
perlio_only
poster
poster_config
qfile
report
reporter_config
reposter_config
rptfile
rsyncbin
rsyncopts
rsyncsource
runsmoke_config
send_log
send_out
sendemailbin
sendmailbin
sendreport_config
showcfg
skip_tests
smartsmoke
smokedb_url
smokeperl_config
snapurl
snapfile
snaptar
swbcc
swcc
sync
syncer
synctree_config
testmake
to
ua_timeout
un_file
un_position
user_note
vmsmake
w32args
w32cc
w32make
pass_option
configsmoke_config
minus_des
perl_version
smokestatus_config
v
w32configure_config
