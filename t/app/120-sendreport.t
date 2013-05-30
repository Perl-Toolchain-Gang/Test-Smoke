#! perl -w
use strict;

use Test::More 'no_plan';

use Test::Smoke::App::SendReport;
use Test::Smoke::App::Options;
my $opt = 'Test::Smoke::App::Options';

{
    local @ARGV = ('--ddir', 't/perl');
    my $app = Test::Smoke::App::SendReport->new(
        main_options    => [$opt->poster()],
        general_options => [$opt->mail(), $opt->ddir()],
        special_otpions => {
            curl => [$opt->curlbin()],
        },
    );
    isa_ok($app, 'Test::Smoke::App::SendReport');
}

# done_testing();

