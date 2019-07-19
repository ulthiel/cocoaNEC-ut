//
//  Interpolate.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/16/11.
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

#import "Interpolate.h"


@implementation Interpolate

//  input points for cubic interpolation, for the component 0 (r) or 1 (x)
- (void)makeInputs:(RXF*)rxf component:(int)component
{
	int i ;
	CGFloat *a ;
	
	a = ( (CGFloat*)qa ) + component ;
	
	if ( component == 0 ) {
		for ( i = 0; i < n; i++ ) {
			a[i*2] = rxf[i].rx.x ;
			x[i] = rxf[i].frequency ;
		}
	}
	else {
		for ( i = 0; i < n; i++ ) {
			a[i*2] = rxf[i].rx.y ;
			x[i] = rxf[i].frequency ;
		}
	}
}

- (void)createInterpolants:(RXF*)rxf
{
	// create cubic spline coeffients
	[ self computeCoefficients:rxf component:0 ] ;
	[ self computeCoefficients:rxf component:1 ] ;  
}

- (NSPoint)evaluate:(float)t
{
	return NSMakePoint( 0, 0 ) ;
}

//	Cubic spline interpolation
//	http://www.michonline.com/ryan/csc/m510/splinepresent.html
//	Compute the cubic coeffienets (a,b,c,d) for each spline segment
- (void)computeCoefficients:(RXF*)rxf component:(int)component
{
	int i, j ;
	CGFloat *a, *b, *c, *d ;
	float delta ;
	
	//  pointers for result (component is either 0 or 1)
	a = ( (CGFloat*)qa ) + component ;
	b = ( (CGFloat*)qb ) + component ;
	c = ( (CGFloat*)qc ) + component ;
	d = ( (CGFloat*)qd ) + component ;
	
	[ self makeInputs:rxf component:component ] ;
	
	for ( i = 0; i < n-1; i++ ) {
		delta = x[i+1]-x[i] ;
		if ( delta < 0.0001 ) delta = 0.0001 ;
		h[i] = delta ;
	}
	for ( i = 1; i < n-1; i++ ) {
		j = i*2 ;
		y[i] = 3*( ( a[j+2] - a[j] )/h[i] - ( a[j] - a[j-2] )/h[i-1] ) ;
	}
	l[0] = 1 ;
	u[0] = 0 ;
	z[0] = 0 ;
	for ( i = 1; i < n-1; i++ ) {
		l[i] = 2.0*( x[i+1] - x[i-1] ) - h[i-1]*u[i-1] ;
		u[i] = h[i]/l[i] ;
		z[i] = ( y[i] - h[i-1]*z[i-1] )/l[i] ;
	}
	i = n-1 ;
	l[i] = 1 ;
	z[i] = 0 ;
	c[i*2] = 0 ;
	for ( i = n-2; i >= 0; i-- ) {
		j = i*2 ;
		c[j] = z[i] - u[i]*c[j+2] ;
		b[j] = ( a[j+2] - a[j] )/h[i] - h[i]*( c[j+2] + 2*c[j] )/3.0 ;
		d[j] = ( c[j+2] - c[j] )/( 3.0*h[i] ) ;
	}
}

//	v0.73	heuristics to find average frequency gap for smart interpolation
//	moderately simple heuristics for now
- (float)frequencyGap:(RXF*)rxf
{
	int i ;
	float *delta, avg, df, largest, smallest ;
	
	if ( n <= 1 ) return 0 ;
	
	delta = (float*)malloc( n*sizeof( float ) ) ;
	avg = largest = 0 ;
	smallest = 1e12 ;
	for ( i = 0; i < n-1; i++ ) {
		df = rxf[i+1].frequency -rxf[i].frequency ;
		delta[i] = df ;
		avg += df ;
		if ( df > largest ) largest = df ;
		if ( df < smallest ) smallest = df ;
	}
	//  first check for a virtually gapless case
    if ( smallest < .001 || ( largest/smallest ) < 3.0 ) {
        free( delta ) ;
        return largest*1.01 ;
    }
	
	avg /= ( n-1 ) ;
	//  find largest non-gap delta f
	largest = 0 ;
	for ( i = 0; i < n-1; i++ ) {
		if ( delta[i] < avg ) {
			if ( delta[i] > largest ) largest = delta[i] ;
		}
	}
	free( delta ) ;
	return largest*1.01 ;
}

- (id)initWithNumberOfPoints:(int)points z0:(float)zref
{
	int psize, fsize ;
	
	self = [ super init ] ;
	if ( self ) {
		n = points ;
		z0 = zref ;
		psize = sizeof( NSPoint )*n ;
		fsize = sizeof( float )*n ;
		//  cubic coefficients (a,b,c,d) for each spline segment (n)
		qa = ( NSPoint* )malloc( psize ) ;
		qb = ( NSPoint* )malloc( psize ) ;
		qc = ( NSPoint* )malloc( psize ) ;
		qd = ( NSPoint* )malloc( psize ) ;
		center = ( NSPoint* )malloc( psize ) ;
		radius = ( float* )malloc( fsize ) ;
		theta = ( float* )malloc( fsize ) ;
		dTheta = ( float* )malloc( fsize ) ;
		x = ( float* )malloc( fsize ) ;
		y = ( float* )malloc( fsize ) ;
		l = ( float* )malloc( fsize ) ;
		u = ( float* )malloc( fsize ) ;
		z = ( float* )malloc( fsize ) ;
		h = ( float* )malloc( fsize ) ;
	}
	return self ;
}

- (id)init
{
	return [ self initWithNumberOfPoints:4 z0:50.0 ] ;
}

- (void)dealloc
{
	free( qa ) ;
	free( qb ) ;
	free( qc ) ;
	free( qd ) ;
	free( h ) ;
	free( x ) ;
	free( y ) ;
	free( l ) ;
	free( u ) ;
	free( z ) ;
	free( center ) ;
	free( radius ) ;
	free( theta ) ;
	free( dTheta ) ;
	[ super dealloc ] ;
}

@end
