# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN 
  { 
    $| = 1; 
    if (!-e ".c") { print "1..1\n"; }
    else { print "1..14\n";}
  }
END {print "not ok 1 Load module\n" unless $loaded;}
use Filesys::SmbClient;
$loaded = 1;
print "ok 1 Load module\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

if (-e ".c") {
  my $total_test = 13;
  my $courant = 0;
  use POSIX;
  open(F,".c") || die "Can't read .c\n";
  my $l = <F>; chomp($l); 
  my @l = split(/\t/, $l);
  my $smb = new Filesys::SmbClient(username  => $l[3],
					     password  => $l[4],
					     workgroup => $l[2],
					     debug     => 10);
  my $server = "smb://$l[0]/$l[1]";

  # Create a directory
  if ($smb->mkdir("$server/toto",'0666'))
    { print "ok 2 Create directory\n"; $courant++;}
  else { print "not ok 2 Create directory: ", $!, "\n"; }

  # Write a file
  my $fd = $smb->open(">$server/toto/test",0666);
  if ($fd)
    {
	if ($smb->write($fd,"A test of write call"))
	  { print "ok 3 Create file\n";  $courant++;}
	else { print "not ok 3 Create file $!\n"; }
	$smb->close($fd);
    }
  else { print "not ok 3 Create file:", $!, "\n"; }

  # Rename a file
  if ($smb->rename("$server/toto/test","$server/toto/tata"))
    { print "ok 4 Rename file\n";  $courant++;}
  else { print "not ok 4 Rename file ", $!, "\n"; }

  # Rename a non-existent ile
  if ($smb->rename("$server/toto/testrr","$server/toto/tata"))
    { print "not ok 5 Rename non-existent file\n"; }
  else { print "ok 5 Rename non-existent file\n";  $courant++;}

  # Stat a file
  my @tab = $smb->stat("$server/toto/tata");
  if ($#tab == 0) { print "not ok 6 Stat file ", $!, "\n"; }
  else { print "ok 6 Stat file\n";  $courant++;}

  # Stat a non-existent file
  my @tab = $smb->stat("smb://jupiter/soft/lala");
  if ($#tab == 0) { print "ok 7 Stat non-existent file \n"; $courant++;}
  else { print "not ok 7 Stat non-existent file\n"; }

  # Read a file
  my $buf;
  my $fd = $smb->open("$server/toto/tata",'0666');
  while (defined(my $l= $smb->read($fd,50))) {$buf.=$l; }
  $smb->close($fd);
  if (length($buf) == length("A test of write call"))
    { print "ok 8 Read file\n";  $courant++;}
  else { print "not ok 8 Read file (read ",length($buf)," bytes)\n"; }

  # Directory
  # Read a directory
  my $fd = $smb->opendir("$server/toto"); 
  my @a;
  if ($fd)
    {	
	foreach my $n ($smb->readdir($fd)) {push(@a,$n);}
	if ($#a==2) { print "ok 9 Read short directory\n";  $courant++;}
	else {print "not ok 9 Read short directory ($#a)\n";}
	close($fd);
    }
  else { print "not ok 9 Read short directory $!\n"; }

  # Read long info on a directory
  undef @a;
  my $fd = $smb->opendir("$server/toto");
  if ($fd)
    {	
	while (my $f = $smb->readdir_struct($fd))
	  { push(@a,$n);}
	if ($#a==2) { print "ok 10 Read long directory\n";  $courant++;}
	else {print "not ok 10 Read long directory ($#a)\n";}
	close($fd);
    }
  else { print "not ok 10 Read long directory $!\n"; }

  # Unlink a file
  if ($smb->unlink("$server/toto/tata"))
    { print "ok 11 Unlink file\n";  $courant++;}
  else { print "not ok 11 Unlink file ", $!, "\n"; }

  # Unlink a non-existent file
  if ($smb->unlink("$server/toto/tatarr"))
    { print "not ok 12 Unlink non-existent file\n";}
  else { print "ok 12 Unlink non-existent file\n";   $courant++;}

  # Erase this directory
  if ($smb->rmdir("$server/toto/"))
    { print "ok 13 Rm directory\n";  $courant++;}
  else { print "not ok 13 Rm directory ", $!, "\n"; }

  # Erase non-existent directory
  if ($smb->rmdir("$server/totoarr/"))
    { print "not ok 14 Rm non-existent directory\n"; }
  else { print "ok 14 Rm non-existent directory\n";  $courant++;}

  if ($courant == $total_test) 
    { print "All SMB test successful !\n\n"; }
  else { print "Some SMB tests fails !\n\n"; }

  print "There is a .c file in this directory with info about your params \n",
        "for you SMB server test. Think to remove it if you have finish \n",
	  "with test.\n\n";
}
