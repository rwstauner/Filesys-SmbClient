use ExtUtils::MakeMaker;

my ($define, $ccfl);

# special flag for AIX
($^O =~ m/AIX/i) ? ($ccfl = '-qcpluscmt') : ($ccfl = '');

# path libsmbclient.h
my $include = prompt("Where can I find libsmbclient.h ?","/usr/include");
warn_user("$include/libsmbclient.h") if (!-r "$include/libsmbclient.h");

# path libsmbclient.so
my $lib = prompt("Where can I find libsmbclient.so ?","/usr/lib");
warn_user("libsmbclient.so") if (!-r "$lib/libsmbclient.so");

# tests demande ?
my $ans = 
  prompt("Do you want make tests ?(you will be prompted for server / \n".
	   "worgroup / share / user / password to make read write access.",
	   "yes");
if ($ans =~ /^y(es)?$/i) 
  {
    my $server = prompt("Server ?","localhost");
    my $share = prompt("Share ?","homes");
    my $workgroup = prompt("Workgroup/Domain ?","");
    my $user = prompt("Smb user ?",$ENV{'USER'});
    my $pass = prompt("Smb password ?");
    open(FILE,">.c") || warn "Can't create .c for test: $!\n";
    print FILE $server,"\t",$share,"\t",$workgroup,"\t",$user,"\t",$pass;
    close FILE;
  }

# Trace for debug
$ans = prompt("Compile module with trace to STDERR ?", "no");
if ($ans =~ /^y(es)?$/i) { $define = "-DVERBOSE"; }

# Create config.h for alloca via configure
system("./configure") == 0 or die "Can't run configure:$!\n";

# Create makefile
WriteMakefile(
		  'NAME'         => 'Filesys::SmbClient',
		  'VERSION_FROM' => 'SmbClient.pm',
		  'INC'          => "-I$include",
		  'DEFINE'       => $define,
		  'DIR'          => 'lib',
		  'LIBS'         => ["-L$lib -lsmbclient"],
		  'MYEXTLIB'     => 'lib/libAuthSamba$(LIB_EXT)',
		  'CCFLAGS'      => $ccfl
		 );

sub MY::postamble
  {
    return	'
$(MYEXTLIB): lib/Makefile
	cd lib && $(MAKE) all
';
  }

sub warn_user
  {
    my $file = $_[0];
    warn <<EOF;
*************************************************************
** WHAT !!!!
** I Can't find $file : $!. 
*************************************************************
If you don't have this file you can download last version
of Samba on www.samba.org and do:

\$ tar zxvf samba-2.2.x.tar.gz
\$ cd samba-2.2.x/source
\$ ./configure
\$ make bin/libsmbclient.so

Then you can find libsmbclient.h in source/include directory and
libsmbclient.so in source/bin directory. You can then put them in
/usr/include and /usr/lib (or /usr/local/include and 
/usr/local/lib)

EOF

  }
