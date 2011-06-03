void set_fn(const char *workgroup,
	    const char *username,
	    const char *password);

void auth_fn(const char *server, 
	     const char *share,
	     char *workgroup, int wgmaxlen,
	     char *username, int umaxlen,
	     char *password, int pwmaxlen);

