#include "config.h"
/* AIX requires this to be the first thing in the file.  */
#ifndef __GNUC__
# if HAVE_ALLOCA_H
#  include <alloca.h>
# else
#  ifdef _AIX
 #pragma alloca
#  else
#   ifndef alloca /* predefined by HP cc +Olibcalls */
char *alloca ();
#   endif
#  endif
# endif
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libsmbclient.h"
#include "libauthSamba.h"
#include "config.h"

/* 
 * This file defines the functions interfacing with libsmbclient.so
 */

MODULE = Filesys::SmbClient    PACKAGE = Filesys::SmbClient
PROTOTYPES: ENABLE

SMBCCTX *
_init(user, password, workgroup, debug)
  char *user
  char *password  
  char* workgroup
  int debug
CODE:
/* 
 * Initialize things ... 
 */	
  SMBCCTX *context;
  context = smbc_new_context();
  if (!context) {
    XSRETURN_UNDEF;
  }
  smbc_setDebug(context, 0); // 4 gives a good level of trace
  set_fn(workgroup, user, password);
  smbc_setFunctionAuthData(context, auth_fn);
  smbc_setDebug(context, debug);
  if (smbc_init_context(context) == 0) {
    smbc_free_context(context, 1); 
    XSRETURN_UNDEF;
  }
  RETVAL = context; 
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient : "
	          "init %p context\n", context); 
#endif
OUTPUT:
  RETVAL

int
_free(context, forced)
  SMBCCTX *context
  int forced
CODE:
  RETVAL = smbc_free_context(context, forced);
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient : "
	          "free %p context %d\n", context, RETVAL);
#endif
OUTPUT:
  RETVAL

int
_set_flags(context, flag)
  SMBCCTX *context
  int flag
CODE:
/* 
 * Create directory fname
 *
 */
#ifdef HAVE_SMBCTXX_FLAG
    context->flags = flag;
#endif
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient : "
                  "_set_flags value %d\n", flag); 
#endif
  RETVAL = 1;
OUTPUT:
  RETVAL


int
_mkdir(context, fname, mode)
  SMBCCTX *context
  char *fname
  int mode
CODE:
  smbc_mkdir_fn mkdir_fn = smbc_getFunctionMkdir(context);
/* 
 * Create directory fname
 *
 */
  int returnValue = mkdir_fn(context, fname, mode);
  if (returnValue < 0) {
#ifdef VERBOSE
    fprintf(stderr, "*** Error Filesys::SmbClient : "
	            "mkdir %s directory : %s\n", fname, strerror(errno)); 
#endif
  }
  RETVAL = returnValue;
OUTPUT:
  RETVAL


int
_rmdir(context, fname)
  SMBCCTX *context
  char *fname
CODE:
/* 
 * Remove directory fname
 *
 */
  smbc_rmdir_fn rmdir_fn = smbc_getFunctionRmdir(context);
  int returnValue = rmdir_fn(context, fname);
  if (returnValue < 0) {
#ifdef VERBOSE
    fprintf(stderr, "*** Error Filesys::SmbClient : "
      	            "rmdir %s directory : %s\n", fname,strerror(errno));
#endif
  }
  RETVAL = returnValue;
OUTPUT:
  RETVAL


SMBCFILE*
_opendir(context, fname)
  SMBCCTX *context
  char *fname
CODE:
/* 
 * Open directory fname
 *
 */
  smbc_opendir_fn opendir_fn = smbc_getFunctionOpendir(context);
  SMBCFILE *file = opendir_fn(context, fname);
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient : _opendir: %#p\n", file); 
#endif
  if (!file) { 
#ifdef VERBOSE
    fprintf(stderr, "*** Error Filesys::SmbClient : "
                      "Error opendir %s : %s\n", fname, strerror(errno));
#endif
    XSRETURN_UNDEF;
  }
  RETVAL = file;
OUTPUT:
  RETVAL


int
_closedir(context, fd)
  SMBCCTX *context
  SMBCFILE *fd
CODE:
/* 
 * Close file descriptor for directory fd
 *
 */
  smbc_closedir_fn closedir_fn = smbc_getFunctionClosedir(context);
  int returnValue = closedir_fn(context, fd);
#ifdef VERBOSE
  if (returnValue < 0) { 
    fprintf(stderr, "*** Error Filesys::SmbClient : "
                    "Closedir : %s\n", strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


void
_readdir(context, fd)
  SMBCCTX *context
  SMBCFILE *fd
PREINIT:
/* 
 * Read file descriptor for directory fd and return file type, name and comment
 *
 */
  smbc_readdir_fn readdir_fn;
  struct smbc_dirent *dirp;
PPCODE:
  readdir_fn = smbc_getFunctionReaddir(context);
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient : _readdir: %d\n", fd); 
#endif
  dirp = readdir_fn(context, fd);
  if (! dirp) {
    XSRETURN_EMPTY;
  }
  XPUSHs(sv_2mortal(newSViv(dirp->smbc_type)));
  XPUSHs(sv_2mortal(newSVpvn(dirp->name, dirp->namelen)));
  XPUSHs(sv_2mortal(newSVpvn(dirp->comment, dirp->commentlen)));


int
_telldir(context, fd)
  SMBCCTX *context
  SMBCFILE *fd
CODE:
/* 
 * Get the curreent directory offset for directory fd
 *
 */
  smbc_telldir_fn telldir_fn = smbc_getFunctionTelldir(context);
  int returnValue = telldir_fn(context, fd);
#ifdef VERBOSE
  if (returnValue == -1) { 
    fprintf(stderr, "*** Error Filesys::SmbClient : "
                    "Telldir : %s\n", strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


int
_lseekdir(context, fd, offset)
  SMBCCTX *context
  SMBCFILE *fd
  int offset
CODE:
/* 
 * Lseek on directory for directory fd
 *
 */
  smbc_lseekdir_fn lseekdir_fn = smbc_getFunctionLseekdir(context);
  int returnValue = lseekdir_fn(context, fd, offset);
#ifdef VERBOSE
  if (returnValue == -1) { 
    fprintf(stderr, "*** Error Filesys::SmbClient : "
                    "Lseekdir : %s\n", strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


void
_stat(context, fname)
  SMBCCTX *context
  char *fname
PREINIT:
/* 
 * _stat(fname) : Get information about a file or directory.
 *
 */
  struct stat buf;
  smbc_stat_fn stat_fn;
  int returnValue;
PPCODE:
  stat_fn = smbc_getFunctionStat(context);
  returnValue = stat_fn(context, fname, &buf);
  if (returnValue != 0) {
#ifdef VERBOSE
    fprintf(stderr, "! Filesys::SmbClient : Stat: %s returns %s\n", fname, strerror(errno)); 
#endif
    XSRETURN_EMPTY;
  } else {
    XPUSHs(sv_2mortal(newSVuv(buf.st_dev)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_ino)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_mode)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_nlink)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_uid)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_gid)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_rdev)));
    XPUSHs(sv_2mortal(newSViv(buf.st_size)));
    XPUSHs(sv_2mortal(newSViv(buf.st_blksize)));
    XPUSHs(sv_2mortal(newSViv(buf.st_blocks)));
    XPUSHs(sv_2mortal(newSViv(buf.st_atime)));
    XPUSHs(sv_2mortal(newSViv(buf.st_mtime)));
    XPUSHs(sv_2mortal(newSViv(buf.st_ctime)));
  }


void
_fstat(context, fd)
  SMBCCTX *context
  SMBCFILE *fd
PREINIT:
/* 
 * Get information about a file or directory via a file descriptor.
 *
 */
  struct stat buf;
  smbc_fstat_fn fstat_fn;
  int returnValue;
PPCODE:
  fstat_fn = smbc_getFunctionFstat(context);
  returnValue = fstat_fn(context, fd, &buf);
  if (returnValue != 0) {
#ifdef VERBOSE
    fprintf(stderr, "! Filesys::SmbClient : Fstat: %#p returns %s\n", fd, strerror(errno)); 
#endif
    XSRETURN_EMPTY;
  } else {
    XPUSHs(sv_2mortal(newSVuv(buf.st_dev)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_ino)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_mode)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_nlink)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_uid)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_gid)));
    XPUSHs(sv_2mortal(newSVuv(buf.st_rdev)));
    XPUSHs(sv_2mortal(newSViv(buf.st_size)));
    XPUSHs(sv_2mortal(newSViv(buf.st_blksize)));
    XPUSHs(sv_2mortal(newSViv(buf.st_blocks)));
    XPUSHs(sv_2mortal(newSViv(buf.st_atime)));
    XPUSHs(sv_2mortal(newSViv(buf.st_mtime)));
    XPUSHs(sv_2mortal(newSViv(buf.st_ctime)));
  }
  

int
_rename(context, oname, nname)
  SMBCCTX *context
  char *oname
  char *nname
CODE:
/* 
 * Rename old file oname in nname
 *
 */
  smbc_rename_fn rename_fn = smbc_getFunctionRename(context);
  int returnValue = rename_fn(context, oname, context, nname);
  if (returnValue < 0) { 
#ifdef VERBOSE	
    fprintf(stderr, "*** Error Filesys::SmbClient : "
 		    "Rename %s in %s : %s\n", oname, nname, strerror(errno)); 
#endif
  }
  RETVAL = returnValue;
OUTPUT:
  RETVAL


SMBCFILE*
_open(context, fname, mode)
  SMBCCTX *context
  char *fname
  int mode
CODE:
/* 
 * Open file fname with perm mode
 *
 */	
  int flags; 
  int seek_end = 0;
  smbc_open_fn open_fn = smbc_getFunctionOpen(context);
  SMBCFILE *file;

  /* Mode >> */
  if ( (*fname != '\0') && (*(fname+1) != '\0') &&
     (*fname == '>') && (*(fname+1) == '>')) { 
    flags = O_WRONLY | O_CREAT | O_APPEND; 
    fname += 2; 
    seek_end = 1;
#ifdef VERBOSE
    fprintf(stderr, "! Filesys::SmbClient :"
	            "Open append %s : %s\n", fname); 
#endif
  /* Mode > */
  } else if ( (*fname != '\0') && (*fname == '>')) {
    flags = O_WRONLY | O_CREAT | O_TRUNC; fname++; 
  /* Mode < */
  } else if ( (*fname != '\0') && (*fname == '<')) {
    flags = O_RDONLY; fname++; 
  /* Mod < */
  } else {
    flags =  O_RDONLY;
  }

  file = open_fn(context, fname, flags, mode);	
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient :"
	          "Open %s return %#p\n", fname, file); 
#endif
  if (!file) {
#ifdef VERBOSE
     fprintf(stderr, "*** Error Filesys::SmbClient :"
                     "Open %s : %s\n", fname, strerror(errno)); 
#endif
    XSRETURN_UNDEF;
  } else {
    RETVAL = file;
  }
OUTPUT:
  RETVAL


int
_read(context, fd, bufsv, count, offset)
  SMBCCTX *context
  SMBCFILE *fd
  SV *bufsv
  int count
  int offset
CODE:
/* 
 * Read count bytes on file descriptor fd
 *
 */
  smbc_read_fn read_fn = smbc_getFunctionRead(context);
  char *buf;
  STRLEN blen;
  int returnValue;

  if (count < 0)
    croak("Negative count");

  if (!SvOK(bufsv))
    sv_setpvn(bufsv, "", 0);
  (void)SvPV_force(bufsv, blen);

  if (offset < 0) {
    if ((unsigned) -offset > blen)
      croak("Offset beyond end");
    offset += blen;
  } else if ((unsigned) offset > blen)
    offset = blen;

  buf = SvGROW(bufsv, (unsigned) (count + offset)) + offset;

  returnValue = read_fn(context, fd, buf, count);
#ifdef VERBOSE
  if (returnValue <= 0) {
    fprintf(stderr, "*** Error Filesys::SmbClient: "
                    "Read %#p : %s\n", bufsv, strerror(errno)); 
  }
#endif
  if (returnValue > 0) {
    SvCUR_set(bufsv, offset + returnValue);
    (void)SvPOK_only(bufsv);
  }
  RETVAL = returnValue;
OUTPUT:
  RETVAL

int
_write(context, fd, bufsv, count, offset)
  SMBCCTX *context
  SMBCFILE *fd
  SV *bufsv
  int count
  int offset
CODE:
/* 
 * Write buf on file descriptor fd
 *
 */
  smbc_write_fn write_fn = smbc_getFunctionWrite(context);
  char *buf;
  STRLEN blen;
  int returnValue;

  if (count < 0)
    croak("Negative count");

  SvPV_const(bufsv, blen);

  if (offset < 0) {
    if ((unsigned) -offset > blen)
      croak("Offset beyond end");
    offset += blen;
  } else if ((unsigned) offset > blen)
    offset = blen;

  if ((unsigned) (offset + count) > blen)
    count = blen - offset;

  buf = SvPVX(bufsv) + offset;

  returnValue = write_fn(context, fd, buf, count);
#ifdef VERBOSE
  fprintf(stderr, "! Filesys::SmbClient :"
	          "write %d bytes: %s\n", count, buf);	
  if (returnValue < 0) { 
    if (errno == EBADF) 
      fprintf(stderr, "*** Error Filesys::SmbClient: "
		      "write fd invalid\n");
    else if (errno == EINVAL) 
      fprintf(stderr, "*** Error Filesys::SmbClient: "
	              "write param invalid\n");
    else 
      fprintf(stderr, "*** Error Filesys::SmbClient: "
	               "write %d : %s\n", fd, strerror(errno)); 
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL

int 
_lseek(context, fd,offset,whence)
  SMBCCTX *context
  SMBCFILE *fd
  int offset
  int whence
CODE:
  smbc_lseek_fn lseek_fn = smbc_getFunctionLseek(context);
  int returnValue = lseek_fn(context, fd, offset, whence);
#ifdef VERBOSE
  if (returnValue == -1) { 
    if (errno == EBADF) 
       fprintf(stderr, "*** Error Filesys::SmbClient: "
                       "lseek fd not open\n");
    else if (errno == EINVAL) 
       fprintf(stderr, "*** Error Filesys::SmbClient: "
	   	      "smbc_init not called or fd not a filehandle\n");
    else 
       fprintf(stderr, "*** Error Filesys::SmbClient: "
	               "write %#p : %s\n", fd, strerror(errno)); 
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL

int
_ftruncate(context, fd, size)
  SMBCCTX *context
  SMBCFILE *fd
  int size
CODE:
  smbc_ftruncate_fn ftruncate_fn = smbc_getFunctionFtruncate(context);
  int returnValue = ftruncate_fn(context, fd, size);
#ifdef VERBOSE
  if (returnValue < 0) {
    if (returnValue == EBADF)
      fprintf(stderr, "*** Error Filesys::SmbClient: "
                      "ftruncate fd not open\n");
    else if (returnValue == EINVAL)
      fprintf(stderr, "*** Error Filesys::SmbClient: "
                      "smbc_init not called or fd not a filehandle\n");
    else
      fprintf(stderr, "*** Error Filesys::SmbClient: "
                      "ftruncate %#p : %s\n", fd, strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL

int
_close(context, fd)
  SMBCCTX *context
  SMBCFILE *fd
CODE:
/* 
 * Close file desriptor fd
 *
 */
  smbc_close_fn close_fn = smbc_getFunctionClose(context);
  int returnValue = close_fn(context, fd);
#ifdef VERBOSE
  if (returnValue) {
    fprintf(stderr, "*** Error Filesys::SmbClient: Close %s\n",
                    stderror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


int
_unlink(context, fname)
  SMBCCTX *context
  char *fname
CODE:
/* 
 * Remove file fname
 *
 */
  smbc_unlink_fn unlink_fn = smbc_getFunctionUnlink(context);
  int returnValue = unlink_fn(context, fname);
  if (returnValue < 0) { 
#ifdef VERBOSE	
  fprintf(stderr, "*** Error Filesys::SmbClient: Failed to unlink %s : %s\n", 
          fname, strerror(errno)); 
#endif
  }
  RETVAL = returnValue;
OUTPUT:
  RETVAL


int
_unlink_print_job(context, purl, id)
  SMBCCTX *context
  char *purl
  int id
CODE:
  smbc_unlink_print_job_fn unlink_pj_fn = smbc_getFunctionUnlinkPrintJob(context);
  int returnValue = unlink_pj_fn(context, purl, id);
#ifdef VERBOSE
  if (returnValue < 0) {
    fprintf(stderr, "*** Error Filesys::SmbClient: "
	            "Failed to unlink job id %u on %s, %s\n",
                    id, purl, strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


int
_print_file(context, fname, c_print, printq)
  SMBCCTX *context
  char *fname
  SMBCCTX *c_print
  char *printq
CODE:
  smbc_print_file_fn print_file_fn = smbc_getFunctionPrintFile(context);
  int returnValue = print_file_fn(context, fname, c_print, printq);
#ifdef VERBOSE
  if (returnValue < 0) {
    fprintf(stderr, "*** Error Filesys::SmbClient *** "
		    "Failed to print file %s on %s, %s\n", 
	            fname, printq, strerror(errno));
  }
#endif
  RETVAL = returnValue;
OUTPUT:
  RETVAL


#if 0

void
_utimes(context, fname)
  SMBCCTX *context
  char *fname
PREINIT:
/* 
 * Get the access and modification times on a file
 *
 */
  struct timeval tbuf[2];
  smbc_utimes_fn utimes_fn;
  int returnValue;
PPCODE:
  bzero(tbuf, sizeof(tbuf));
  utimes_fn = smbc_getFunctionUtimes(context);
  returnValue = utimes_fn(context, fname, tbuf);
  if (returnValue != 0) {
#ifdef VERBOSE
    fprintf(stderr, "! Filesys::SmbClient : Utimes : %#p returns %s\n", fd, strerror(errno)); 
#endif
    XSRETURN_EMPTY;
  } else {
    XPUSHs(sv_2mortal(newSVuv(tbuf[0].tv_sec)));
    XPUSHs(sv_2mortal(newSVuv(tbuf[1].tv_sec)));
  }

#endif
