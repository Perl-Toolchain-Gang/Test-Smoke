#! perl -w
use strict;
$| = 1;

use File::Spec::Functions;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;

my $verbose = exists $ENV{SMOKE_VERBOSE} ? $ENV{SMOKE_VERBOSE} : 0;

use Test::More;

use_ok 'Test::Smoke::Reporter';

my $config_sh = catfile( $findbin, 'config.sh' );

sub create_config_sh {
    my ($file, %cfg) = @_;

    my $cfg_sh = "# This is a testfile config.sh\n";
    $cfg_sh .= "# created by $0\n";

    $cfg_sh .= join "", map "$_='$cfg{$_}'\n" => keys %cfg;

    put_file($cfg_sh, $file);
}

sub get_passed_from_configs {
    my ($configs) = @_;
    my @found;
    for my $cfg (@$configs) {
        for my $result (@{$cfg->{results}}) {
            for my $f (@{$result->{failures}}) {
                next unless $f->{status} eq "PASSED";
                push @found, {
                    arguments => $cfg->{arguments},
                    debugging => $cfg->{debugging},
                    io_env    => $result->{io_env},
                    test      => $f->{test},
                    extra     => $f->{extra},
                };
            }
        }
    }
    return @found;
}

{
    note("GH#68 — multi-config todo-passed with different test numbers");

    create_config_sh( $config_sh, version => '5.41.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
    );
    isa_ok( $reporter, 'Test::Smoke::Reporter' );

    $reporter->read_parse( \(my $result = <<'EORESULTS') );
Started smoke at 1750000000
Smoking patch abc123def456 v5.41.2-100-gabc123d

Stopped smoke at 1750000001
Started smoke at 1750000001

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    20
Stopped smoke at 1750000100
Started smoke at 1750000100

Configuration: -Dusedevel -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    20
Stopped smoke at 1750000200
Started smoke at 1750000200

Configuration: -Dusedevel -Duse64bitall
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
Stopped smoke at 1750000300
Started smoke at 1750000300

Configuration: -Dusedevel -Duse64bitall -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    20
Stopped smoke at 1750000400
Started smoke at 1750000400

Configuration: -Dusedevel -Duselongdouble
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    6, 28-29
Stopped smoke at 1750000500
Started smoke at 1750000500

Configuration: -Dusedevel -Duselongdouble -DDEBUGGING
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    6, 20, 28-29

Finished smoking abc123def456 v5.41.2-100-gabc123d
Stopped smoke at 1750000600
EORESULTS

    my @passed = get_passed_from_configs($reporter->{configs});

    is(scalar @passed, 5, "5 configs with todo-passed tests");

    is_deeply($passed[0], {
        arguments => '',
        debugging => 'N',
        io_env    => 'stdio',
        test      => '../t/run/todo.t',
        extra     => ['20'],
    }, "default config: extra=[20]");

    is_deeply($passed[1], {
        arguments => '',
        debugging => 'D',
        io_env    => 'stdio',
        test      => '../t/run/todo.t',
        extra     => ['20'],
    }, "DEBUGGING config: extra=[20]");

    is_deeply($passed[2], {
        arguments => '-Duse64bitall',
        debugging => 'D',
        io_env    => 'stdio',
        test      => '../t/run/todo.t',
        extra     => ['20'],
    }, "64bitall DEBUGGING config: extra=[20]");

    is_deeply($passed[3], {
        arguments => '-Duselongdouble',
        debugging => 'N',
        io_env    => 'stdio',
        test      => '../t/run/todo.t',
        extra     => ['6', '28-29'],
    }, "longdouble config: extra=[6, 28-29] (range preserved)");

    is_deeply($passed[4], {
        arguments => '-Duselongdouble',
        debugging => 'D',
        io_env    => 'stdio',
        test      => '../t/run/todo.t',
        extra     => ['6', '20', '28-29'],
    }, "longdouble DEBUGGING config: extra=[6, 20, 28-29] (all captured)");

    my $todo = $reporter->todo_passed;
    like($todo, qr/\[stdio\]\s*\n\[stdio\] -DDEBUGGING\n\[stdio\] -DDEBUGGING -Duse64bitall/,
        "Mail report groups configs with same pattern (test 20)");
    like($todo, qr/\[stdio\] -Duselongdouble\n.*PASSED\n\s+6, 28-29/s,
        "Mail report shows longdouble pattern (6, 28-29)");
    like($todo, qr/\[stdio\] -DDEBUGGING -Duselongdouble\n.*PASSED\n\s+6, 20, 28-29/s,
        "Mail report shows longdouble+debug pattern (6, 20, 28-29)");
}

{
    note("Multi-line continuation of todo-passed test numbers");

    create_config_sh( $config_sh, version => '5.41.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
    );

    $reporter->read_parse( \(my $result = <<'EORESULTS') );
Started smoke at 1750000000
Smoking patch abc123 v5.41.2-1-gabc123

Stopped smoke at 1750000001
Started smoke at 1750000001

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20
    22, 24, 26

Finished smoking abc123 v5.41.2-1-gabc123
Stopped smoke at 1750000100
EORESULTS

    my @passed = get_passed_from_configs($reporter->{configs});

    is(scalar @passed, 1, "one config with todo-passed");
    is_deeply($passed[0]->{extra},
        ['2', '4', '6', '8', '10', '12', '14', '16', '18', '20',
         '22', '24', '26'],
        "multi-line continuation captures all test numbers");
}

{
    note("Todo-passed with range-style test numbers");

    create_config_sh( $config_sh, version => '5.41.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
    );

    $reporter->read_parse( \(my $result = <<'EORESULTS') );
Started smoke at 1750000000
Smoking patch abc123 v5.41.2-1-gabc123

Stopped smoke at 1750000001
Started smoke at 1750000001

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    1-5, 10, 20-25

Finished smoking abc123 v5.41.2-1-gabc123
Stopped smoke at 1750000100
EORESULTS

    my @passed = get_passed_from_configs($reporter->{configs});
    is_deeply($passed[0]->{extra}, ['1-5', '10', '20-25'],
        "range-style test numbers preserved in extra");
}

{
    note("Todo-passed across multiple test environments");

    create_config_sh( $config_sh, version => '5.41.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
    );

    $reporter->read_parse( \(my $result = <<'EORESULTS') );
Started smoke at 1750000000
Smoking patch abc123 v5.41.2-1-gabc123

Stopped smoke at 1750000001
Started smoke at 1750000001

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio
All tests successful.
../t/run/todo.t.............................................PASSED
    6

PERLIO = perlio
All tests successful.
../t/run/todo.t.............................................PASSED
    6, 20

Finished smoking abc123 v5.41.2-1-gabc123
Stopped smoke at 1750000100
EORESULTS

    my @passed = get_passed_from_configs($reporter->{configs});

    is(scalar @passed, 2, "two results with todo-passed");

    is($passed[0]->{io_env}, 'stdio', "first is stdio");
    is_deeply($passed[0]->{extra}, ['6'], "stdio: extra=[6]");

    is($passed[1]->{io_env}, 'perlio', "second is perlio");
    is_deeply($passed[1]->{extra}, ['6', '20'], "perlio: extra=[6, 20]");

    my $todo = $reporter->todo_passed;
    like($todo, qr/\[stdio\]\s*\n.*PASSED\n\s+6\n/s,
        "Mail report shows stdio pattern (6 only)");
    like($todo, qr/\[perlio\]\s*\n.*PASSED\n\s+6, 20\n/s,
        "Mail report shows perlio pattern (6, 20)");
}

{
    note("Regex grouping: failure extra info requires leading whitespace");

    create_config_sh( $config_sh, version => '5.41.2' );

    my $reporter = Test::Smoke::Reporter->new(
        ddir       => $findbin,
        v          => $verbose,
        outfile    => '',
    );

    $reporter->read_parse( \(my $result = <<'EORESULTS') );
Started smoke at 1750000000
Smoking patch abc123 v5.41.2-1-gabc123

Stopped smoke at 1750000001
Started smoke at 1750000001

Configuration: -Dusedevel
------------------------------------------------------------------------------
PERLIO = stdio
    ../t/op/test1.t.............................................FAILED
        Non-zero exit status: 2
    ../t/op/test2.t.............................................FAILED
        Bad plan.  You planned 5 tests but ran 2.
    ../t/op/test3.t.............................................FAILED
        No plan found in TAP output

Finished smoking abc123 v5.41.2-1-gabc123
Stopped smoke at 1750000100
EORESULTS

    my $cfg = $reporter->{configs}[0];
    my @failures = @{$cfg->{results}[0]{failures}};
    is(scalar @failures, 3, "three test failures");

    is($failures[0]{test}, '../t/op/test1.t', "test1 parsed");
    is_deeply($failures[0]{extra}, ['Non-zero exit status: 2'],
        "Non-zero exit status captured as extra");

    is($failures[1]{test}, '../t/op/test2.t', "test2 parsed");
    is_deeply($failures[1]{extra}, ['Bad plan.  You planned 5 tests but ran 2.'],
        "Bad plan captured as extra");

    is($failures[2]{test}, '../t/op/test3.t', "test3 parsed");
    is_deeply($failures[2]{extra}, ['No plan found in TAP output'],
        "No plan found captured as extra");
}

unlink $config_sh;

done_testing();
