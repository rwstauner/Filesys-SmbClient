#!/usr/bin/perl -w

use Test::More;
use Filesys::SmbClient qw(:raw SMBC_FILE SMBC_DIR SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON);
use strict;
use diagnostics;

use lib 't/lib';
use Test_SMB;

use POSIX;

my $tests = 31;
plan tests => $tests;

my $loaded = 1;
ok($loaded,"Load module");

my $buffer = "A test of write call\n";
my $buffer2 = "buffer of 1234\n";

SKIP: {
  skip_if_no_server_info($tests - 1);

  my %param = connection_params();
  my $server = server_uri(%param);

  is(SMBC_FILE, 8, "verify importing SMBC_FILE");

  my $smb = _init($param{username}, $param{password}, $param{workgroup},
                  $param{debug});
  isa_ok($smb, 'SMBCCTXPtr', "Allocate object");


  # Create a directory
  is(_mkdir($smb,"$server/toto",'0666'),0,"Create directory")
    or diag("With $!");

  # Create a existent directory
  isnt(_mkdir($smb,"$server/toto",'0666'),0,"Create existent directory");

  # Write a file
  SKIP: {
    my $fd = _open($smb,">$server/toto/test",0666);

    isa_ok($fd,"SMBCFILEPtr","Smb File Descriptor")
      # if opening fails, skip the next two
      or skip "Failed to open file for writing: $!", 2;

    ok(_write($smb,$fd,$buffer,length($buffer),0)>0,"Write to test file");

    is(_close($smb,$fd),0,"Close test file")
      or diag("With $!");
  }

  # Rename a file
  ok(_rename($smb,"$server/toto/test","$server/toto/tata")>=0,"Rename file")
    or diag("With $!");

  # Stat a file
  my @tab = _stat($smb,"$server/toto/tata");
  ok(@tab == 13,"Stat file ") or diag("With $!");

  # Stat a non-existent file
  @tab = _stat($smb,"smb://jupidsdsdster/soft/lala");
  ok(@tab == 0,"Stat non-existent file") or diag("With $!");

  # Read a file
  SKIP: {
    my $fd = _open($smb,"$server/toto/tata",'0666');
    isa_ok($fd,"SMBCFILEPtr","Smb File Descriptor")
      or skip "Failed to open file for reading: $!", 4;

    my $l;
    my $buf='abcdefghi';
    $l = _read($smb,$fd,$buf,50,3);

    is($l, length($buffer), "length on read test file")
        or diag("read ", length($buf), " bytes)");
    is($buf, 'abc' . $buffer, "contents on read test file");

    $l = _read($smb,$fd,$buf,50,0);
    is($l,0, "read at end-of-file returns 0");

    ok(_close($smb,$fd)==0,"Closing test reading file");
  }

  # Read long info on a directory
  SKIP: {
    my @a;
    my $fd = _opendir($smb,"$server/toto");

    # FIXME: the number of tests in this group is unknown unless we populate the directory ourselves
    # FIXME: this test requires 3 dir entires (".", "..", and something else)
    my $dir_entries = 3;

    isa_ok($fd,"SMBCFILEPtr","Smb Directory Handle")
      or skip "Failed to open directory: $!", 2 + $dir_entries;

    # _readdir returns (type, name, comment)
    while (my @b = _readdir($smb,$fd)) {
      is(@b,3,"iterative readdir on toto");
      push(@a,$b[1]);
    }

    is(@a, $dir_entries, "Read long directory");

    is(_close($smb,$fd),0,"Closing test directory");
  }

  # Unlink a file
  is(_unlink($smb,"$server/toto/tata"),0,"Unlink file")
    or diag("With $!");

  # Unlink a non-existent file
  isnt(_unlink($smb,"$server/toto/tatarr"),0,"Unlink non-existent file");

  is(_mkdir($smb,"$server/toto/tate",'0666'),0,"Create directory")
    or diag("With $!");

  is(_mkdir($smb,"$server/toto/tate/titi",'0666'),0,"Create directory")
    or diag("With $!");

  foreach ("$server/toto/tate/titi", "$server/toto/tate", "$server/toto") {
    is(_rmdir($smb,$_),0,"Remove directory")
      or diag("With $!");
  }

  # Erase non-existent directory
  isnt(_rmdir($smb,"$server/totoarr/"),0,"Rm non-existent directory");

  # Rename a non-existent file
  isnt(_rename($smb,"$server/toto/testrr","$server/toto/tata"),0,
     "Rename non-existent file");

  print "There is a .c file in this directory with info about your params \n",
        "for you SMB server test. Think to remove it if you have finish \n",
	  "with test.\n\n";
}
