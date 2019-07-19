//
//  CubicUV.m
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

#import "CubicUV.h"


@implementation CubicUV

//	Determine arc defined by three points, return NO if arc is not good estimate of path.
//	see http://mathworld.wolfram.com/Circle.html
static float circleDeterminant( float a, float b, float c, float d, float e, float f, float g, float h, float i )
{
	return ( a*(e*i-h*f) - d*(b*i-h*c) + g*(b*f-e*c) ) ;
}

- (Boolean)arcCheckInner:(RXF*)rxf index:(int)index p0:(int)p0 checkLeft:(Boolean)checkLeft checkRight:(Boolean)checkRight
{
	float a, d, e, f, z1, z2, z3, r, start, end, diff ;
	float x1, y1, x2, y2, x3, y3, xt, yt, cx, cy, check, cross ;
	
	//  get three consecutive points, starting at p0, to extimate circle
	x1 = rxf[p0].uv.x ;
	y1 = rxf[p0].uv.y ;
	x2 = rxf[p0+1].uv.x ;
	y2 = rxf[p0+1].uv.y ;
	x3 = rxf[p0+2].uv.x ;
	y3 = rxf[p0+2].uv.y ;
	
	z1 = x1*x1 + y1*y1 ;
	z2 = x2*x2 + y2*y2 ;
	z3 = x3*x3 + y3*y3 ;
	
	a = circleDeterminant( x1, y1, 1, x2, y2, 1, x3, y3, 1 ) ;
	d = -circleDeterminant( z1, y1, 1, z2, y2, 1, z3, y3, 1 ) ;
	e = circleDeterminant( z1, x1, 1, z2, x2, 1, z3, x3, 1 ) ;
	f = -circleDeterminant( z1, x1, y1, z2, x2, y2, z3, x3, y3 ) ;
	
	// center and radius of circle that passes through the three points
	center[index].x = cx = -d*0.5/a ;
	center[index].y = cy = -e*0.5/a ;
	r = (d*d+e*e)/(4*a*a) - f/a ;
	if ( r <= 0 ) return NO ;
	radius[index] = sqrt( r ) ;
	check = 0.35*( radius[index] + 0.001 ) ;
	
	//  now check distance from center to the two adjacent points
	if ( checkLeft ) {
		xt = rxf[p0-1].uv.x - cx ;
		yt = rxf[p0-1].uv.y - cy ;
		r = sqrt( xt*xt + yt*yt ) ;
		if ( fabs( r - radius[index] ) > check ) return NO ; 
	}
	if ( checkRight ) {
		xt = rxf[p0+3].uv.x - cx ;
		yt = rxf[p0+3].uv.y - cy ;
		r = sqrt( xt*xt + yt*yt ) ;
		if ( fabs( r - radius[index] ) > check ) return NO ; 
	}
	//  find angles and arcs for needed segment (from index to index+1)
	x1 = rxf[index].uv.x ;
	y1 = rxf[index].uv.y ;
	x2 = rxf[index+1].uv.x ;
	y2 = rxf[index+1].uv.y ;
	theta[index] = start = atan2( y1-cy, x1-cx ) ;
	end = atan2( y2-cy, x2-cx ) ;
	diff = end-start ;
	if ( fabs( diff ) < .1 ) return NO ;
	
	//	compute cross product of two consecutive edges, to find direction
	x3 = rxf[index+2].uv.x ;
	y3 = rxf[index+2].uv.y ;
	cross = (x2-x1)*(y3-y2) - (y2-y1)*(x3-x2) ;
	if ( fabs( cross ) < 0.001 ) return NO ;         // v0.92 changed from 0.1

	if ( cross < 0 ) {
		//  counter clockwise, diff should be negative
		if ( diff > 0 ) diff = diff-3.1415926*2 ;
	}
	else {
		//  clockwise, diff should be positive
		if ( diff < 0 ) diff = 3.1415926*2 + diff ;
	}
	//	reduce to no more than one full rotation
	if ( diff > 3.1415926*2 ) diff -= 3.1415926*2 ; else if ( diff < -3.1415926*2 ) diff += 3.1415926*2 ;
	dTheta[index] = diff ;
	
	return YES ;
}

- (Boolean)arcCheck:(RXF*)rxf index:(int)index
{
	int first ;
	
	if ( n < 4 || index >= ( n-1 ) ) return NO ;		//  need at least 4 points

	first = ( index > n-3 ) ? ( n-3 ) : index ;
	return [ self arcCheckInner:rxf index:index p0:first checkLeft:( first > 0 ) checkRight:( ( first+3 ) < n ) ] ;
}

- (void)createInterpolants:(RXF*)rxf
{
	int i ;
	
	[ super createInterpolants:rxf ] ;
	//  now create circle estimates, invalidate the ones that are not part of a circular arc by setting radius to -1
	for ( i = 0; i < n; i++ ) {
		if ( [ self arcCheck:rxf index:i ] == NO ) {
            radius[i] = -1 ;
        }
	}
}

static void cubicRXtoUV( float r, float x, float *u, float *v )
{
    float d ;
    
    d = r*r + x*x + r*2 + 1 ;
    *u = ( r*r + x*x - 1 )/d ;
    *v = ( x*2 )/d ;
}


//	return UV point
//	use circle estimate if it has enough precision, otherwise use cubic spline on RX and then convert to UV
- (NSPoint)evaluate:(float)t
{
	int index ;
	float angle, R, X, U, V ;
	NSPoint result ;
	
    
	index = t ;
	t -= index ;
    
	if ( radius[index] >= 0 ) {
		//  use circle interpolation
		angle = theta[index] + dTheta[index]*t ;
		result.x = center[index].x + radius[index]*cos(angle) ;
		result.y = center[index].y + radius[index]*sin(angle) ;
	}
	else {
		//  use cubic interpolation, rescale parameter t
		t *= h[index] ;
		R = qa[index].x + ( qb[index].x + ( qc[index].x + qd[index].x*t )*t )*t ;
		X = qa[index].y + ( qb[index].y + ( qc[index].y + qd[index].y*t )*t )*t ;
        
		cubicRXtoUV( R, X, &U, &V ) ;
		result.x = U ;
		result.y = V ;
	}
    
	return result ;
}

@end
