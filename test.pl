# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN 
  { 
    $| = 1; 
    if (!-e ".c") { print "1..1\n"; }
    else { print "1..10\n";}
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
  my $total_test = 9;
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
  my $fd = $smb->open(">$server/toto/test",0666)
    || print "not ok 3 Create file:", $!, "\n";
  if ($fd)
    {
	if ($smb->write($fd,"A test of write call",
			    length("A test of write call")))
	  { print "ok 3 Create file\n";  $courant++;}
	else { print "not ok 3 Create file $!\n"; }
	$smb->close($fd);
    }

  # Rename a file
  if ($smb->rename("$server/toto/test","$server/toto/tata"))
    { print "ok 4 Rename file\n";  $courant++;}
  else { print "not ok 4 Rename file ", $!, "\n"; }

  # Stat a file
  my @tab = $smb->stat("$server/toto/tata");
  if ($#tab == 0) { print "not ok 5 Stat file ", $!, "\n"; }
  else { print "ok 5 Stat file\n";  $courant++;}

  # Read a file
  my $buf;
  my $fd = $smb->open("$server/toto/tata",'0666');
  while (defined(my $l= $smb->read($fd,50))) {$buf.=$l; }
  $smb->close($fd);
  if (length($buf) == length("A test of write call"))
    { print "ok 6 Read file\n";  $courant++;}
  else { print "not ok 6 Read file (read ",length($buf)," bytes)\n"; }

  # Directory
  # Read a directory
  my $fd = $smb->opendir("$server/toto") 
    || print "not ok 7 Read short directory $!\n";
  my @a;
  if ($fd)
    {	
	foreach my $n ($smb->readdir($fd)) {push(@a,$n);}
	if ($#a==2) { print "ok 7 Read short directory\n";  $courant++;}
	else {print "not ok 7 Read short directory ($#a)\n";}
    }
  close($fd);

  # Read long info on a directory
  undef @a;
  my $fd = $smb->opendir("$server/toto") ||
    print "not ok 8 Read long directory $!\n";
  if ($fd)
    {	
	while (my $f = $smb->readdir_struct($fd))
	  { push(@a,$n);}
	if ($#a==2) { print "ok 8 Read long directory\n";  $courant++;}
	else {print "not ok 8 Read long directory ($#a)\n";}
	close($fd);
    }

  # Unlink a file
  if ($smb->unlink("$server/toto/tata"))
    { print "ok 9 Unlink file\n";  $courant++;}
  else { print "not ok 9 Unlink file ", $!, "\n"; }

  # Erase this directory
  if ($smb->rmdir("$server/toto/"))
    { print "ok 10 Rm directory\n";  $courant++;}
  else { print "not ok 10 Rm directory ", $!, "\n"; }
  if ($courant == $total_test) 
    { print "All SMB test successful !\n\n"; }
  else { print "Some SMB tests fails !\n\n"; }
  print "There is a .c file in this directory with info about your params \n",
        "for you SMB server test. Think to remove it if you have finish \n",
	  "with test.\n\n";
}
