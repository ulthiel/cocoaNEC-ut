/*
 *  nec2cdouble.m
 *  cocoaNEC
 *
 *  Created by Kok Chen on 7/30/07.
 */


//  This generates a double precision version of nec2c (in nec2common.m)
//  Its companion, for generating quad precision persion of nec2c is nec2c.m.

#define GENERATE_DOUBLE_NEC

#include <complex.h>

typedef double doubletype ;
typedef double complex complextype ;


#define	stopproc( flag )	stopnec( flag )
//  define as creal() for double precision
#define	crealx( v )			( creal( v ) )
#define	cimagx( v )			( cimag( v ) )


#include "nec2common.m"

