/*
 *  nec2cquad.m
 *  cocoaNEC
 *
 *  Created by Kok Chen on 7/30/07.
 */

//  This generates a quad precision version of nec2c (in nec2common.m)
//  Its companion, for generating double precision persion of nec2c is nec2cdouble.m.

#define GENERATE_QUAD_NEC


#include <complex.h>

typedef long double doubletype ;
typedef long double complex complextype ;
#define	stopproc( flag )	stopnec( flag )
#define	crealx( v )			( creall( v ) )
#define	cimagx( v )			( cimagl( v ) )


int necmain() ;

static void 	test(doubletype f1r, doubletype f2r, doubletype *tr, doubletype f1i, doubletype f2i, doubletype *ti, doubletype dmin);
static void 	testdouble(double f1r, double f2r, double *tr, double f1i, double f2i, double *ti, double dmin);

#include "nec2common.m"

