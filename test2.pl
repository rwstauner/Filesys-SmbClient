#!/usr/bin/perl
use POSIX;
use Filesys::SmbClient;  

my $smb = new Filesys::SmbClient(username  => "alian",
				 password  => "speed", 
				 workgroup => "alian",
				 debug     => 10);  

# Directory

# Read a directory
my $fd = $smb->opendir("smb://jupiter/doc");
foreach my $n ($smb->readdir($fd)) {print $n,"\n";}
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
$smb->mkdir("smb://jupiter/doc/toto",'0666') 
  || print "Error mkdir: ", $!, "\n";

# Erase this directory
$smb->rmdir("smb://jupiter/doc/toto")
  || print "Error rmdir: ", $!, "\n";

# Files

# Write a file
#my $fd = $smb->open("smb://jupiter/doc/test",O_CREAT, 0666) 
#  || print "Can't create file:", $!, "\n";
#$smb->write($fd,"A test of write call") || print $!,"\n";
#$smb->close($fd);  
#exit;

# Read a file
my $fd = $smb->open("smb://jupiter/doc/general.css",O_RDONLY,'0666');
while (defined(my $l= $smb->read($fd,50))) {print $l; }
$smb->close(fd);  

# Stat a file
my @tab = $smb->stat("smb://jupiter/doc/tata");
if ($#tab == 0) { print "Erreur in stat:", $!, "\n"; }
else
  {
    for (10..12) {$tab[$_] = localtime($tab[$_]);}
    print join("\n",@tab);
  }

# Rename a file
$smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata")
  || print "Can't rename file:", $!, "\n";

# Unlink a file
$smb->unlink("smb://jupiter/doc/test") 
  || print "Can't unlink file:", $!, "\n";

