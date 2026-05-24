package Test::Smoke;
use strict;

use vars qw($conf);
our $VERSION  = "1.87";

use base 'Exporter';
our @EXPORT  = qw( $conf &read_config );

my $ConfigError;

use File::Spec;
use Test::Smoke::BuildCFG;
use Test::Smoke::SourceTree qw( :mani_const );
use Test::Smoke::Util qw( skip_config
                          get_local_patches set_local_patch );

=head1 NAME

Test::Smoke - The Perl core test smoke suite

=head1 SYNOPSIS

    use Test::Smoke;

    use vars qw( $VERSION );
    $VERSION = Test::Smoke->VERSION;

    read_config( $config_name ) or warn Test::Smoke->config_error;


=head1 DESCRIPTION

If you are looking to get started, start at the B<README>!

C<Test::Smoke> exports C<$conf> and C<read_config()> by default.

B<Note:> The C<run_smoke()> function that was previously exported from this
module has been removed. It was superseded by
L<Test::Smoke::App::RunSmoke>, which provides the same functionality through
an OO interface. See L<Test::Smoke::App::RunSmoke/run()>.

=head2 Test::Smoke::read_config( $config_name )

Read (require) the configfile.

Takes one optional argument: a string holding the name of the configuration
file.  Defaults to C<smokecurrent_config>.

If there is an error in reading the configuration file, C<read_config()>
returns an undefined value; the content of the error can be found by calling
C<config_error()>.  If there is no such error, C<read_config()> returns a true
value.

=cut

sub read_config {
    my( $config_name ) = @_;

    $config_name = 'smokecurrent_config'
        unless defined $config_name && length $config_name;
    $config_name .= '_config'
        unless $config_name =~ /_config$/ || -f $config_name;

    # Enable reloading by hackery
    local @INC = ( File::Spec->curdir, @INC );
    delete $INC{ $config_name } if exists $INC{ $config_name };
    eval { require $config_name };
    $ConfigError = $@ ? $@ : undef;

    return defined $ConfigError ? undef : 1;
}

=head2 Test::Smoke->config_error()

Return the value of C<$ConfigError>.

=cut

sub config_error {
    return $ConfigError;
}

=head2 is_win32( )

C<is_win32()> returns true if  C<< $^O eq "MSWin32" >>.

=cut

sub is_win32() { $^O eq "MSWin32" }

=head2 do_manifest_check( $ddir, $smoker )

C<do_manifest_check()> uses B<Test::Smoke::SourceTree> to do the
MANIFEST check.

=cut

sub do_manifest_check {
    my( $ddir, $smoker ) = @_;

    my $tree = Test::Smoke::SourceTree->new( $ddir );
    my $mani_check = $tree->check_MANIFEST( 'mktest.out', 'mktest.rpt' );
    foreach my $file ( sort keys %$mani_check ) {
        if ( $mani_check->{ $file } == ST_MISSING ) {
            $smoker->log( "MANIFEST declared '$file' but it is missing\n" );
        } elsif ( $mani_check->{ $file } == ST_UNDECLARED ) {
            $smoker->log( "MANIFEST did not declare '$file'\n" );
        }
    }
}

=head2 set_smoke_patchlevel( $ddir, $patch[, $verbose] )

Set the current patchlevel as a registered patch like "SMOKE$patch"

=cut

sub set_smoke_patchlevel {
    my( $ddir, $patch, $verbose ) = @_;
    $ddir && $patch or return;

    my @smokereg = grep
        /^SMOKE[a-fA-F0-9]+$/
    , get_local_patches( $ddir, $verbose );
    @smokereg or set_local_patch( $ddir, "SMOKE$patch" );
}

1;

=head1 COPYRIGHT

(c) 2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
