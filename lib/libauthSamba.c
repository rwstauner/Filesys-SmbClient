#include <stdio.h>
#include "auth.h"

void auth_fn(char *server, char *share,
       char **workgroup, char **username, char **password)
{
  static char wg[128], un[128], pw[128];
  /* DO nothing for now ... change later */

  fprintf(stdout, "Enter workgroup: ");
  fgets(wg, sizeof(wg), stdin);

  if (wg[strlen(wg) - 1] == 0x0a) /* A new line? */
    wg[strlen(wg) - 1] = 0x00;

  fprintf(stdout, "Enter username: ");
  fgets(un, sizeof(un), stdin);

  if (un[strlen(un) - 1] == 0x0a) /* A new line? */
    un[strlen(un) - 1] = 0x00;

  fprintf(stdout, "Enter password: ");
  fgets(pw, sizeof(pw), stdin);

  if (pw[strlen(pw) - 1] == 0x0a) /* A new line? */
    pw[strlen(pw) - 1] = 0x00;

  *workgroup = wg; *password = pw; *username = un;

}
