#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use File::Spec::Functions;
use File::Path qw( mkpath );
use File::Temp 'tempdir';

BEGIN {
    $INC{'Test/Smoke/Smoker.pm'} = 'fake';
}

use Test::Smoke;
use Test::Smoke::SourceTree qw( :mani_const );
use Test::Smoke::App::RunSmoke;
use Test::Smoke::App::Options;
$Test::Smoke::LogMixin::USE_TIMESTAMP = 0;

sub write_file {
    my ($path) = @_;
    open my $fh, '>', $path or die "Cannot create '$path': $!";
    close $fh;
}

sub write_manifest {
    my ($dir, @entries) = @_;
    my $mani = catfile($dir, 'MANIFEST');
    open my $fh, '>', $mani or die "Cannot create '$mani': $!";
    print $fh "$_\n" for @entries;
    close $fh;
}

{
    package MockSmoker;
    sub new { bless { log => [] }, shift }
    sub log { push @{ $_[0]->{log} }, $_[1] }
    sub messages { @{ $_[0]->{log} } }
}

my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));

# ---- Test::Smoke::do_manifest_check (procedural) ----

{
    my $ddir = catdir($tmpdir, 'proc_clean');
    mkpath($ddir);
    write_file(catfile($ddir, 'lib.pm'));
    write_manifest($ddir, 'MANIFEST', 'lib.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    is_deeply([$smoker->messages], [], "procedural: clean tree produces no log messages");
}

{
    my $ddir = catdir($tmpdir, 'proc_missing');
    mkpath($ddir);
    write_file(catfile($ddir, 'exists.pm'));
    write_manifest($ddir, 'MANIFEST', 'exists.pm', 'gone.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1, "procedural: one missing file logged");
    like($msgs[0], qr/MANIFEST declared 'gone\.pm' but it is missing/,
         "procedural: correct missing-file message");
}

{
    my $ddir = catdir($tmpdir, 'proc_undeclared');
    mkpath($ddir);
    write_file(catfile($ddir, 'declared.pm'));
    write_file(catfile($ddir, 'extra.pm'));
    write_manifest($ddir, 'MANIFEST', 'declared.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1, "procedural: one undeclared file logged");
    like($msgs[0], qr/MANIFEST did not declare 'extra\.pm'/,
         "procedural: correct undeclared-file message");
}

{
    my $ddir = catdir($tmpdir, 'proc_both');
    mkpath($ddir);
    write_file(catfile($ddir, 'present.pm'));
    write_file(catfile($ddir, 'bonus.pm'));
    write_manifest($ddir, 'MANIFEST', 'present.pm', 'absent.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    my @msgs = $smoker->messages;
    is(scalar @msgs, 2, "procedural: missing + undeclared both logged");

    my @missing = grep { /missing/ } @msgs;
    my @undecl  = grep { /did not declare/ } @msgs;
    is(scalar @missing, 1, "procedural: one missing");
    is(scalar @undecl,  1, "procedural: one undeclared");
}

# The procedural version hardcodes 'mktest.out' and 'mktest.rpt' as exclusions
{
    my $ddir = catdir($tmpdir, 'proc_exclude');
    mkpath($ddir);
    write_file(catfile($ddir, 'code.pm'));
    write_file(catfile($ddir, 'mktest.out'));
    write_file(catfile($ddir, 'mktest.rpt'));
    write_manifest($ddir, 'MANIFEST', 'code.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    my @msgs = $smoker->messages;
    is(scalar @msgs, 0,
       "procedural: mktest.out and mktest.rpt excluded from undeclared check");
}

# The procedural version does NOT exclude patchlevel.bak
{
    my $ddir = catdir($tmpdir, 'proc_patchlevel');
    mkpath($ddir);
    write_file(catfile($ddir, 'code.pm'));
    write_file(catfile($ddir, 'patchlevel.bak'));
    write_manifest($ddir, 'MANIFEST', 'code.pm');

    my $smoker = MockSmoker->new;
    Test::Smoke::do_manifest_check($ddir, $smoker);
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1,
       "procedural: patchlevel.bak is NOT excluded (reported as undeclared)");
    like($msgs[0], qr/patchlevel\.bak/,
         "procedural: patchlevel.bak appears in the log");
}

# ---- Test::Smoke::App::RunSmoke::do_manifest_check (OO) ----

sub make_runsmoke_app {
    my ($ddir, %extra) = @_;
    my @argv = (
        '--ddir', $ddir,
        '--verbose', $extra{verbose} // 0,
    );
    local @ARGV = @argv;
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    return $app;
}

{
    my $ddir = catdir($tmpdir, 'oo_clean');
    mkpath($ddir);
    write_file(catfile($ddir, 'lib.pm'));
    write_manifest($ddir, 'MANIFEST', 'lib.pm');

    my $app = make_runsmoke_app($ddir);
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    is_deeply([$smoker->messages], [], "OO: clean tree produces no log messages");
}

{
    my $ddir = catdir($tmpdir, 'oo_missing');
    mkpath($ddir);
    write_file(catfile($ddir, 'exists.pm'));
    write_manifest($ddir, 'MANIFEST', 'exists.pm', 'gone.pm');

    my $app = make_runsmoke_app($ddir);
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1, "OO: one missing file logged");
    like($msgs[0], qr/MANIFEST declared 'gone\.pm' but it is missing/,
         "OO: correct missing-file message");
}

{
    my $ddir = catdir($tmpdir, 'oo_undeclared');
    mkpath($ddir);
    write_file(catfile($ddir, 'declared.pm'));
    write_file(catfile($ddir, 'extra.pm'));
    write_manifest($ddir, 'MANIFEST', 'declared.pm');

    my $app = make_runsmoke_app($ddir);
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1, "OO: one undeclared file logged");
    like($msgs[0], qr/MANIFEST did not declare 'extra\.pm'/,
         "OO: correct undeclared-file message");
}

{
    my $ddir = catdir($tmpdir, 'oo_both');
    mkpath($ddir);
    write_file(catfile($ddir, 'present.pm'));
    write_file(catfile($ddir, 'bonus.pm'));
    write_manifest($ddir, 'MANIFEST', 'present.pm', 'absent.pm');

    my $app = make_runsmoke_app($ddir);
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 2, "OO: missing + undeclared both logged");
}

# The OO version excludes outfile, rptfile, AND patchlevel.bak
{
    my $ddir = catdir($tmpdir, 'oo_exclude');
    mkpath($ddir);
    write_file(catfile($ddir, 'code.pm'));
    write_file(catfile($ddir, 'mktest.out'));
    write_file(catfile($ddir, 'mktest.rpt'));
    write_file(catfile($ddir, 'patchlevel.bak'));
    write_manifest($ddir, 'MANIFEST', 'code.pm');

    my $app = make_runsmoke_app($ddir);
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 0,
       "OO: outfile, rptfile, AND patchlevel.bak all excluded");
}

# Verify the OO version uses options for outfile/rptfile (not hardcoded)
{
    my $ddir = catdir($tmpdir, 'oo_custom_names');
    mkpath($ddir);
    write_file(catfile($ddir, 'code.pm'));
    write_file(catfile($ddir, 'custom.out'));
    write_file(catfile($ddir, 'custom.rpt'));
    write_manifest($ddir, 'MANIFEST', 'code.pm');

    local @ARGV = (
        '--ddir', $ddir,
        '--outfile', 'custom.out',
        '--rptfile', 'custom.rpt',
        '--verbose', 0,
    );
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 0,
       "OO: custom outfile/rptfile names are excluded");
}

# When custom names are used, the default names ARE reported as undeclared
{
    my $ddir = catdir($tmpdir, 'oo_default_visible');
    mkpath($ddir);
    write_file(catfile($ddir, 'code.pm'));
    write_file(catfile($ddir, 'mktest.out'));
    write_manifest($ddir, 'MANIFEST', 'code.pm');

    local @ARGV = (
        '--ddir', $ddir,
        '--outfile', 'other.out',
        '--rptfile', 'other.rpt',
        '--verbose', 0,
    );
    my $app = Test::Smoke::App::RunSmoke->new(
        Test::Smoke::App::Options->runsmoke_config()
    );
    my $smoker = MockSmoker->new;
    $app->{_smoker} = $smoker;
    $app->do_manifest_check();
    my @msgs = $smoker->messages;
    is(scalar @msgs, 1,
       "OO: mktest.out is undeclared when outfile is configured differently");
    like($msgs[0], qr/mktest\.out/,
         "OO: mktest.out reported when not the configured outfile");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
