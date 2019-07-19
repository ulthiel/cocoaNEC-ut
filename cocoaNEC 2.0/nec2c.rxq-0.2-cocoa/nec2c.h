/*
 * nec2.h - header file for nec2
 */

#include <complex.h>
#include <stdio.h>
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

#ifndef	TRUE
#define	TRUE	1
#endif

#ifndef	FALSE
#define	FALSE	0
#endif

/* commonly used complex constants */
#define	CPLX_00	(0.0+0.0fj)
#define	CPLX_01	(0.0+1.0fj)
#define	CPLX_10	(1.0+0.0fj)
#define	CPLX_11	(1.0+1.0fj)

/* common constants */
#define	PI		3.14159265358979
#define	POT		1.570796327
#define	TP		( PI *2.0 )
#define	PTP		0.6283185308
#define	TPJ		(0.0+6.283185308fj)
#define PI8     ( PI*8.0 )
#define PI10	( PI*10.0 )
#define	TA		1.745329252E-02
#define	TD		57.29577951
#define	ETA		376.73
#define	CVEL	299.7925
#define	RETA	2.654420938E-3
#define	TOSP	1.128379167
#define ACCS	1.E-12
#define	SP		1.772453851
#define	FPI		12.56637062
#define	CCJ		(0.0-0.01666666667fj)
#define	CONST1	(0.0+4.771341189fj)
#define	CONST2	4.771341188
#define	CONST3	(0.0-29.97922085fj)
#define	CONST4	(0.0+188.365fj)
#define	GAMMA	.5772156649
#define C1		-.02457850915
#define C2		.3674669052
#define C3		.7978845608
#define P10		.0703125
#define P20		.1121520996
#define Q10		.125
#define Q20		.0732421875
#define P11		.1171875
#define P21		.1441955566
#define Q11		.375
#define Q21		.1025390625
#define POF		.7853981635
#define MAXH	20
#define CRIT	1.0E-4
#define NM		131072
#define NTS		4
#define	SMIN	1.e-3

/* Replaces the "10000" limit used to */
/* identify segment/patch connections */
#define	PCHCON  100000


/* version of fortran source for the -v option */
#define		version "nec2c.rxq v0.2"

#include "misc.h"

#define cmplx(r, i) ((r)+(i)*CPLX_01)

/* somnec.c */
void	initSomnec() ;
void 	somnec(double epr, double sig, double fmhz);


