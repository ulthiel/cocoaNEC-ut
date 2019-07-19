/*
 * nec2.h - header file for nec2
 */

/*
#include <complex.h>
#include <math.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <sys/types.h>
#include <sys/times.h>
*/

#include <stdio.h>


/* carriage return and line feed */
#define	CR	0x0d
#define	LF	0x0a

/* max length of a line read from input file */
#define	LINE_LEN	132

void 	usage(void);
void 	abort_on_error(int why);
void 	secnds(double *x);
int 	load_line(char *buff, FILE *pfile);
void	mem_alloc( void **ptr, int req );
void	mem_realloc( void **ptr, int req );
void	free_ptr( void **ptr );
