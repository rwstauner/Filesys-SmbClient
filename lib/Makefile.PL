use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
            NAME   => 'Filesys::Smbclient::libauthSamba',
            clean  => {'FILES' => 'libAuthSamba$(LIB_EXT)'},
        );        

sub MY::top_targets {
                '
all :: static

pure_all :: static

static :: libAuthSamba$(LIB_EXT)

libAuthSamba$(LIB_EXT): $(O_FILES)
	$(AR) cr libAuthSamba$(LIB_EXT) $(O_FILES)
	$(RANLIB) libAuthSamba$(LIB_EXT)
        ';
        }
