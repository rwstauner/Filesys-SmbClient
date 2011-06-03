package Filesys::SmbClient::DirHandle;

use IO::Dir;
use Carp;
use strict;

use Filesys::SmbClient qw(:raw);

our (@ISA);

use Exporter;

@ISA = qw(IO::Dir);

sub new($$$) {
  my ($type, $smb, $fd) = @_;
  my $class = ref($type) || $type;

  my $dh = $class->SUPER::new();

  ${*$dh}{smb} = $smb;
  ${*$dh}{fd} = $fd;

  bless $dh, $class;

  return $dh;
}

sub open($$) {
  croak 'open not supported';
}

sub read($) {
  my ($dh) = @_;

  if (wantarray()) {
    my @list = ();

    while (1) {
      my @args = _readdir(${*$dh}{smb}, ${*$dh}{fd});

      last if (@args == 0);

      push(@list, $args[1]);
    }
    return @list;
  }

  my @args = _readdir(${*$dh}{smb}, ${*$dh}{fd});

  return (@args == 0) ? undef : $args[1];
}

sub seek($$) {
  my ($dh, $pos) = @_;

  my $ret = _lseekdir(${*$dh}{smb}, ${*$dh}{fd}, $pos);

  return ($ret == -1) ? 0 : 1;
}

sub tell($) {
  my ($dh) = @_;

  my $ret = _telldir(${*$dh}{smb}, ${*$dh}{fd});

  return ($ret == -1) ? undef : $ret;
}

sub rewind($) {
  my ($dh) = @_;

  $dh->seek(0);
}

sub close($) {
  my ($dh) = @_;

  my $ret = _closedir(${*$dh}{smb}, ${*$dh}{fd});

  ${*$dh}{fd} = undef;

  return ($ret < 0) ? 0 : 1;
}

sub DESTROY($) {
  my ($dh) = @_;

  $dh->close() if (defined ${*$dh}{fd});
}

1;

__END__

=pod

=head1 NAME

Filesys::SmbClient::DirHandle - Interface for accessing samba filesystem with libsmbclient.so

=head1 SYNOPSIS

 use Filesys::SmbClient;

 my $smb = Filesys::SmbClient->new(username => "guest",
                                   share => "test",
                                   workgroup => "mygroup");

 my $dh = $smb->opendir("perl/t");

 while (my $name = $dh->read()) {
     ...
 }

 $dh->close();

=head1 DESCRIPTION

This class provides access to the libsmbclient.so API using C<IO::Dir> methods.
Since opening is done via the $smb handle itself, there is no C<open> method.

Standard methods that are implemented are:

=over 4

=item * read

=item * seek

=item * tell

=item * rewind

=item * close

=back

=head1 SEE ALSO

Consult the L<IO::Dir> documention for the specifics of the class methods.

=head1 COPYRIGHT

The C<Filesys::SmbClient::DirHandle> module is Copyright (C) 2010
Philip Prindeville, Redfish Solutions.  philipp at cpan.org.  All
rights reserved.

You may distribute uder the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=cut

