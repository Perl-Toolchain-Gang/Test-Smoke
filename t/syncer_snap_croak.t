#! /usr/bin/perl -w
use strict;

use Test::More;
use File::Temp qw( tempdir );
use File::Spec;

use_ok('Test::Smoke::Syncer::Snapshot');

# __get_directory_names is a plain sub (not a method), called with a dir arg.
# We can call it directly via its full name.

subtest '__get_directory_names croaks on unreadable directory' => sub {
    my $nonexistent = File::Spec->catdir(tempdir(CLEANUP => 1), 'no_such_dir');
    eval {
        Test::Smoke::Syncer::Snapshot::__get_directory_names($nonexistent);
    };
    like($@, qr/Can't opendir '\Q$nonexistent\E'/, 'croaks with opendir error');
    like($@, qr/\Q: \E/, 'includes errno in message');
};

subtest '__get_directory_names succeeds on valid directory' => sub {
    my $dir = tempdir(CLEANUP => 1);
    # Create a subdirectory so there's something to find
    mkdir File::Spec->catdir($dir, 'subdir');

    my @dirs = Test::Smoke::Syncer::Snapshot::__get_directory_names($dir);
    ok(scalar @dirs > 0, 'returns directory entries');
    ok(grep({ $_ eq 'subdir' } @dirs), 'finds the created subdirectory');
};

done_testing();
