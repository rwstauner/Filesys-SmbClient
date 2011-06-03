#!/usr/bin/perl

use Test::More tests => 38;

use constant { NULL => 0 };

use strict;
use warnings;

use Filesys::SmbClient qw(:raw);

SKIP: {
  skip "no server parameters", 30 unless (open(F,".c"));

  my $l = <F>; chomp($l);
  my ($server, $share, $workgroup, $user, $passwd) = split(/\t/, $l);
  close(F);

  my $url = 'smb://' . $server . '/' . $share . '/';
   
  my ($smb, $type, $name, $comment, @args, $ret, $file, $dir, $offset, $buf);

  $smb = Filesys::SmbClient->new();

  isa_ok($smb, 'Filesys::SmbClient');

  $smb = Filesys::SmbClient->new(workgroup => $workgroup, user => $user,
  			       password => $passwd, debug => 2);

  isa_ok($smb, 'Filesys::SmbClient');

  $ret = $smb->mkdir($url . 'testdir', 0644);

  ok($ret, 'create directory');

  $ret = $smb->mkdir($url . 'testdir', 0644);

  ok(!$ret, 'redo create directory');

  $file = $smb->open('>' . $url . 'testdir/a', 0600);

  isa_ok($file, 'Filesys::SmbClient::FileHandle', 'create test file a');

  $ret = $file->write('foobar', 6);

  ok($ret == 6, 'write to a');

  @args = $file->stat();

  ok($args[7] == 6, 'check size of file via stat');

  $ret = $file->truncate(3);

  ok($ret, 'truncate to 3');

  @args = $file->stat();

  ok($args[7] == 3, 'check size of file after truncate');

  my $literal = 'abcdefghijklmnopqrstuvwxyz';

  $ret = $file->write($literal, 3);

  is($ret, 3, 'write 3');

  $ret = $file->write($literal, 4, -6);

  is($ret, 4, 'write 4');

  $ret = $file->close();

  ok($ret, 'close file a');

  sleep(3);

  $file = $smb->open('>' . $url . 'testdir/b', 0644);

  isa_ok($file, 'Filesys::SmbClient::FileHandle', 'create test file b');

  @args = $file->stat($url . 'testdir/b');

  ok($args[7] == 0, 'check size of file via stat');

  $ret = $file->close();

  ok($ret, 'close file b');

  $file = $smb->open($url . 'testdir/a');

  $buf = undef;
  $ret = $file->read($buf, 1024);

  is($ret, 3 + 3 + 4, 'read back file a');
  ok($buf eq 'fooabcuvwx', 'actual contents of reading back a');

  $ret = $file->eof();

  is($ret, 0, 'negative test of eof');

  $ret = $file->read($buf, 1024);

  is($ret, 0, 'reading file a at end of file');

  $ret = $file->eof();

  is($ret, 1, 'positive test of eof');

  $ret = $file->close();

  ok($ret, 'closing file a at eof');

  ### directory stuff

  $dir = $smb->opendir($url . 'testdir');

  isa_ok($dir, 'Filesys::SmbClient::DirHandle', 'check opendir');

  $ret = $dir->tell();

  ok(defined $ret, 'first tell');

  $name = $dir->read();

  is($name, '.', 'read check for self');

  $name = $dir->read();

  is($name, '..', 'read check for parent');

  $offset = $dir->tell();

  isnt($offset, undef, '2nd telldir');

  $name = $dir->read();

  is($name, 'b', 'read check for file b');

  $name = $dir->read();

  is($name, 'a', 'read check for file a');

  $name = $dir->read();

  is($name, undef, 'read exhausted');

  $ret = $dir->seek($offset);

  is($ret, 1, 'seek back to 2nd telldir');

  $name = $dir->read();

  is($name, 'b', 'read 2nd check for file b');

  $ret = $dir->rewind();

  is($ret, 1, 'seek to beginning');

  $name = $dir->read();

  is($name, '.', '2nd read test for self');

  $ret = $dir->close();

  is($ret, 1, 'close');

  # @args = $smb->utimes($url . 'testdir/a');

  # is(@args, 2, 'utimes for a');

  # @args = $smb->utimes($url . 'testdir/nosuch');

  # is(@args, 0, 'utimes for nosuch');

  $ret = $smb->unlink($url . 'testdir/a');

  is($ret, 1, 'unlink a');

  $ret = $smb->unlink($url . 'testdir/b');

  is($ret, 1, 'unlink b');

  $ret = $smb->unlink($url . 'testdir/nosuch');

  is($ret, 0, 'unlink nosuch');

  $ret = $smb->rmdir($url . 'testdir');

  ok($ret, 'rmdir');
};

