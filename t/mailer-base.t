use strict;
use warnings;

use Cwd;
use File::Copy;
use File::Spec;
use File::Temp qw/ tempdir /;

use Test::More;

use_ok( 'Test::Smoke::Mailer::Base' );

my $cwd = cwd();
my $dummy_copy_dir = File::Spec->catdir($cwd, 't', 'logs', 'rtc-126010');
ok(-d $dummy_copy_dir, "Located directory for dummy copy");
my $rpt = 'mktest.rpt';
my $rpt_file = File::Spec->catfile($dummy_copy_dir, $rpt);
ok(-f $rpt_file, "rpt file located for testing");

my $tdir = tempdir(CLEANUP => 1);

copy $rpt_file => $tdir or die;

{
    my %mailer_args = (
        bcc             => '',
        cc              => '',
        ccp5p_onfail    => 0,
        ddir            => $tdir,
        from            => '',
        rptfile         => $rpt,
        to              => 'daily-build-reports@perl.org',
        sendmailbin     => 'sendmail',
        v               => 0,
    );
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my $string = $mailer->fetch_report();
    like($string, qr/^Smoke/, "Got expected response from fetch_report");
}

{
    my $bad_report = "$$-nonexistent-report.txt";
    my %mailer_args = (
        bcc             => '',
        cc              => '',
        ccp5p_onfail    => 0,
        ddir            => $tdir,
        from            => '',
        rptfile         => $bad_report,
        to              => 'daily-build-reports@perl.org',
        sendmailbin     => 'sendmail',
        v               => 0,
    );
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    local $@;
    my $bad_report_path = File::Spec->catfile($tdir, $bad_report);
    ok(! -f $bad_report_path, "File does not exist (as intended)");
    my $expect = "Cannot read '\Q$bad_report_path\E'";
    eval { $mailer->fetch_report(); };
    like($@, qr/^$expect/,
        "Got expected error message from non-existent report file");

    my $error = $mailer->error();
    is($error, '', "No error because none set directly in Test::Smoke::Mailer::Base");
}

done_testing();
