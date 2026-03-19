#! perl -w
use strict;
$|++;

use Test::More;
use Test::NoWarnings ();

use Test::Smoke::App::AppOption;
use Test::Smoke::App::ConfigSmoke;

# Minimal stub to exercise ConfigSmoke->prompt() without the full app setup
{
    package MockConfigSmoke;
    use parent -norequire, 'Test::Smoke::App::ConfigSmoke';

    sub new {
        my $class = shift;
        return bless {
            _usedft          => 0,
            _current_values  => {},
            _from_configfile => {},
            _options         => {},
        }, $class;
    }

    # Satisfy default_for_option()
    sub options         { %{ $_[0]->{_options} } }
    sub from_configfile { $_[0]->{_from_configfile} }
    sub usedft          { $_[0]->{_usedft} }
}

# Helper: run prompt() with a given option and simulated STDIN input
sub run_prompt {
    my ($opt, $stdin_input) = @_;

    my $cs = MockConfigSmoke->new();

    # Capture stdout
    my $stdout = '';
    local *STDOUT;
    open(STDOUT, '>', \$stdout) or die "Cannot redirect STDOUT: $!";

    # Provide STDIN
    local *STDIN;
    open(STDIN, '<', \$stdin_input) or die "Cannot redirect STDIN: $!";

    my $retval = $cs->prompt($opt);

    close STDOUT;
    close STDIN;

    return ($retval, $stdout);
}

# --- Test 1: curlargs with empty array default, user presses Enter ---
# Before the fix, this would display "[ARRAY(0x...)] $" and return an array ref
# as a stringified value. After the fix it should display "[] $" and return [].
{
    my $opt = Test::Smoke::App::AppOption->new(
        name       => 'curlargs',
        option     => '=s@',
        default    => [],
        helptext   => 'Extra switches to pass to curl (repeatable!)',
        configtext => 'Extra switches to pass to curl?',
    );

    my ($retval, $stdout) = run_prompt($opt, "\n");

    # The displayed default must NOT contain 'ARRAY('
    unlike(
        $stdout,
        qr/ARRAY\(/,
        'curlargs: default display does not show raw array ref'
    );

    # User accepted empty default: should return an array ref
    is(ref($retval), 'ARRAY', 'curlargs: returns array ref when default accepted');
    is_deeply($retval, [], 'curlargs: returns empty array ref for empty default');
}

# --- Test 2: curlargs with non-empty array default, user presses Enter ---
{
    my $opt = Test::Smoke::App::AppOption->new(
        name       => 'curlargs',
        option     => '=s@',
        default    => ['--globoff', '--silent'],
        helptext   => 'Extra switches to pass to curl (repeatable!)',
        configtext => 'Extra switches to pass to curl?',
    );

    my ($retval, $stdout) = run_prompt($opt, "\n");

    unlike(
        $stdout,
        qr/ARRAY\(/,
        'curlargs: non-empty array default display does not show raw array ref'
    );

    like(
        $stdout,
        qr/--globoff --silent/,
        'curlargs: non-empty array default displayed as space-joined string'
    );

    is(ref($retval), 'ARRAY', 'curlargs: returns array ref when non-empty default accepted');
    is_deeply(
        $retval,
        ['--globoff', '--silent'],
        'curlargs: returns correct array ref for non-empty default'
    );
}

# --- Test 3: curlargs, user enters new value ---
{
    my $opt = Test::Smoke::App::AppOption->new(
        name       => 'curlargs',
        option     => '=s@',
        default    => [],
        helptext   => 'Extra switches to pass to curl (repeatable!)',
        configtext => 'Extra switches to pass to curl?',
    );

    my ($retval, $stdout) = run_prompt($opt, "--foo --bar\n");

    is(ref($retval), 'ARRAY', 'curlargs: user input returns array ref');
    is_deeply(
        $retval,
        ['--foo', '--bar'],
        'curlargs: user input split into array ref'
    );
}

# --- Test 4: scalar option still works correctly ---
{
    my $opt = Test::Smoke::App::AppOption->new(
        name       => 'curlbin',
        option     => '=s',
        default    => 'curl',
        helptext   => 'The fqp for the curl program.',
        configtext => "Which 'curl' binary do you want to use?",
    );

    my ($retval, $stdout) = run_prompt($opt, "\n");

    is($retval, 'curl', 'curlbin: scalar default still works correctly');
    unlike($stdout, qr/ARRAY\(/, 'curlbin: no array ref stringification');
}

done_testing();
