//
//  NCGeometry.m
//  cocoaNEC
//
//  Created by Kok Chen on 5/4/12.
//	-----------------------------------------------------------------------------
//  Copyright 2012-2016 Kok Chen, W7AY. 
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

#import "NCGeometry.h"


@implementation NCGeometry

+ (WireCoord)addCoord:(WireCoord*)delta toCoord:(WireCoord*)coord
{
	WireCoord result ;
	
	result.x = coord->x + delta->x ;
	result.y = coord->y + delta->y ;
	result.z = coord->z + delta->z ;
	
	return result ;
}

+ (WireCoord)subtractCoord:(WireCoord*)delta fromCoord:(WireCoord*)coord
{
	WireCoord result ;
	
	result.x = coord->x - delta->x ;
	result.y = coord->y - delta->y ;
	result.z = coord->z - delta->z ;
	
	return result ;
}

//  v0.92
+ (WireCoord)midpointBetweenCoord:(WireCoord*)w1 andCoord:(WireCoord*)w2
{
	WireCoord result ;
	
	result.x = 0.5*( w1->x + w2->x ) ;
	result.y = 0.5*( w1->y + w2->y ) ;
	result.z = 0.5*( w1->z + w2->z ) ;
	
	return result ;
}



+ (WireCoord)scaleCoord:(WireCoord*)coord factor:(double)r
{
	WireCoord result ;
	
	result.x = coord->x * r ;
	result.y = coord->y * r ;
	result.z = coord->z * r ;
	
	return result ;
}

//	scale WireCoord to the given length
+ (WireCoord)scaleCoord:(WireCoord*)coord toLength:(double)r
{
	return [ NCGeometry scaleCoord:coord factor:r/[ NCGeometry magnitudeOfCoord:coord ] ] ;
}

+ (double)distanceBetweenCoord:(WireCoord*)coord1 andCoord:(WireCoord*)coord2
{
	double dx, dy, dz ;
	
	dx = coord2->x - coord1->x ;
	dy = coord2->y - coord1->y ;
	dz = coord2->z - coord1->z ;
	
	return sqrt( dx*dx + dy*dy + dz*dz ) ;
}

+ (double)magnitudeOfCoord:(WireCoord*)coord
{
	double dx, dy, dz ;
	
	dx = coord->x ;
	dy = coord->y ;
	dz = coord->z ;
	
	return sqrt( dx*dx + dy*dy + dz*dz ) ;
}

+ (double)dotProduct:(WireCoord*)coord1 withCoord:(WireCoord*)coord2
{
	return ( coord1->x*coord2->x + coord1->y*coord2->y + coord1->z*coord2->z ) ; 
}

+ (WireCoord)crossProduct:(WireCoord*)coord1 withCoord:(WireCoord*)coord2
{
	WireCoord result ;
	
	result.x = coord1->y * coord2->z - coord1->z*coord2->y ;
	result.y = coord1->z * coord2->x - coord1->x*coord2->z ;
	result.z = coord1->x * coord2->y - coord1->y*coord2->x ;
	
	return result ;
}

//	return end:1 or end:2
- (WireCoord*)end:(int)which
{
	return ( which == 2 ) ? &end2 : &end1 ;
}

- (WireCoord*)end1
{
	return &end1 ;
}

- (void)setEnd1:(WireCoord*)coord
{
	end1 = *coord ;
}

- (void)setEnd1FromVector:(NCVector*)vector 
{
	end1.x = [ vector x ] ;
	end1.y = [ vector y ] ;
	end1.z = [ vector z ] ;
}

- (WireCoord*)end2
{
	return &end2 ;
}

- (void)setEnd2:(WireCoord*)coord
{
	end2 = *coord ;
}

- (void)setEnd2FromVector:(NCVector*)vector 
{
	end2.x = [ vector x ] ;
	end2.y = [ vector y ] ;
	end2.z = [ vector z ] ;
}

- (WireCoord)coordAtFraction:(double)fraction displacement:(double)displacement
{
	WireCoord result ;
	double a ;
	
	if ( fraction < 0 ) fraction = 0 ; else if ( fraction > 1 ) fraction = 1 ;
	a = 1 - fraction ;
	
	result.x = end1.x*a + end2.x*fraction + displacement ;
	result.y = end1.y*a + end2.y*fraction + displacement ;
	result.z = end1.z*a + end2.z*fraction + displacement ;
	
	return result ;
}

- (WireCoord)coordAtFraction:(double)fraction
{
	return [ self coordAtFraction:fraction displacement:0.0 ] ;
}

//  v0.81
- (WireCoord)midpointWithDisplacement:(double)displacement	
{
	return [ self coordAtFraction:0.5 displacement:displacement ] ;
}

//	midpoint of (end1, end2)
- (WireCoord)midpoint
{
	return [ self midpointWithDisplacement:0.0 ] ;
}

//	vector that runs from end1 to end2.
- (WireCoord)span
{
	WireCoord result ;
	
	result.x = ( end2.x-end1.x ) ;
	result.y = ( end2.y-end1.y ) ;
	result.z = ( end2.z-end1.z ) ;
	return result ;
}

//  vector end2-end1 scaled to given length
- (WireCoord)spanWithLength:(double)length
{
	WireCoord p ;
	double ratio ;
	
	ratio = length/( [ self length ] + 1.0e-12 ) ;
	p = [ self span ] ;
	p.x *= ratio ;
	p.y *= ratio ;
	p.z *= ratio ;
	return p ;
}

- (double)length
{
	double dx, dy, dz ;
	
	dx = ( end2.x - end1.x ) ;
	dy = ( end2.y - end1.y ) ;
	dz = ( end2.z - end1.z ) ;
	return sqrt( dx*dx + dy*dy + dz*dz ) ;
}

- (id)initWithEnd1:(WireCoord*)e1 end2:(WireCoord*)e2
{
	self = [ super init ] ;
	if ( self ) {
		[ self setEnd1:e1 ] ;
		[ self setEnd2:e2 ] ;
	}
	return self ;
}

+ (id)geometryWithEnd1:(WireCoord*)e1 end2:(WireCoord*)e2
{
	return [ [ [ NCGeometry alloc ] initWithEnd1:e1 end2:e2 ] autorelease ] ;
}

+ (id)geometryFromCoord:(WireCoord*)e1 delta:(WireCoord*)delta
{
	WireCoord end2 ;
	
	end2 = [ NCGeometry addCoord:delta toCoord:e1 ] ;
	return [ NCGeometry geometryWithEnd1:e1 end2:&end2 ] ;
}

- (id)geometryFrom:(double)start to:(double)end
{
	WireCoord e1, e2 ;
	
	e1 = [ self coordAtFraction:start ] ;
	e2 = [ self coordAtFraction:end ] ;
	return [ [ [ NCGeometry alloc ] initWithEnd1:&e1 end2:&e2 ] autorelease ] ;
}

- (void)shortenEndsBy:(double)delta
{
	double length, ratio, t ;
	
	length = [ self length ] ;
	
	if ( length < ( 2*delta + 0.02 ) ) delta = length/2 - 0.01 ;
	
	ratio = delta/length ;
	t = ( end2.x - end1.x )*ratio ;
	end1.x += t ;
	end2.x -= t ;
	t = ( end2.y - end1.y )*ratio ;
	end1.y += t ;
	end2.y -= t ;
	t = ( end2.z - end1.z )*ratio ;
	end1.z += t ;
	end2.z -= t ;
	
}

@end
