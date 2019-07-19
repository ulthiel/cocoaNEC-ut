//
//  NCVector.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/1/09.
//	-----------------------------------------------------------------------------
//  Copyright 2009-2016 Kok Chen, W7AY. 
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

#import "NCVector.h"


@implementation NCVector

//	note: vector objects are owned by NCValue objects and are released by them

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		x = y = z = 0.0 ;
	}
	return self ;
}

- (id)initWithX:(float)ix y:(float)iy z:(float)iz
{
	self = [ super init ] ;
	if ( self ) {
		x = ix ;
		y = iy ;
		z = iz ;
	}
	return self ;
}

- (id)initWithVectorArray:(float*)ix
{
	self = [ super init ] ;
	if ( self ) {
		x = ix[0] ;
		y = ix[1] ;
		z = ix[2] ;
	}
	return self ;
}

- (id)initWithVector:(NCVector*)v
{
	self = [ super init ] ;
	if ( self ) {
		x = [ v x ] ;
		y = [ v y ] ;
		z = [ v z ] ;
	}
	return self ;
}

+ (NCVector*)vectorWithX:(float)ix y:(float)iy z:(float)iz
{
	NCVector *v ;
	
	v = [ [ NCVector alloc ] initWithX:ix y:iy z:iz ] ;
	[ v autorelease ] ;
	return v ;
}

+ (NCVector*)vectorWithArray:(float*)iv
{
	NCVector *v ;
	
	v = [ [ NCVector alloc ] initWithVectorArray:iv ] ;
	[ v autorelease ] ;
	return v ;
}

+ (NCVector*)vectorWithVector:(NCVector*)v
{
	NCVector *u ;
	
	u = [ [ NCVector alloc ] initWithVector:v ] ;
	[ u autorelease ] ;
	return u ;
}

+ (NCVector*)vectorWithVector:(NCVector*)v scale:(float)factor
{
	NCVector *u ;
	
	u = [ [ NCVector alloc ] initWithVector:v ] ;
	[ u scale:factor ] ;
	[ u autorelease ] ;
	return u ;
}

+ (NCVector*)vectorWithSum:(NCVector*)v to:(NCVector*)u
{
	NCVector *q ;
	
	q = [ [ NCVector alloc ] initWithVector:u ] ;
	[ q addVector:v ] ;
	[ q autorelease ] ;
	return q ;
}

+ (NCVector*)vectorWithDifference:(NCVector*)v from:(NCVector*)u
{
	NCVector *q ;
	
	q = [ [ NCVector alloc ] initWithVector:u ] ;
	[ q subtractVector:v ] ;
	[ q autorelease ] ;
	return q ;
}

- (void)scale:(float)factor
{
	x *= factor ;
	y *= factor ;
	z *= factor ;
}

- (void)addVector:(NCVector*)v
{
	x += [ v x ] ;
	y += [ v y ] ;
	z += [ v z ] ;
}

- (void)subtractVector:(NCVector*)v
{
	x -= [ v x ] ;
	y -= [ v y ] ;
	z -= [ v z ] ;
}

- (float)dotWithVector:(NCVector*)v 
{
	return x*[ v x ] + y*[ v y ] + z*[ v z ] ; 
}

- (float)length
{
	return sqrt( x*x + y*y + z*z ) ;
}

- (void)setX:(float)ix y:(float)iy z:(float)iz
{
	x = ix ;
	y = iy ;
	z = iz ;
}

- (float)component:(int)index
{
	switch ( index ) {
	case 0: return x ;
	case 1: return y ;
	case 2: return z ;
	}
	return 0 ;
}

- (float*)get:(float*)v
{
	array[0] = x ;
	array[1] = y ;
	array[2] = z ;
	if ( v ) {
		v[0] = x ;
		v[1] = y ;
		v[2] = z ;
	}
	return array ;
}

- (void)set:(float*)v
{
	x = v[0] ;
	y = v[1] ;
	z = v[2] ;
}

- (float)x 
{
	return x ;
}

- (void)setX:(float)v 
{
	x = v ;
}

- (float)y
{
	return y ;
}

- (void)setY:(float)v
{
	y = v ;
}

- (float)z
{
	return z ;
}

- (void)setZ:(float)v
{
	z = v ;
}

@end
