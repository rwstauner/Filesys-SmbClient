#pragma alloca
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libsmbclient.h"
#include "lib/libauthSamba.h"

/* 
 * Ce fichier definit les fonctions d'interface avec libsmbclient.so 
 */

MODULE = Filesys::SmbClient    PACKAGE = Filesys::SmbClient
PROTOTYPES: ENABLE

int
_init(user, password, workgroup, debug)
  char *user
  char *password  
  char* workgroup
  int debug
    CODE:
/* 
 * Initialize things ... 
 */	
	set_fn(workgroup, user, password);
      RETVAL = smbc_init(auth_fn, debug ); 

      if (RETVAL < 0)
       	{
	RETVAL = 0;
#ifdef VERBOSE
	fprintf(stderr, 
		"Initializing the smbclient library ...: %s\n", 
	        strerror(errno));
#endif
        }
    OUTPUT:
      RETVAL



int
_mkdir(fname,mode)
  char *fname
  int mode
    CODE:
/* 
 * _mkdir(char *fname, int mode) : Create directory fname
 *
 */
      RETVAL = smbc_mkdir(fname,mode);

      if (RETVAL < 0)
        {
	RETVAL = 0;
#ifdef VERBOSE
	fprintf(stderr, "mkdir %s directory : %s\n", fname,strerror(errno)); 
#endif
	}
      else RETVAL = 1;
    OUTPUT:
      RETVAL



int
_rmdir(fname)
  char *fname
    CODE:
/* 
 * _rmdir(char *fname) : Remove directory fname
 *
 */
      RETVAL = smbc_rmdir(fname);
      if (RETVAL < 0)
        {
	RETVAL = 0;
#ifdef VERBOSE
	fprintf(stderr, "rmdir %s directory : %s\n", fname,strerror(errno));
#endif
	}
       else RETVAL = 1;
    OUTPUT:
      RETVAL



int
_opendir(fname)
  char *fname
    CODE:
/* 
 * _opendir(char *fname) : Open directory fname
 *
 */
      RETVAL = smbc_opendir(fname);
#ifdef VERBOSE
      if (RETVAL<0) 
	{fprintf(stderr, "Error opendir %s : %s\n", fname, strerror(errno));}
#endif
    OUTPUT:
      RETVAL



int
_closedir(fd)
  int fd
    CODE:
/* 
 * _closedir(int fd) : Close file descriptor for directory fd
 *
 */
      RETVAL = smbc_closedir(fd);
#ifdef VERBOSE
      if (RETVAL < 0)
        { fprintf(stderr, "Closedir : %s\n", strerror(errno)); }
#endif
    OUTPUT:
      RETVAL


void
_readdir(fd)
  int fd
    	INIT:
/* 
 * _readdir(int fd) : Read file descriptor for directory fd and return file
 *                    name and type
 *
 */
       		struct smbc_dirent *dirp;
    	PPCODE:
         dirp = (struct smbc_dirent *)smbc_readdir(fd);
         if (dirp)
          {
          XPUSHs(sv_2mortal(newSVnv(dirp->smbc_type)));
          XPUSHs(sv_2mortal((SV*)newSVpv(dirp->name,strlen(dirp->name))));
          }


void
_stat(fname)
  char *fname
           INIT:
/* 
 * _stat(fname) : Get information about a file or directory.
 *
 */
                int i;
                struct stat buf;
           PPCODE:
             i = smbc_stat(fname, &buf);
             if (i == 0) 
		{
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
                } 
	   else 
		{
#ifdef VERBOSE
         	fprintf(stderr, "Stat: %s\n", strerror(errno)); 
#endif
                XPUSHs(sv_2mortal(newSVnv(0)));
                }

void
_fstat(fd)
  int fd
           INIT:
/* 
 * _fstat(fname) : Get information about a file or directory via 
 *                 a file descriptor.
 *
 */
                int i;
                struct stat buf;
           PPCODE:
                i = smbc_fstat(fd, &buf);
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
/* 
 * _rename(oname, nname) : Rename old file oname in nname
 *
 */
      RETVAL = smbc_rename(oname,nname);

      if (RETVAL < 0)
        { 
	RETVAL = 0;
#ifdef VERBOSE	
	fprintf(stderr, 
                  "Rename %s in %s : %s\n", 
                  oname, nname, strerror(errno)); 
#endif
	}
      else RETVAL = 1;
    OUTPUT:
      RETVAL


int
_open(fname, mode)
  char *fname
  int mode
    CODE:
/* 
 * _open(fname, mode): Open file fname with perm mode
 *
 */	
	int flags; int seek_end = 0;
	/* Mode >> */
	if ( (*fname != '\0') && (*(fname+1) != '\0') &&
		    (*fname == '>') && (*(fname+1) == '>'))
		{ 
			flags = O_WRONLY | O_CREAT | O_APPEND; 
			fname+=2; 
			seek_end = 1;
#ifdef VERBOSE
			fprintf(stderr, "Open append %s : %s\n", fname); 
#endif
		}
	/* Mode > */
	else if ( (*fname != '\0') && (*fname == '>')) 
		{ flags = O_WRONLY | O_CREAT | O_TRUNC; fname++; }
	/* Mode < */
	else if ( (*fname != '\0') && (*fname == '<')) 
		{ flags = O_RDONLY; fname++; }
	/* Mod < */
	else flags =  O_RDONLY;
      RETVAL = smbc_open(fname,flags, mode);	
      if (RETVAL < 0)
        { 
	RETVAL = 0;
#ifdef VERBOSE
	fprintf(stderr, "Open %s : %s\n", fname, strerror(errno)); 
#endif
	}
	else if (seek_end) { smbc_lseek(RETVAL, 0, SEEK_END); }
    OUTPUT:
      RETVAL


SV*
_read(fd,count)
  int fd
  int count
    CODE:
/* 
 * _read(fd, count): Read count bytes on file descriptor fd
 *
 */
     char *buf;
     int returnValue;
     buf = (char*)alloca(sizeof(char)*(count+1));
     returnValue = smbc_read(fd,buf,count);
     buf[returnValue]='\0';
#ifdef VERBOSE
     if (returnValue < 0)
        { fprintf(stderr, "Read %s : %s\n", buf, strerror(errno)); }
#endif
     if (returnValue==0) {RETVAL=&PL_sv_undef;}
     else {RETVAL=newSVpvn(buf,returnValue);}
    OUTPUT:
      RETVAL

int
_write(fd,buf,count)
  int fd
  char *buf
  int count
    CODE:
/* 
 * _write(fd, buf, lenght): Write buf on file descriptor fd
 *
 */
      RETVAL=smbc_write(fd,buf,count);
#ifdef VERBOSE
	fprintf(stderr, "write %d bytes: %s\n",count, buf);	
       	if (RETVAL < 0)
        { 
	if (RETVAL == EBADF) 
		fprintf(stderr, "write fd non valide\n");
	else if (RETVAL == EINVAL) 
		fprintf(stderr, "write param non valide\n");
	else fprintf(stderr, "write %d : %s\n", fd, strerror(errno)); 
	}
#endif
    OUTPUT:
      RETVAL


int
_close(fd)
  int fd
    CODE:
/* 
 * _close() : Close file desriptor fd
 *
 */
      RETVAL=smbc_close(fd);
    OUTPUT:
      RETVAL

int
_unlink(fname)
  char *fname
    CODE:
/* 
 * _unlink(char *fname) : Remove file fname
 *
 */
      RETVAL = smbc_unlink(fname);
      if (RETVAL < 0)
        { 
	RETVAL = 0;
#ifdef VERBOSE	
	fprintf(stderr, 
                "Failed to unlink %s : %s\n", 
                fname, strerror(errno)); 
#endif
	}
      else RETVAL = 1;

    OUTPUT:
      RETVAL


int
_unlink_print_job(purl, id)
  char *purl
  int id
    CODE:
/* 
 * _unlink_print_job : Remove job print no id on printer purl
 *
 */
      RETVAL = smbc_unlink_print_job(purl, id);
#ifdef VERBOSE
      if (RETVAL<0)
         fprintf(stderr, "Failed to unlink job id %u on %s, %s, %u\n", 
	         id, purl, strerror(errno), errno);
#endif
    OUTPUT:
      RETVAL


int
_print_file(purl, printer)
  char *purl
  char *printer
    CODE:
/* 
 * _print_file : Print url purl on printer purl
 *
 */
      RETVAL = smbc_print_file(purl, printer);
#ifdef VERBOSE
      if (RETVAL<0)
         fprintf(stderr, "Failed to print file %s on %s, %s, %u\n", 
	         purl, printer, strerror(errno), errno);
#endif
    OUTPUT:
      RETVAL