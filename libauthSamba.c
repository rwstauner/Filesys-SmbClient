#include <stdio.h>
#include <string.h>
#include "libauthSamba.h"

char User[30];
char Password[30];
char Workgroup[30];

inline void
lstrncpy(char *d, const char *s, size_t n)
{
  strncpy(d, s, n);
  if (n > 0)
    d[n - 1] = '\0';
}

/*-----------------------------------------------------------------------------
 * set_fn
 *---------------------------------------------------------------------------*/
void set_fn(const char *workgroup,
	    const char *username,
	    const char *password)
{  
#ifdef VERBOSE
  printf("set_fn\n");
#endif

  lstrncpy(User, username, sizeof(User));
  lstrncpy(Password, password, sizeof(Password));
  lstrncpy(Workgroup, workgroup, sizeof(Workgroup));
}

/*-----------------------------------------------------------------------------
 * auth_fn
 *---------------------------------------------------------------------------*/
void auth_fn(const char *server, 
	     const char *share,
	     char *workgroup, int wgmaxlen,
	     char *username, int unmaxlen,
	     char *password, int pwmaxlen)
{
#ifdef VERBOSE
  printf("auth_fn\n");
#endif

  lstrncpy(workgroup, Workgroup, wgmaxlen);
  lstrncpy(username, User, unmaxlen);
  lstrncpy(password, Password, pwmaxlen);

#ifdef VERBOSE
  fprintf(stdout, "username: [%s]\n", username);
  fprintf(stdout, "password: [%s]\n", password);
  fprintf(stdout, "workgroup: [%s]\n", workgroup);
#endif
}
