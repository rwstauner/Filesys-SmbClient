package Filesys::SmbClient;
 
# module Filesys::SmbClient : provide function to access Samba filesystem
# with libsmclient.so
# Copyright 2000 A.Barbet alian@alianwebserver.com.  All rights reserved.

# $Log: SmbClient.pm,v $
# Revision 0.6  2001/12/13 23:20:41  alian
# - Change in _read method for take it binary safe. Tks to Robert Richmond
# <bob@netus.com>
#
# Revision 0.5  2001/10/22 12:39:36  alian
# - Add behaviour to create an empty $HOME/.smb/smb.conf file if not exist
# (else libsmbclient.so will segfault !)
#
# Revision 0.4  2001/10/22 10:58:38  alian
# - Mise a jour de la documentation pour le nouveau format de open
# - Suppression d'une trace oubliee
#
# Revision 0.3  2001/08/04 15:30:20  alian
# - Update for version 2.2.1 of Samba
# - Update POD documentation
# - Add fstat, rmdir, unlink_print_job, print_file method
# - Update return code to use Perl style
# - Add TODO section
# - Update read routine to remove memory leak
# - Change parameters for constructor of Filesys::SmbClient : see POD doc
#
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
$VERSION = ('$Revision: 0.6 $ ' =~ /(\d+\.\d+)/)[0];

bootstrap Filesys::SmbClient $VERSION;

my %commandes =
  (
   "close"            => \&_close,
   "closedir"         => \&_closedir,
   "fstat"            => \&_fstat,
   "mkdir"            => \&_mkdir,
   "open"             => \&_open,
   "opendir"          => \&_opendir,
   "print_file"       => \&_print_file,
   "stat"             => \&_stat,
   "rename"           => \&_rename,
   "rmdir"            => \&_rmdir,
   "read"             => \&_read,
   "unlink"           => \&_unlink,
   "unlink_print_job" => \&_unlink_print_job,
   "write"            => \&_write,
  );

#------------------------------------------------------------------------------
# AUTOLOAD
#------------------------------------------------------------------------------
sub AUTOLOAD
  {
  my $self =shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*:://;
  return unless $attr =~ /[^A-Z]/;
  die "Method undef ->$attr()\n" unless defined($commandes{$attr});
  return $commandes{$attr}->(@_);
  }

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new 
  {
    my $class = shift;
    my $self = {};
    my @l; 
    bless $self, $class;
    if (@_)
      {
	my %vars =@_;
	if (!$vars{'workgroup'}) { $vars{'workgroup'}=""; }
	if (!$vars{'username'})  { $vars{'username'}=""; }
	if (!$vars{'password'})  { $vars{'password'}=""; }
	if (!$vars{'debug'})     { $vars{'debug'}=0; }
	push(@l, $vars{'username'});
	push(@l, $vars{'password'});
	push(@l, $vars{'workgroup'});
	push(@l, $vars{'debug'});
      }    
    else { @l =("","","",0); }
    if (!-e "$ENV{HOME}/.smb/smb.conf")
	{
	  print STDERR "you don't have a $ENV{HOME}/.smb/smb.conf, ",
	    "I will create it (empty file)\n";
	  mkdir "$ENV{HOME}/.smb" unless (-e "$ENV{HOME}/.smb");
	  open(F,">$ENV{HOME}/.smb/smb.conf") || 
	    die "Can't create $ENV{HOME}/.smb/smb.conf : $!\n";
	  close(F);
	}
    my $ret = _init(@l);
    if ($ret <0)
      {die 'You must have a samba configuration file '.
	 '($HOME/.smb/smb.conf , even if it is empty';}
    return $self;
  }

#------------------------------------------------------------------------------
# readdir_struct
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# readdir
#------------------------------------------------------------------------------
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

Filesys::SmbClient - Interface for access Samba filesystem with libsmclient.so

=head1 SYNOPSIS

  use POSIX;
  use Filesys::SmbClient;  

  my $smb = new Filesys::SmbClient(username  => "alian",
				   password  => "speed", 
				   workgroup => "alian",
				   debug     => 10);  
    
  # Read a file
  my $fd = $smb->open("smb://jupiter/doc/general.css", '0666');
  while (defined(my $l= $smb->read($fd,50))) {print $l; }
  $smb->close(fd);  

  # ...

There is some others examples in test.pl file

=head1 DESCRIPTION

Provide interface to access routine defined in libsmbclient.so.

On 2001/08/05, this library is available on Samba source, but is not
build by default. (release 2.2.1).
Do "make bin/libsmbclient.so" in sources directory of Samba to build 
this libraries. Then copy source/include/libsmbclient.h
and source/bin/libsmbclient.so where you need them before install this
module.

When a path is used, his scheme is :

  smb://server/share/rep/doc

=head1 VERSION

$Revision: 0.6 $

=head1 FONCTIONS

=over

=item new(%hash)

Init connection
Hash can have this keys:

=over

=item *

username

=item *

password

=item * 

workgroup

=item *

debug

=back

Return instance of Filesys::SmbClient on succes, die with error else.

Example:

  my $smb = new Filesys::SmbClient(username  => "alian",
				   password  => "speed", 
				   workgroup => "alian",
				   debug     => 10);

=back

=head2 Directory

=over

=item mkdir($fname,$mode)

Create directory $fname with permissions set to $mode.
Return 1 on success, else 0 is return and errno and $! is set.

Example:

  $smb->mkdir("smb://jupiter/doc/toto",'0666') 
    || print "Error mkdir: ", $!, "\n";

=item rmdir($fname)

Erase directory $fname. Return 1 on success, else 0 is return
and errno and $! is set.

Example:

  $smb->rmdir("smb://jupiter/doc/toto")
    || print "Error rmdir: ", $!, "\n";

=item opendir($fname)

Open directory $fname and return file descriptor.

=item readdir($fd)

Read a directory. In a list context, return the full content of
the directory $fd, else return next element. Each elem is
a name of a directory or files.

Return undef at end of directory.

Example:

  my $fd = $smb->opendir("smb://jupiter/doc");
  foreach my $n ($smb->readdir($fd)) {print $n,"\n";}
  close($fd);

=item readdir_struct($fd)

Read a directory. In a list context, return the full content of
the directory $fd, else return next element. Each element
is a ref to an array with type and name. Type can be :

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

Return undef at end of directory.

Example:

  my $fd = $smb->opendir("smb://jupiter/doc");
  while (my $f = $smb->readdir_struct($fd))
    {
    if ($f->[0] == SMBC_DIR) {print "Directory ",$f->[1],"\n";}
    elsif ($f->[0] == SMBC_FILE) {print "File ",$f->[1],"\n";}
    # ...
    }
  close($fd);

=item closedir($fd)

Close directory $fd.

=back

=head2 Files

=over

=item stat($fname)

Stat a file to get info via file $fname. Return a list with info on
success, else an empty list is return and $! is set. 

List is made with:

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

Example:

  my @tab = $smb->stat("smb://jupiter/doc/tata");
  if ($#tab == 0) { print "Erreur in stat:", $!, "\n"; }
  else
    {
      for (10..12) {$tab[$_] = localtime($tab[$_]);}
      print join("\n",@tab);
    }

=item fstat($fd)

Like stat, but on a file descriptor

=item rename($oname,$nname)

Rename $oname in  $nname. Return 1 on success, else 0 is return
and errno and $! is set.

Example:

  $smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata")
    || print "Can't rename file:", $!, "\n";
  

=item unlink($fname)

Unlink $fname. Return 1 on success, else 0 is return
and errno and $! is set.

Example:

  $smb->unlink("smb://jupiter/doc/test") 
    || print "Can't unlink file:", $!, "\n";


=item open($fname, $mode)

Open file $fname with perm $mode. Return file descriptor
on success, else 0 is return and $! is set.

Example:

  my $fd = $smb->open("smb://jupiter/doc/test", 0666) 
    || print "Can't read file:", $!, "\n";

  my $fd = $smb->open(">smb://jupiter/doc/test", 0666) 
    || print "Can't create file:", $!, "\n";

  my $fd = $smb->open(">>smb://jupiter/doc/test", 0666) 
    || print "Can't append to file:", $!, "\n";


=item read($fd,$count)

Read $count bytes of data on file descriptor $fd. Return buffer read on
success, undef at end of file, -1 is return on error and $! is set.

=item write($fd,$buf)

Write $buf on file descriptor $fd. Return number of bytes wrote, else -1
is return and errno and $! is set.

Example:

  my $fd = $smb->open(">smb://jupiter/doc/test", 0666) 
    || print "Can't create file:", $!, "\n";
  $smb->write($fd,"A test of write call", length("A test of write call")) 
    || print $!,"\n";
  $smb->close($fd);

=item close($fd)

Close file descriptior $fd. Return 0 on success, else -1 is return and
errno and $! is set.

=back

=head2 Print method

=over

=item unlink_print_job($purl, $id)

Remove job number $id on printer $purl

=item print_file($purl, $printer)

Print file $purl on $printer

=back

=head1 TODO

=over 

=item *

chown

=item *

chmod

=item *

open_print_job

=item *

telldir

=item *

lseekdir

=item *

lseek

=back

=head1 AUTHOR

Alain BARBET,  alian@alianwebserver.com

=cut
