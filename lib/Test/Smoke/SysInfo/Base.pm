package Test::Smoke::SysInfo::Base;
use warnings;
use strict;

use POSIX ();

=head1 NAME

Test::Smoke::SysInfo::Base - Baseclass for system information.

=head1 ATTRIBUTES

=head2 cpu

=head2 cpu_type

=head2 ncpu

=head2 os

=head2 host

=head1 DESCRIPTION

=head2 Test::Smoke::SysInfo::Base->new()

Return a new instance for $^O

=cut

sub new {
    my $class = shift;

    my $self = bless {}, $class;
    $self->prepare_sysinfo();

    $self->{_host}     = $self->get_hostname();
    $self->{_os}       = $self->get_os();
    $self->{_cpu_type} = $self->get_cpu_type();
    $self->{_cpu}      = $self->get_cpu();
    $self->{_ncpu}     = $self->get_cpu_count();

    return $self;
}

=head2 $si->prepare_sysinfo()

This method should be overridden by platform specific subclasses.

The generic information is taken from C<< POSIX::uname() >>.

=over

=item $self->_hostname  => (POSIX::uname)[1]

=item $self->_os        => join(" - ", (POSIX::uname)[0,2]

=item $self->_osname    => (POSIX::uname)[0]

=item $self->_osvers    => (POSIX::uname)[2]

=item $self->_cpu_type  => (POSIX::uname)[4]

=item $self->_cpu       => (POSIX::uname)[4]

=itum $self->_cpu_count => ''

=back

=cut

sub prepare_sysinfo {
    my $self = shift;
    my @uname = POSIX::uname();

    $self->{__hostname} = $uname[1];

    $self->{__osname} = $uname[0];
    $self->{__osvers} = $uname[2];
    my $os = join " - ", @uname[0,2];
    $os =~ s/(\S+)/\L$1/;
    $self->{__os} = $os;

    $self->{__cpu_type}  = $uname[4];
    $self->{__cpu}       = $uname[4];
    $self->{__cpu_count} = '';

    return $self;
}

=head2 $si->get_os()

Returns $self->_os

=cut

sub get_os {
    my $self = shift;
    return $self->_os();
}

=head2 $si->get_hostname()

Returns $self->_hostname

=cut

sub get_hostname {
    my $self = shift;
    return $self->_hostname();
}

=head2 $si->get_cpu_type()

Returns $self->_cpu_type

=cut

sub get_cpu_type {
    my $self = shift;
    return $self->_cpu_type();
}

=head2 $si->get_cpu()

Returns $self->_cpu

=cut

sub get_cpu {
    my $self = shift;
    return $self->_cpu();
}

=head2 $si->get_cpu_count()

Returns $self->_cpu_count

=cut

sub get_cpu_count {
    my $self = shift;
    return $self->_cpu_count();
}

=head2 tsuname( @args )

This class gathers most of the C<uname(1)> info, make a comparable
version. Takes almost the same arguments:

    a for all (can be omitted)
    n for nodename
    s for os name and version
    m for cpu name
    c for cpu count
    p for cpu_type

=cut

sub tsuname {
    my $self = shift;
    my @args = map split() => @_;

    my @sw = qw( n s m c p );
    my %sw = ( n => 'host', s => 'os',
               m => 'cpu', c => 'ncpu', p => 'cpu_type' );

    @args = grep exists $sw{ $_ } => @args;
    @args or @args = ( 'a' );
    grep( /a/ => @args ) and @args = @sw;

    # filter supported args but keep order of @sw!
    my %show = map +( $_ => undef ) => grep exists $sw{ $_ } => @args;
    @args = grep exists $show{ $_ } => @sw;

    return join " ", map { my $m = $sw{$_}; $self->$m } @args;
}

sub old_dump {
    my $self = shift;
    return {
        _cpu      => $self->cpu,
        _cpu_type => $self->cpu_type,
        _ncpu     => $self->ncpu,
        _os       => $self->os,
        _host     => $self->host,
    };
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;

    (my $attrib = our $AUTOLOAD) =~ s/.*:://;
    if (exists $self->{"_$attrib"}) {
        if (ref $self->{"_$attrib"} eq 'ARRAY') {
            return @{ $self->{"_$attrib"} };
        }
        return $self->{"_$attrib"};
    }
}

1;

=head1 COPYRIGHT

(c) 2002-2013, Abe Timmerman <abeltje@cpan.org> All rights reserved.

With contributions from Jarkko Hietaniemi, Merijn Brand, Campo
Weijerman, Alan Burlison, Allen Smith, Alain Barbet, Dominic Dunlop,
Rich Rauenzahn, David Cantrell.

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
