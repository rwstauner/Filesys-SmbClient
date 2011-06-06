# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package # hide
  Test_SMB;

use Test::More;
use Filesys::SmbClient qw(:raw SMBC_FILE SMBC_DIR SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON);

use Exporter qw(import);
our @EXPORT = qw(
       connection_params
  have_connection_params
  skip_if_no_server_info
  server_uri
);

our $FILE = '.c';
my $params;

sub connection_params {
  return unless have_connection_params();  # not configured
  return %$params if $params;              # already done
  return _parse_file($FILE);
}

# if answer to Makefile.PL was "yes" user was prompted for values
# stored in this file.  If "no", file should not exist.
sub have_connection_params {
  return -e $FILE;
}

sub _parse_file {
  my ($file) = @_;
  my @l = do {
    open(my $fh, '<', $file)
      or die "Failed to open connection parameters file '$file': $!";
    chomp(my $line = <$fh>);
    split(/\t/, $line);
  };
  $params = {
    host      => $l[0],
    share     => $l[1],
    workgroup => $l[2],
    username  => $l[3],
    password  => $l[4] || '',
    debug     =>  0,
    flags     => SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON
  };
  return %$params;
}

sub server_uri {
  my %params = @_;
  return "smb://$params{host}/$params{share}";
}

# convenience function to avoid copying the same message over and over
sub skip_if_no_server_info {
  my ($tests) = @_;
  skip 'No server identified for tests during Makefile.PL', $tests
    unless have_connection_params();
}

1;
