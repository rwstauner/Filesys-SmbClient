use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'  => 'Filesys::SmbClient',
    'VERSION_FROM' => 'SmbClient.pm',
    'LIBS'  => ['-lsmbclient'],
    'DEFINE'  => '',
    'INC'  => '',
    'MYEXTLIB' =>'lib/libAuthSamba$(LIB_EXT)'
);


sub MY::postamble {
        '
$(MYEXTLIB): lib/Makefile
	cd lib && $(MAKE) $(PASSTHRU)
        ';
        }


