#!/usr/bin/perl -w

use Test::More;
use Filesys::SmbClient;
use strict;
use diagnostics;

(lc $^O eq 'linux' && system("lsof -v > /dev/null 2>&1") == 0)
  or plan skip_all => 'Linux and lsof required to test connection cleanup.';

my $loops = 3;
my $tests = $loops * 2;

plan tests => $tests;

SKIP: {
    # copied from t/02tie.t
    skip "No server defined for test at perl Makefile.PL", $tests if (!-e ".c");
    my $ok = 0;
    my (%param,$server);
    if (open(F,".c")) {
      my $l = <F>; chomp($l);
      my @l = split(/\t/, $l);
      %param =
        (
         username  => $l[3],
         password  => $l[4],
         workgroup => $l[2],
         debug     =>  0
        );
      $server = "smb://$l[0]/$l[1]";
    }

  for( 1 .. $loops ){
    {
      my $smb = Filesys::SmbClient->new(%param);

      my $dh = $smb->opendir($server)
        or die $!;

      #is($smb->readdir($dh), '.', 'directory contains "."');

      is(scalar lsof(), 1, 'one connection open');
    }
    # $smb gone out of scope; should clean up its connections
    # might need to sleep 1;

    is(scalar lsof(), 0, 'connections removed');
  }
}

sub lsof {
  my @lsof =
    grep { /:445 / } # netbios
      qx{lsof -P -p $$};
  return @lsof;
}
