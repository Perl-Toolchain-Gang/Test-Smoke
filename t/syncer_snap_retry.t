#! /usr/bin/perl -w
use strict;

use Test::More tests => 13;
use File::Temp qw( tempdir );
use File::Path qw( mkpath );
use File::Spec;

use_ok('Test::Smoke::Syncer::Snapshot');

# Helpers to mock LWP::Simple functions
my @mirror_results;
my @mirror_calls;
{
    no warnings 'redefine';

    # Pre-load LWP::Simple so we can override its functions
    require LWP::Simple;

    *LWP::Simple::mirror = sub ($$) {
        push @mirror_calls, [@_];
        return shift @mirror_results;
    };
}

sub reset_mock {
    @mirror_results = ();
    @mirror_calls   = ();
}

sub make_syncer {
    my (%extra) = @_;
    my $ddir = tempdir( CLEANUP => 1 );
    mkpath($ddir);

    return Test::Smoke::Syncer::Snapshot->new(
        ddir            => $ddir,
        snapurl         => 'http://example.com/perl-current.tar.gz',
        v               => 0,
        snap_retry_delay => 0,   # no actual sleep in tests
        %extra,
    );
}

# Test 1: Success on first attempt — no retry
{
    reset_mock();
    @mirror_results = (200);

    my $syncer  = make_syncer();
    my $archive = $syncer->_fetch_archive;

    ok( defined $archive, "Success on first attempt returns archive path" );
    is( scalar @mirror_calls, 1, "Only one mirror call on success" );
}

# Test 2: Permanent 4xx error — no retry
{
    reset_mock();
    @mirror_results = (404);

    my $syncer  = make_syncer();
    my $archive = $syncer->_fetch_archive;

    ok( !defined $archive, "404 returns undef (permanent error)" );
    is( scalar @mirror_calls, 1, "No retry on 4xx error" );
}

# Test 3: Transient 500 then success — retries and succeeds
{
    reset_mock();
    @mirror_results = (500, 200);

    my $syncer  = make_syncer();
    my $archive = $syncer->_fetch_archive;

    ok( defined $archive, "Succeeds after transient 500" );
    is( scalar @mirror_calls, 2, "Two attempts: one failure + one success" );
}

# Test 4: All 3 attempts fail with 503 — gives up
{
    reset_mock();
    @mirror_results = (503, 502, 500);

    my $syncer  = make_syncer( snap_retries => 3 );
    my $archive = $syncer->_fetch_archive;

    ok( !defined $archive, "Returns undef after exhausting retries" );
    is( scalar @mirror_calls, 3, "Three attempts made before giving up" );
}

# Test 5: 304 Not Modified (not success, not error) — returns immediately
{
    reset_mock();
    @mirror_results = (304);

    my $syncer  = make_syncer();
    my $archive = $syncer->_fetch_archive;

    ok( defined $archive, "304 returns archive path (not modified)" );
    is( scalar @mirror_calls, 1, "No retry on 304" );
}

# Test 6: Custom retry count respected
{
    reset_mock();
    @mirror_results = (500, 500);

    my $syncer  = make_syncer( snap_retries => 2 );
    my $archive = $syncer->_fetch_archive;

    ok( !defined $archive, "Gives up after custom retry count" );
    is( scalar @mirror_calls, 2, "Respects snap_retries=2" );
}
