package Filesys::SmbClient::FileHandle;

use IO::Handle;
use IO::Scalar;
use Carp;
use strict;

use Filesys::SmbClient qw(:raw);

use POSIX qw(SEEK_SET SEEK_CUR SEEK_END);

our (@ISA);

use Exporter;

@ISA = qw(IO::Handle);

sub new ($$$) {
  my ($type, $smb, $fd) = @_;
  my $class = ref($type) || $type;

  my $fh = $class->SUPER::new();

  $fh->autoflush(1);

  ${*$fh}{smb} = $smb;
  ${*$fh}{fd} = $fd;
  ${*$fh}{error} = 0;
  ${*$fh}{eof} = 0;

  bless $fh, $class;

  return $fh;
}

sub close ($) {
  my ($fh) = @_;

  my $ret = _close(${*$fh}{smb}, ${*$fh}{fd});

  ${*$fh}{fd} = undef;
  ${*$fh}{smb} = undef;

  if ($ret != 0) {
    ${*$fh}{error} = $! + 0;
    return 0;
  }

  return 1;
}

sub eof($) {
  my ($fh) = @_;

  return ${*$fh}{eof};
}

sub fcntl($$$) {
  croak 'fcntl not supported';
}

sub fileno($) {
  croak 'fileno not supported';
}

sub format_write($) {
  my ($fh) = @_;

  my $buf = '';
  my $SH = new IO::Scalar \$buf;

  $SH->write;		# not documented what it returns

  my $ret = $fh->write($buf, length($buf));

  if (! defined $ret) {
    ${*$fh}{error} = $! + 0;
    return 0;
  }

  return 1;
}

sub getc($) {
  croak 'getc not supported';
}

sub ioctl($$$) {
  croak 'ioctl not supported';
}

sub read($$$;$) {
  my ($fh, undef, $len) = @_;
  my $off = (@_ == 4) ? $_[3] : 0;

  my $cnt = _read(${*$fh}{smb}, ${*$fh}{fd}, $_[1], $len, $off);

  if ($cnt < 0) {
    ${*$fh}{error} = $! + 0;
    return undef;
  } elsif ($cnt == 0) {
    ${*$fh}{eof} = 1;
  }

  return $cnt;
}

sub print($@) {
  my ($fh, @args) = @_;

  my $buf = '';
  my $SH = new IO::Scalar \$buf;

  $SH->print(@args);		# always returns 1

  my $ret = $fh->write($buf, length($buf));

  return (defined $ret);
}

sub printf($$@) {
  my ($fh, $fmt, @args) = @_;

  my $buf = sprintf $fmt, @args;

  return undef unless (defined $buf);
  return 1 if ($buf eq '');

  my $ret = $fh->write($buf, length($buf));

  return (defined $ret);
}

sub say($@) {
  local $\ = "\n";

  return print(@_);
}

sub stat($) {
  my ($fh) = @_;

  my @ret = _fstat(${*$fh}{smb}, ${*$fh}{fd});

  if (@_ == 0) {
    ${*$fh}{error} = $! + 0;
    return ();
  }
  return @ret;
}

sub sysread($\$$;$) {
  croak 'sysread not supported';
}

sub syswrite($$$;$) {
  croak 'syswrite not supported';
}

sub truncate($$) {
  my ($fh, $len) = @_;

  my $ret = _ftruncate(${*$fh}{smb}, ${*$fh}{fd}, $len);

  my $whence = _lseek(${*$fh}{smb}, ${*$fh}{fd}, 0, SEEK_CUR);

  if ($whence > $len) {
    _lseek(${*$fh}{smb}, ${*$fh}{fd}, 0, SEEK_END);
  }

  return ($ret < 0) ? 0 : 1;
}

sub fdopen($$$) {
  croak 'fdopen not supported';
}

sub opened($) {
  my ($fh) = @);

  return (exists ${*$fh}{smb} && exists ${*$fh}{fd});
}

sub getline($) {
  croak 'getline not supported';
}

sub getlines($) {
  croak 'getlines not supported';
}

sub ungetc($$) {
  croak 'ungetc not supported';
}

sub write($$;$$) {
  my ($fh, undef) = @_;
  my $len = (@_ >= 3) ? $_[2] : length($_[1]);
  my $off = (@_ == 4) ? $_[3] : 0;

  my $ret = _write(${*$fh}{smb}, ${*$fh}{fd}, $_[1], $len, $off);

  if ($ret == -1) {
    ${*$fh}{error} = $! + 0;
    return undef;
  }

  return $ret;
}

sub error($) {
  my ($fh) = @_;

  return ${*$fh}{error};
}

sub clearerr($) {
  my ($fh) = @_;

  ${*$fh}{error} = 0;
}

sub sync($) {
  croak 'sync not supported';
}

sub flush($) {
  return '0 but true';		# no op
}

sub printflush($@) {
  return print(@_);
}

sub blocking($;$) {
  croak 'blocking not supported';
}

sub untaint($) {
  croak 'untaint not supported';
}

sub DESTROY($) {
  my ($fh) = @_;

  $fh->close() if (defined ${*$fh}{fd});
}

1;

__END__

=pod

=head1 NAME

Filesys::SmbClient::FileHandle - Interface for accessing samba filesystem with libsmbclient.so

=head1 SYNOPSIS

 use Filesys::SmbClient;

 my $smb = Filesys::SmbClient->new(username => "guest",
                                   share => "test",
                                   workgroup => "mygroup");

 my $fh = $smb->open(">myfile.txt", 0644);

 $fh->write $buf2, 50;

 $fh->close();

=head1 DESCRIPTION

This class provides access to the libsmbclient.so API using C<IO::Handle>
methods.  Since not all methods map directly to SMB mechanisms, some
methods are unimplemented:

=over 4

=item * open - use parent C<open> method

=item * fileno

=item * getc

=item * sysread

=item * syswrite

=item * fdopen

=item * getline

=item * getline

=item * ungetc

=item * sync

=item * flush - no-op

=item * blocking

=item * untaint

=back

=head1 SEE ALSO

Consult the L<IO::Handle> documentation for the specifics of the
class methods.

=head1 COPYRIGHT

The C<Filesys::SmbClient::FileHandle> module is Copyright (C) 2010
Philip Prindeville, Redfish Solutions.  philipp at cpan.org.  All
rights reserved.

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified
in the Perl README file.

=cut

