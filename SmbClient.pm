package Filesys::SmbClient;

# module Filesys::SmbClient : provide function to access Samba filesystem
# with libsmclient.so
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: SmbClient.pm,v $
# Revision 0.1.1.1  2000/12/28 01:12:25  alian
# First beta release
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
use vars qw($AUTOLOAD %func_ok);
@EXPORT = qw();
$VERSION = ('$Revision: 0.1.1.1 $ ' =~ /(\d+\.\d+)/)[0];

bootstrap Filesys::SmbClient $VERSION;

my %commandes =
  (
  "mkdir"     => \&_mkdir,
  "unlink"     =>\&_unlink,
  "stat"        =>\&_stat,
  "rename" =>\&_rename,
  "open"     =>\&_open,
  "read"      =>\&_read,
  "write"      =>\&_write,
  "close"     =>\&_close
  );

sub AUTOLOAD
  {
  my $self =shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*:://;
  return unless $attr =~ /[^A-Z]/;
  die "Méthod undef ->$attr()\n" unless defined($commandes{$attr});
  return $commandes{$attr}->(@_);
  }


sub new {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        _init($_[0],$_[1]);
        return $self;
        }
1;
__END__

=head1 NAME

Filesys::SmbClient - Perl extension for access Samba filesystem with libsmclient.so

=head1 SYNOPSIS

 use POSIX;
 use Filesys::SmbClient;

 my $smb = new Filesys::SmbClient("alian",10);

 # Read a file
 my $fd = $smb->open("smb://jupiter/doc/toto",O_RDONLY, 0666);
 while (defined(my $l= $smb->read($fd,50))) {print $l; }
 $smb->close(fd);

 # Write a file
 my $fd = $smb->open("smb://jupiter/doc/test",O_CREAT, 0666);
 $smb->write($fd,"A test of write call") || print $!,"\n";
 $smb->close(fd);

 # Rename a file
 $smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata"),"\n";

 # Create a directory (not yet implemented in libsmbclient.so ;-)
 $smb->mkdir("smb://jupiter/doc/toto",10);

 # Delete a file
 $smb->unlink("smb://jupiter/doc/test");

 # Stat a file
 my @tab = $smb->stat("smb://jupiter/doc/tata");
 for (10..12) {$tab[$_] = localtime($tab[$_]);}
 print join("\n",@tab);

=head1 DESCRIPTION

Provide interface to access routine defined in libsmbclient.so.
On 2000/12/28, this library is only available with CVS source of Samba (target head),
See on samba.org web site, section developpement. This module is a beta version !

When a path is used, his scheme is :

  smb://server/share/rep/doc

=head1 VERSION

$Revision: 0.1.1.1 $

=head1 FONCTIONS

=over

=item new($wgroup,$debug)

Init some things

  $wgroup : Current workgroup
  $debug : level of debug

Return 0 on succes, errno else.

=item unlink($fname)

Delete file $fname

Return 0 on succes, errno else.

=cut

=item mkdir($fname,$mode)

Create directory $fname with permissions set to $mode

=cut

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
