use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'  => 'Filesys::SmbClient',
    'VERSION_FROM' => 'SmbClient.pm',
    'LIBS'  => ['-lsmbclient'],
    'DEFINE'  => '',
    'INC'  => '',
    'MYEXTLIB' =>'auth/libAuthSamba$(LIB_EXT)'
);


sub MY::postamble {
        '
$(MYEXTLIB): auth/Makefile
	cd auth && $(MAKE) $(PASSTHRU)
        ';
        }


