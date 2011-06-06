package Filesys::SmbClient;
 
# module Filesys::SmbClient : provide function to access Samba filesystem
# with libsmclient.so
#
# Copyright 2010 Philip Prindeville philipp@cpan.org  All rights reserved.
# Copyright 2000-2006 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: SmbClient.pm,v $
# Revision 3.99  2010/04/02 12:10:05  philipp
#  - Add additional TIEHANDLE methods.
#  - Fix return values to true/false as per Perl, rather than 0 on success
#    and <0 on failure.
#  - Use new API from samba 3.4 onwards
#  - Create Directory and File subclasses based on IO::Dir and IO::Handle
#    base classes
#  - Require Perl 5.6 as a minimum
#
# release 3.1: fix for rt#12221 rt#18757 rt#13173 and bug in configure
#
# Revision 3.0  2005/03/04 16:15:00  alian
# 3.0  2005/03/05 alian
#  - Update to samba3 API and use SMBCTXX
#  - Add set_flag method for samba 3.0.11
#  - Update smb2www-2.cgi to browse workgroup with smb://
#  - Return 0 not undef at end of file with read/READLINE
#   (tks to jonathan.segal at genizon.com for report).
#  - Fix whence bug in seek method (not used before)
#  - Add some tests for read and seek patched in this version
#
# Revision 1.5  2003/11/09 18:28:01  alian
# Add Copyright section
#
# See file CHANGES for others update

use strict;
use warnings;
use Carp;

use 5.006;

use constant {
	SMBC_WORKGROUP => 1,
        SMBC_SERVER => 2,
        SMBC_FILE_SHARE => 3,
        SMBC_PRINTER_SHARE => 4,
        SMBC_COMMS_SHARE => 5,
        SMBC_IPC_SHARE =>6,
        SMBC_DIR => 7,
        SMBC_FILE => 8,
        SMBC_LINK => 9,
        MAX_LENGTH_LINE => 4096,
        SMB_CTX_FLAG_USE_KERBEROS => (1 << 0),
        SMB_CTX_FLAG_FALLBACK_AFTER_KERBEROS => (1 << 1),
        SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON => (1 << 2),
};

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;
require DynaLoader;

use POSIX qw(SEEK_CUR);
use Tie::Handle;

BEGIN {
  @ISA = qw(Exporter DynaLoader Tie::Handle);
  @EXPORT = qw(
	SMBC_WORKGROUP SMBC_SERVER SMBC_FILE_SHARE
	SMBC_PRINTER_SHARE SMBC_COMMS_SHARE SMBC_IPC_SHARE
	SMBC_DIR SMBC_FILE SMBC_LINK
	SMB_CTX_FLAG_USE_KERBEROS SMB_CTX_FLAG_FALLBACK_AFTER_KERBEROS
        SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON
  );
  # allow direct access to the stubs
  %EXPORT_TAGS = (
	raw => [qw(
		    _init _free _set_flags _mkdir _rmdir
		    _opendir _closedir _readdir _telldir _lseekdir
		    _stat _fstat _rename _open _read _write _lseek _ftruncate
		    _close _unlink _unlink_print_job _print_file
		)],
#		    _utimes
  );

  Exporter::export_ok_tags('raw');
}

$VERSION = ('$Revision: 3.99_51 $ ' =~ /(\d+\.\d+(_\d+)?)/)[0];

bootstrap Filesys::SmbClient $VERSION;

our $DEBUG = 0;

use Filesys::SmbClient::FileHandle;
use Filesys::SmbClient::DirHandle;

#------------------------------------------------------------------------------
# TIEHANDLE
#------------------------------------------------------------------------------
sub TIEHANDLE {
  my ($class,$fn,$mode,@args) = @_;
  $mode = '0666' if (!$mode);
  my $self = new($class, @args);
  print "Filesys::SmbClient TIEHANDLE\n" if ($DEBUG);
  if ($fn) {
    $self->{FD} = _open($self->{context}, $fn, $mode) or return undef; }
  return $self;
}

#------------------------------------------------------------------------------
# OPEN
#------------------------------------------------------------------------------
sub OPEN {
  my ($class,$fn,$mode) = @_;
  $mode = '0666' if (!$mode);
  print "OPEN\n" if ($DEBUG);
  $class->{FD} = _open($class->{context}, $fn, $mode) or return undef;
  $class;
}

#------------------------------------------------------------------------------
# WRITE
#------------------------------------------------------------------------------
sub WRITE {
  my ($self, undef, $len) = @_;
  my $off = (@_ == 4) ? $_[3] : 0;
  print "Filesys::SmbClient WRITE\n" if ($DEBUG);
  my $lg = _write($self->{context}, $self->{FD}, $_[1], $len, $off);
  return ($lg == -1) ? undef : $lg;
}

#------------------------------------------------------------------------------
# PRINT
#------------------------------------------------------------------------------
sub PRINT {
  my $self = shift;
  print "Filesys::SmbClient PRINT\n" if ($DEBUG);
  local $, ||= '';
  local $\ ||= '';
  my $buf = join($,, @_) . $\;
  my $lg = WRITE($self, $buf, length($buf), 0);
  return ($lg == -1) ? undef : $lg;
}

#------------------------------------------------------------------------------
# PRINTF
#------------------------------------------------------------------------------
sub PRINTF {
  my $self = shift;
  my $fmt = shift;
  print "Filesys::SmbClient PRINTF\n" if ($DEBUG);
  my $buf = sprintf $fmt, @_;
  my $lg = WRITE($self, $buf, length($buf), 0);
  return ($lg == -1) ? undef : $lg;
}

#------------------------------------------------------------------------------
# SEEK
#------------------------------------------------------------------------------
sub SEEK {
  my ($self,$offset,$whence) = @_;
  print "Filesys::SmbClient SEEK\n" if ($DEBUG);
  return _lseek($self->{context}, $self->{FD}, $offset, $whence);
}

#------------------------------------------------------------------------------
# TELL
#------------------------------------------------------------------------------
sub TELL {
  my ($self) = @_;
  print "Filesys::SmbClient TELL\n" if ($DEBUG);
  return _lseek($self->{context}, $self->{FD}, 0, SEEK_CUR);
}

#------------------------------------------------------------------------------
# READ
#------------------------------------------------------------------------------
sub READ {
  my ($self, undef, $len) = @_;
  my $off = (@_ == 4) ? $_[3] : 0;
  print "Filesys::SmbClient READ\n" if ($DEBUG);
  my $cnt = _read($self->{context}, $self->{FD}, $_[1], $len, $off);
  return ($cnt < 0) ? undef : $cnt;
}

#------------------------------------------------------------------------------
# READLINE
#------------------------------------------------------------------------------
sub READLINE {
  my $self = shift;
  print "Filesys::SmbClient READLINE\n" if ($DEBUG);
  croak "READLINE: record mode not supported" if (ref($/) ne '' || $/ =~ m/^\d+$/);
  my @lines = ();
  while (1) {
    my $buf = '';
    my $c;
    while ($c = $self->GETC()) {
      $buf .= $c;

      # check if $/ is set, and if so does it match the end of our buffer?
      next if (length($/) == 0);		# slurp mode
      last if (substr($buf, -length($/)) eq $/);
    }
    return $buf unless (wantarray());
    last unless (defined $c);		# EOF
    push(@lines,$buf);
  }
  return @lines;
}

#------------------------------------------------------------------------------
# GETC
#------------------------------------------------------------------------------
sub GETC {
  my $self = shift;
  my $c = '';
  print "Filesys::SmbClient GETC\n" if ($DEBUG);
  $self->READ($c,1,0) or return undef;
  return $c;
}

#------------------------------------------------------------------------------
# CLOSE
#------------------------------------------------------------------------------
sub CLOSE {
  my $self = shift;
  print "Filesys::SmbClient CLOSE\n" if ($DEBUG);
  _close($self->{context}, $self->{FD});
}

#------------------------------------------------------------------------------
# FILENO
#------------------------------------------------------------------------------
sub FILENO {
  my $self = shift;
  print "Filesys::SmbClient FILENO\n" if ($DEBUG);
  return -1;
}

#------------------------------------------------------------------------------
# UNTIE
#------------------------------------------------------------------------------
sub UNTIE {
  my $self=shift;
  print "Filesys::SmbClient UNTIE\n" if ($DEBUG);
  CLOSE($self);
}





#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new($;%) {
  my $class = shift;
  my $self = {};
  my @l; 
  bless $self, $class;
  my %vars = @_;
  if (keys %vars) {
    if (!$vars{'workgroup'}) { $vars{'workgroup'}=""; }
    if (!$vars{'username'})  { $vars{'username'}=""; }
    if (!$vars{'password'})  { $vars{'password'}=""; }
    if (!$vars{'debug'})     { $vars{'debug'}=0; }
    push(@l, $vars{'username'});
    push(@l, $vars{'password'});
    push(@l, $vars{'workgroup'});
    push(@l, $vars{'debug'});
    print "Filesys::SmbClient new>",join(" ", @l),"\n" if $vars{'debug'};
    $self->{params}= \%vars;
  }
  else { @l =("","","",0); }

  $self->{context} = _init(@l);
  $vars{'flags'} && _set_flags($self->{context}, $vars{'flags'});

  return $self;
}

sub DESTROY ($) {
  my ($self) = @_;

  _free($self->{context}, 1);
}

sub open($$;$) {
  my ($self, $file, $mode) = @_;

  $mode ||= 644;

  my $fd = _open($self->{context}, $file, $mode);

  return undef unless (defined $fd);

  return Filesys::SmbClient::FileHandle->new($self->{context}, $fd);
}

sub opendir($$) {
  my ($self, $dir) = @_;

  my $fd = _opendir($self->{context}, $dir);

  return undef unless (defined $fd);

  return Filesys::SmbClient::DirHandle->new($self->{context}, $fd);
}

# miscellany

sub mkdir($$;$) {
  my ($self, $dir) = @_;

  my $mode = (@_ == 3) ? $_[2] : 0777;	# modified by umask

  my $ret = _mkdir($self->{context}, $dir, $mode);

  return ($ret < 0) ? 0 : 1;
}

# sub utimes($$) {
#   my ($self, $file) = @_;
# 
#   my @args = _utimes($self->{context}, $file);
# 
#   return @args;
# }

sub unlink($$) {
  my ($self, $file) = @_;

  my $ret = _unlink($self->{context}, $file);

  return ($ret < 0) ? 0 : 1;
}

sub stat($$) {
  my ($self, $file) = @_;

  my @args = _stat($self->{context}, $file);

  return @args;
}

sub rmdir($$) {
  my ($self, $dir) = @_;

  my $ret = _rmdir($self->{context}, $dir);

  return ($ret < 0) ? 0 : 1;
}

sub rename($$$) {
  my ($self, $old, $new) = @_;

  my $ret = _rename($self->{context}, $old, $self->{context}, $new);

  return ($ret < 0) ? 0 : 1;
}

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

Filesys::SmbClient - Interface for accessing Samba filesystem with libsmclient.so

=head1 SYNOPSIS

 use POSIX;
 use Filesys::SmbClient;
 
 my $smb = Filesys::SmbClient->new(username  => "alian",
				    password  => "speed",
				    workgroup => "alian",
				    debug     => 10);
 
 # Read a file
 my $fh = $smb->open("smb://jupiter/doc/general.css", '0666');
 my $buf;
 while (defined($fh->read($buf,50))) {print $buf; }
 $fh->close();
  
  # ...

=head2 Models

There are 4 different interfaces to Samba.  The first one is the "raw"
access to the libsmbclient.so functions (well, most of them).  This is
done via:

 use Filesys::SmbClient qw(:raw);

Because the XS stub functions map directly to the libsmbclient.so API
and are subject to change, using these methods is strongly discouraged.

The second method is using the C<Tie::Handle> class, and is kept for
backward compatibility.  This is a very limited interface, and may
not be maintained much longer.

The last two interfaces are symmetrical and use the C<IO::Handle> and
C<IO::Dir> base classes for the derived classes C<FileHandle> and
C<DirHandle>.

Construction is done via the parent class, firstly:

 my $fh = $smb->open("a/b/foo.txt");

to open a file for reading (or with slight modification, for writing).
The class's own C<open> method isn't available, since opening is done via
the parent object.  The C<IO::Handle> methods that aren't implemented are:

=over 4

=item * open - use parent C<open> method

=item * eof

=item * fileno

=item * getc

=item * sysread

=item * syswrite

=item * fdopen

=item * getline

=item * getline

=item * ungetc

=item * clearerr

=item * sync

=item * flush - no-op

=item * blocking

=item * untaint

=back

The second construction is done similarly, for directories:

  my $dh = $smb->opendir("usr/spool");

and again, not all methods map onto SMB.  Omitted methods are:

=over 4

=item * open - use parent open method

=back

See the IO::Handle and IO::Dir modules' documentation for more info.

=head1 DESCRIPTION

Provide interface to access routine defined in libsmbclient.so provided with
Samba.

With the 4.0 release of this package, you are required to have Samba 3.4.5 or later.

If you want to use filehandle with this module, you need Perl 5.6 or later.

When a path is used, the URL is represented as:

  smb://server/share/rep/doc

=head1 VERSION

$Revision: 3.99 $

=head1 FUNCTIONS

Construct a Filesys::SmbClient object:

=over 4

=item * new %hash

The hash can have the keys:

=over 4

=item * username

=item * password

=item * workgroup

=item * debug

=item * flags - See set_flag

=back

=back

Returns an instance of Filesys::SmbClient on success, or undef otherwise.

Example:

 my $smb = new Filesys::SmbClient(username  => "alian",
				  password  => "speed", 
				  workgroup => "alian",
				  debug     => 10);


=over 4

=item set_flag

Set flag for smb connection. See _SMBCCTX->flags in libsmclient.h
Flags can be a combination of:

=over 4

=item SMB_CTX_FLAG_USE_KERBEROS

=item SMB_CTX_FLAG_FALLBACK_AFTER_KERBEROS

=item SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON

=back

=back

The returned object can then be used with "open" to construct a FileHandle,
with "opendir" to construct a DirHandle, or with "tie" to access
the legacy Tie::Handle API.

=head2 Tie Filesys::SmbClient filehandle

This didn't work before 5.005_64. Why, I don't know.
When you have tied a filehandle with Filesys::SmbClient,
you can call classic methods for filehandle:
print, printf, seek, syswrite, tell, getc, open, close, read.
See perldoc for usage.

Example:

 local *FD;
 tie(*FD, 'Filesys::SmbClient');
 open(FD,"smb://jupiter/doc/test")
     or print "Can't open file:", $!, "\n";
 while(<FD>) { print $_; }
 close(FD);

or

 local *FD;
 tie(*FD, 'Filesys::SmbClient');
 open(FD,">smb://jupiter/doc/test")
     or print "Can't create file:", $!, "\n";
 print FD "Samba test","\n";
 printf FD "%s", "And that work !\n";
 close(FD);

=head2 Miscellany

=over 4

=item mkdir FILENAME, MODE

Creates FILENAME, with permissions as MODE (as modified by umask).
Return 1 on success, otherwise 0 is return and errno and $! is set.

Example:

 $smb->mkdir("smb://jupiter/doc/toto",'0666') 
     or print "Error mkdir: ", $!, "\n";

=item rmdir DIRNAME

Unlink DIRNAME. Return 1 on success, otherwise 0 is return
and errno and $! is set.  The directory must be empty.

Example:

 $smb->rmdir("smb://jupiter/doc/toto")
     or print "Error rmdir: ", $!, "\n";

=item unlink FILENAME

Unlink FILENAME.  Return 1 on success, otherwise 0 is return
and errno and $! is set.

=item stat FILENAME

Returns the following about the named file or directory:

=over

=item * device number

=item * inode number

=item * permission modes

=item * number of links

=item * user identifier

=item * group identifier

=item * remote device number

=item * size

=item * block size

=item * blocks

=item * access time

=item * modification time

=item * creation time

=back

Note that because of filesystem "holes" the reported size may be larger
than the product of block size x blocks.

On failure, an empty list is returned and errno and $! is set.

=over 4

=item rename OLDNAME,NEWNAME

=back

Renames a file or directory; an existing file NEWNAME will be clobbered.
Returns 1 for success, 0 otherwise, with $! set.

Example:

 $smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata")
     or print "Can't rename file:", $!, "\n";

=head1 TODO

Revisit the list of IO::Handle methods that aren't implemented and see
which ones can be added.

=head1 COPYRIGHT

The Filesys-SmbClient module is Copyright (c) 1999-2003 Alain BARBET, France,
alian at cpan.org. All rights reserved.

Assumed in 2010 by Philip Prindeville.

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified
in the Perl README file.

=cut
