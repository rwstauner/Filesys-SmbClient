#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libsmbclient.h"
#include "auth.h"

MODULE = Filesys::SmbClient    PACKAGE = Filesys::SmbClient
PROTOTYPES: ENABLE

int
_init(wgroup,debug)
  char* wgroup
  int debug
    CODE:
      RETVAL = smbc_init(auth_fn, wgroup,  debug ); /* Initialize things */
      if (RETVAL < 0)
        {
        fprintf(stderr, "Initializing the smbclient library ...: %s\n", strerror(errno));
        }
    OUTPUT:
      RETVAL

int
_unlink(fname)
  char *fname
    CODE:
      RETVAL = smbc_unlink(fname);
    OUTPUT:
      RETVAL

int
_mkdir(fname,mode)
  char *fname
  int mode
    CODE:
      RETVAL = smbc_mkdir(fname,mode);
      if (RETVAL < 0)
        {
        fprintf(stderr, "mkdir %s directory : %s\n", fname,strerror(errno));
        }
    OUTPUT:
      RETVAL

void
_stat(fname)
  char *fname
           INIT:
                int i;
                struct stat buf;
           PPCODE:
                i = smbc_stat(fname, &buf);
                if (i == 0) {
                        XPUSHs(sv_2mortal(newSVnv(buf.st_dev)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_ino)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_mode)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_nlink)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_uid)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_gid)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_rdev)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_size)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_blksize)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_blocks)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_atime)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_mtime)));
                        XPUSHs(sv_2mortal(newSVnv(buf.st_ctime)));
                } else {
                        XPUSHs(sv_2mortal(newSVnv(errno)));
                        }

int
_rename(oname,nname)
  char *oname
  char *nname
    CODE:
      RETVAL = smbc_rename(oname,nname);
      if (RETVAL < 0)
        {
        fprintf(stderr, "Rename %s in %s : %s\n", oname, nname, strerror(errno));
        }
    OUTPUT:
      RETVAL

int
_open(fname, flags, mode)
  char *fname
  int flags
  int mode
    CODE:
      RETVAL = smbc_open(fname,flags,mode);
      if (RETVAL < 0)
        {
        fprintf(stderr, "Open %s : %s\n", fname, strerror(errno));
        }
    OUTPUT:
      RETVAL

char*
_read(fd,count)
  int fd
  int count
    CODE:
     char *buf;
     int returnValue;
     buf=(char *) malloc (count);
     returnValue = smbc_read(fd,buf,count);
     buf[returnValue]='\0';
     if (returnValue < 0)
        {
        fprintf(stderr, "Read %s : %s\n", buf, strerror(errno));
        }
     if (returnValue==0) {RETVAL=NULL;}
     else {RETVAL=buf;}
    OUTPUT:
      RETVAL

int
_write(fd,buf)
  int fd
  char *buf
    CODE:
      RETVAL=smbc_write(fd,buf,sizeof(buf));
      if (RETVAL < 0)
        {
        fprintf(stderr, "write %d : %s\n", fd, strerror(errno));
        }
    OUTPUT:
      RETVAL

int
_close(fd)
  int fd
    CODE:
      RETVAL=smbc_close(fd);
    OUTPUT:
      RETVAL
