#!/usr/bin/perl -w

use Test::More;
use Filesys::SmbClient;
use strict;
use diagnostics;

use lib 't/lib';
use Test_SMB;

(lc $^O eq 'linux' && system("lsof -v > /dev/null 2>&1") == 0)
  or plan skip_all => 'Linux and lsof required to test connection cleanup.';

my $loops = 3;
my $tests = $loops * 2;

plan tests => $tests;

SKIP: {
  skip_if_no_server_info($tests);

  my %param = connection_params();
  my $server = server_uri(%param);

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
