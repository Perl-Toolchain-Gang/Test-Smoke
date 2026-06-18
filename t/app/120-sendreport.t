#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Test::Smoke::App::SendReport;
use Test::Smoke::App::Options;
use Test::Smoke::Util::FindHelpers 'get_avail_posters';

my $opt = 'Test::Smoke::App::Options';

{
    my $poster = (get_avail_posters())[0];
    note("using poster: $poster");

    no warnings 'redefine';
    local *Test::Smoke::Poster::Base::post = sub {
        return 42;
    };
    local *Test::Smoke::App::SendReport::check_for_report_and_json = sub {
        return 1;
    };
    local @ARGV = (
        '--ddir'    => 't/perl',
        '--poster'  => $poster,
        '--verbose' => 2,
        '--nomail',
    );
    my $app = Test::Smoke::App::SendReport->new(
        Test::Smoke::App::Options::sendreport_config(),
    );
    isa_ok($app, 'Test::Smoke::App::SendReport');

    my $report_id = eval { $app->run };
    diag("Error: $@") if $@;
    is($report_id, 42, "->run() returns a report_id");
}

{
    no warnings 'redefine';
    local *Test::Smoke::Mailer::Sendmail::mail = sub {
        my $self = shift;
        $self->{error} = "SMTP connection refused";
        return 0;
    };
    local *Test::Smoke::App::SendReport::check_for_report_and_json = sub {
        return 1;
    };
    local @ARGV = (
        '--ddir'      => 't/perl',
        '--mail_type' => 'sendmail',
        '--to'        => 'test@example.com',
        '--mail'      => '1',
        '--verbose'   => 0,
        '--nosmokedb_url',
    );
    my $app = Test::Smoke::App::SendReport->new(
        Test::Smoke::App::Options::sendreport_config(),
    );
    isa_ok($app, 'Test::Smoke::App::SendReport');

    my $output = '';
    open my $fh, '>', \$output;
    my $old = select($fh);
    eval { $app->run };
    select($old);
    close $fh;

    like($output, qr/Mailer error:.*SMTP connection refused/,
        "mail() failure is reported to the user");
}

{
    no warnings 'redefine';
    local *Test::Smoke::Mailer::Sendmail::mail = sub { return 1 };
    local *Test::Smoke::App::SendReport::check_for_report_and_json = sub {
        return 1;
    };
    local @ARGV = (
        '--ddir'      => 't/perl',
        '--mail_type' => 'sendmail',
        '--to'        => 'test@example.com',
        '--mail'      => '1',
        '--verbose'   => 0,
        '--nosmokedb_url',
    );
    my $app = Test::Smoke::App::SendReport->new(
        Test::Smoke::App::Options::sendreport_config(),
    );

    my $output = '';
    open my $fh, '>', \$output;
    my $old = select($fh);
    eval { $app->run };
    select($old);
    close $fh;

    unlike($output, qr/Mailer error:/,
        "successful mail() produces no error message");
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
