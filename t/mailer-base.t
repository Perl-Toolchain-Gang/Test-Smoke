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

my %basic_mailer_args = (
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

{
    note("minimal arguments for new() and fetch_report()");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my $string = $mailer->fetch_report();
    like($string, qr/^Smoke/, "Got expected response from fetch_report");
}

{
    note("exercise _get_cc(): 1");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my ($subject, $rv);
    $subject = ' PASS';
    $rv = $mailer->_get_cc($subject);
    is($rv, '', "_get_cc() returned empty string, as expected");

    $subject = ' FAIL(X)';
    $rv = $mailer->_get_cc($subject);
    is($rv, '', "_get_cc() returned empty string, as expected");

    $subject = ' UNKNOWN';
    $rv = $mailer->_get_cc($subject);
    is($rv, '', "_get_cc() returned empty string, as expected");
}

{
    note("exercise _get_cc(): 2");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    $mailer_args{ccp5p_onfail} = 1;
    local $Test::Smoke::Mailer::Base::P5P = '';
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my ($subject, $rv);
    $subject = ' UNKNOWN';
    $rv = $mailer->_get_cc($subject);
    is($rv, '', "_get_cc() returned empty string, as expected");
}

{
    note("exercise _get_cc(): 3");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    $mailer_args{ccp5p_onfail} = 1;
    my $this_cc = 'foo@bar.com';
    $mailer_args{cc} = $this_cc;
    local $Test::Smoke::Mailer::Base::P5P = '';
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my ($subject, $rv);
    $subject = ' UNKNOWN';
    $rv = $mailer->_get_cc($subject);
    is($rv, $this_cc, "_get_cc() returned expected email address");
}

{
    note("exercise _get_cc(): 4");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    $mailer_args{ccp5p_onfail} = 1;
    my $this_cc = 'foo@bar.com';
    $mailer_args{cc} = $this_cc;
    local $Test::Smoke::Mailer::Base::P5P = '';
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my ($subject, $rv);
    $subject = ' UNKNOWN';
    $rv = $mailer->_get_cc($subject);
    is($rv, $this_cc, "_get_cc() returned expected email addresses");
}

{
    note("exercise _get_cc(): 5");

    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    $mailer_args{ccp5p_onfail} = 1;
    my $this_cc = '';
    $mailer_args{cc} = $this_cc;
    my $mailer = Test::Smoke::Mailer::Base->new(%mailer_args);
    isa_ok($mailer, 'Test::Smoke::Mailer::Base');

    my ($subject, $rv);
    $subject = ' UNKNOWN';
    $rv = $mailer->_get_cc($subject);
    is($rv, $Test::Smoke::Mailer::Base::P5P,
        "_get_cc() returned P5P list address, as expected");
}

{
    note("report file missing");

    my $bad_report = "$$-nonexistent-report.txt";
    my %mailer_args = map { $_ => $basic_mailer_args{$_}  } keys %basic_mailer_args;
    $mailer_args{rptfile} = $bad_report;
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
