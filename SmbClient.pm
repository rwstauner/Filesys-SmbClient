package Filesys::SmbClient;

# module Filesys::SmbClient : provide function to access Samba filesystem
# with libsmclient.so
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: SmbClient.pm,v $
# Revision 0.2  2001/01/21 00:38:28  alian
# + Update for version 1.10 of libsmbclient.c
# + Provide readdir routines
# + Add pod documentation
#
# Revision 0.1.1.1  2000/12/28 01:12:25  alian
# First beta release
#

use strict;
use constant SMBC_WORKGROUP  => 1;
use constant SMBC_SERVER => 2;
use constant SMBC_FILE_SHARE => 3;
use constant SMBC_PRINTER_SHARE => 4;
use constant SMBC_COMMS_SHARE => 5;
use constant SMBC_IPC_SHARE =>6;
use constant SMBC_DIR => 7;
use constant SMBC_FILE => 8;
use constant SMBC_LINK => 9;
use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);
require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(SMBC_DIR SMBC_WORKGROUP SMBC_SERVER SMBC_FILE_SHARE
                             SMBC_PRINTER_SHARE SMBC_COMMS_SHARE SMBC_IPC_SHARE SMBC_FILE
                             SMBC_LINK);
$VERSION = ('$Revision: 0.2 $ ' =~ /(\d+\.\d+)/)[0];

bootstrap Filesys::SmbClient $VERSION;

my %commandes =
  (
  "mkdir"     => \&_mkdir,
  "unlink"     =>\&_unlink,
  "stat"        =>\&_stat,
  "rename" =>\&_rename,
  "open"     =>\&_open,
  "opendir"=>\&_opendir,
  "read"      =>\&_read,
  "write"      =>\&_write,
  "close"     =>\&_close,
  "closedir"=>\&_closedir,
  );

sub AUTOLOAD
  {
  my $self =shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*:://;
  return unless $attr =~ /[^A-Z]/;
  die "Method undef ->$attr()\n" unless defined($commandes{$attr});
  return $commandes{$attr}->(@_);
  }


sub new {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        my $ret = _init($_[0],$_[1]);
        if ($ret <0)
          {die 'You must have a samba configuration file ($HOME/.smb/smb.conf or /etc/smb.conf), even if it is empty';}
        return $self;
        }

sub readdir_struct
  {
  my $self=shift;
  if (wantarray())
    {
    my @tab;
    while (my @l  = _readdir($_[0])) {push(@tab,\@l);}
    return @tab;
    }
  else {my @l = _readdir($_[0]);return \@l if (@l);}
  }

sub readdir
  {
  my $self=shift;
  if (wantarray())
    {
    my @tab;
    while (my @l  = _readdir($_[0])) { push(@tab,$l[1]);}
    return @tab;
    }
  else {my @l =_readdir($_[0]);return $l[1];}
  }

1;
__END__


=head1 NAME

Filesys::SmbClient - Perl extension for access Samba filesystem with libsmclient.so

=head1 SYNOPSIS

  use POSIX;
  use Filesys::SmbClient;

  my $smb = new Filesys::SmbClient("alian",10);

  # Read a directory
  my $fd = $smb->opendir("smb://jupiter/doc");
  while ($smb->readdir($fd)) {print $_,"\n";}
  close($fd);

  # Read long info on a directory
  my $fd = $smb->opendir("smb://jupiter/doc");
  while (my $f = $smb->readdir_struct($fd))
    {
    if ($f->[0] == SMBC_DIR) {print "Directory ",$f->[1],"\n";}
    elsif ($f->[0] == SMBC_FILE) {print "File ",$f->[1],"\n";}
    # ...
    }
  close($fd);

  # Create a directory
  $smb->mkdir("smb://jupiter/doc/toto",'0666');

  # Read a file
  my $fd = $smb->open("smb://jupiter/doc/toto",O_RDONLY,'0666');
  while (defined(my $l= $smb->read($fd,50))) {print $l; }
  $smb->close(fd);

  # Write a file
  my $fd = $smb->open("smb://jupiter/doc/test",O_CREAT, 0666);
  $smb->write($fd,"A test of write call") || print $!,"\n";
  $smb->close(fd);

  # Rename a file
  $smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata"),"\n";

  # Delete a file
  $smb->unlink("smb://jupiter/doc/test");

  # Stat a file
  my @tab = $smb->stat("smb://jupiter/doc/tata");
  for (10..12) {$tab[$_] = localtime($tab[$_]);}
  print join("\n",@tab);


=head1 DESCRIPTION

Provide interface to access routine defined in libsmbclient.so.
On 2001/01/21, this library is only available with CVS source of Samba (target head),
See on samba.org web site, section download. This module is a beta version !

When a path is used, his scheme is :

  smb://server/share/rep/doc

=head1 VERSION

$Revision: 0.2 $

=head1 FONCTIONS

=over

=item new($wgroup,$debug)

Init some things

  $wgroup : Current workgroup
  $debug : level of debug

Return 0 on succes, errno else.

=back

=head2 Directory

=over

=item mkdir($fname,$mode)

Create directory $fname with permissions set to $mode

=item opendir($fname)

Open directory $fname and return file descriptor.

=item readdir($fd)

Read a directory. In a list context, return the full content of
the directory $fd, else return next element. Each elem is
a name of a directory or files.

Return undef at end of directory.

=item readdir_struct($fd)

Read a directory. In a list context, return the full content of
the directory $fd, else return next element. Each element
is a ref to an array with type and name. Type can be :

Return undef at end of directory.

=over

=item SMBC_WORKGROUP

=item SMBC_SERVER

=item SMBC_FILE_SHARE

=item SMBC_PRINTER_SHARE

=item SMBC_COMMS_SHARE

=item SMBC_IPC_SHARE

=item SMBC_DIR

=item SMBC_FILE

=item SMBC_LINK

=back

=item closedir($fd)

Close directory $fd.

=back

=head2 Files

=over

=item unlink($fname)

Delete file $fname

Return 0 on succes, errno else.

=item stat($fname)

Stat a file to get info via file $fname. Return a array with info on
success, else errno is return and $! is set. Tab is made with:

=over

=item *

device

=item *

inode

=item *

protection

=item *

number of hard links

=item *

user ID of owner

=item *

group ID of owner

=item *

device type (if inode device)

=item *

total size, in bytes

=item *

blocksize for filesystem I/O

=item *

number of blocks allocated

=item *

time of last access

=item *

time of last modification

=item *

time of last change

=back

=cut

=item rename($oname,$nname)

Rename $oname in  $nname. Return 0 on success, else -1 is return
and errno and $! is set.

=item open($fname, $flags, $mode)

Open file $fname with flags $flags and mode $mode. Return file descriptor
on success, else -1 is return and errno and $! is set.

=item read($fd,$count)

Read $count bytes of data on file descriptor $fd. Return buffer read on
success, undef at end of file, -1 is return on error and $! is set.

=item write($fd,$buf)

Write $buf on file descriptor $fd. Return number of bytes wrote, else -1
is return and errno and $! is set.

=item close($fd)

Close file descriptior $fd. Return 0 on success, else -1 is return and
errno and $! is set.

=back

=head1 AUTHOR

Alain BARBET,  alian@alianwebserver.com

=cut
