//
//  Quadratic.m
//  cocoaNEC v0.70
//
//  Created by Kok Chen on 4/11/11.
//	-----------------------------------------------------------------------------
//  Copyright 2011-2016 Kok Chen, W7AY. 
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//	-----------------------------------------------------------------------------

#import "Quadratic.h"


@implementation Quadratic

//	Quadratic spline interpolation

//	Input is assumed to be equal spaced, output is y[0], y[1], ... y[points-1]
- (id)initWithNumberOfPoints:(int)points
{
	
    self = [ super initWithNumberOfPoints:points z0:50 ] ;
	if ( self ) {
		qa = ( NSPoint* )malloc( sizeof( NSPoint )*n ) ;
		qb = ( NSPoint* )malloc( sizeof( NSPoint )*n ) ;
		qc = ( NSPoint* )malloc( sizeof( NSPoint )*n ) ;
		z = ( float* )malloc( sizeof( float )*n ) ;
	}
	return self ;
}

- (void)dealloc
{
	free( qa ) ;
	free( qb ) ;
	free( qc ) ;
	free( z ) ;
	[ super dealloc ] ;
}

//	assume equi-spaced data points (h_i = 1 for all i)
//	Compute the cubic coeffienets (a,b,c,d) for each spline segment
//	Note component must be 0 or 1
- (void)computeQuadraticCoefficients:(NSPoint*)pdata component:(int)p
{
	int i, j ;
	CGFloat *a, *b, *c, *data ;
	
	a = ( (CGFloat*)qa ) + p ;
	b = ( (CGFloat*)qb ) + p ;
	c = ( (CGFloat*)qc ) + p ;
	data = ( (CGFloat*)pdata ) + p ;
	
	for ( i = 0; i < n*2; i += 2 ) a[i] = data[i] ;
	z[0] = 0 ;
	for ( i = 0; i < n-1; i++ ) {
		j = i*2 ;
		z[i+1] = -z[i] + 2*( a[j+2]-data[j] ) ;
	}
	
	for ( i = 0; i < n-1; i++ ) {
		j = i*2 ;
		b[j] = z[i] ;
		c[j] = ( z[i+1]-z[i] )*0.5 ;
		
		printf( "Component %d: a[%d] = %f b[%d] = %f  (a+b+c)[%d] = %f (2c+b)[%d] = %f\n", p, i, a[j], i, b[j], i, a[j]+b[j]+c[j], i, 2*c[j]+b[j] ) ;
	}
	b[n*2-2] = z[n-1] ;
	c[n*2-2] = 0 ;
}

- (NSPoint)evaluate:(float)t
{
	int i ;
	NSPoint result ;
	
	i = t ;
	t -= i ;
	result.x = qa[i].x + ( qb[i].x + qc[i].x*t )*t ;
	result.y = qa[i].y + ( qb[i].y + qc[i].y*t )*t ;
	
	return result ;
}


@end
