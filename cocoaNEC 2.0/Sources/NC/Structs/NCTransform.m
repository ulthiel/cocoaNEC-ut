//
//  NCTransform.m
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

#import "NCTransform.h"


@implementation NCTransform

#define	rad ( 3.14159265358979323/180.0 ) 

//  Affine transform implement using an augmented 4x4 matrix (http://en.wikipedia.org/wiki/Affine_transformation)
//	note: transform objects are owned by NCValue objects and are released by them.

- (id)initWithMatrix:(float*)m 
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		for ( i = 0; i < 16; i++ ) a[i] = m[i] ;
	}
	return self ;
}

//  make copy of the entire transform chain
- (id)initFromTransform:(NCTransform*)v
{
	[ self initWithMatrix:[ v matrix ] ] ;
	return self ;
}

- (id)initByConcatenating:(NCTransform*)transform1 toTransform:(NCTransform*)transform2
{
	float *u, *v, sum ;
	float m[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 } ;
	int i, j, k ;
	
	u = [ transform1 matrix ] ;
	v = [ transform2 matrix ] ;
	
	for ( i = 0; i < 4; i++ ) {
		for ( j = 0; j < 3; j++ ) {
			sum = 0 ;
			for ( k = 0; k < 4; k++ ) sum += u[k + j*4]*v[k*4 + i] ; 			
			m[i+j*4] = sum ;
		}
	}
	m[12] = m[13] = m[14] = 0 ;
	m[15] = 1 ;
	return [ self initWithMatrix:m ] ;
}

- (id)initWithIdentity 
{
	float m[] = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 } ;
	
	return [ self initWithMatrix:m ] ;
}

- (id)initWithScale:(float)scale
{
	float m[] = { scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1 } ;
	
	return [ self initWithMatrix:m ] ;
}

- (id)initWithTranslation:(NCVector*)u 
{
	float m[] = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 } ;
	float *t ;
	
	t = [ u get:nil ] ;
	m[3] = t[0] ;
	m[7] = t[1] ;
	m[11] = t[2] ;

	return [ self initWithMatrix:m ] ;
}

//	(Private API)
- (id)initWithRotateXRadian:(float)v
{
	float m[] = { 1, 0, 0, 0, 0, cos( v ), -sin( v ), 0, 0, sin( v ), cos( v ), 0, 0, 0, 0, 1 } ;
	
	return [ self initWithMatrix:m ] ;
}

//	(Private API)
- (id)initWithRotateYRadian:(float)v
{
	float m[] = { cos( v ), 0, -sin( v ), 0, 0, 1, 0, 0, sin( v ), 0, cos( v ), 0, 0, 0, 0, 1 } ;
	
	return [ self initWithMatrix:m ] ;
}

//	(Private API)
- (id)initWithRotateZRadian:(float)v
{
	float m[] = { cos( v ), -sin( v ), 0, 0, sin( v ), cos( v ), 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 } ;
	
	return [ self initWithMatrix:m ] ;
}

- (id)initWithRotateX:(float)u
{
	return [ self initWithRotateXRadian:u*rad ] ;
}

- (id)initWithRotateY:(float)u
{
	return [ self initWithRotateYRadian:u*rad ] ;
}

- (id)initWithRotateZ:(float)u 
{
	return [ self initWithRotateZRadian:u*rad ] ;
}

- (void)dealloc
{
	[ super dealloc ] ;
}

+ (id)transformWithMatrix:(float*)m 
{
	NCTransform *p ;
		
	p = [ [ NCTransform alloc ] initWithMatrix:m ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithTransform:(NCTransform*)v
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initFromTransform:v ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

//  return copy of v*scale
+ (id)transformWithTransform:(NCTransform*)v scale:(float)scale
{
	NCTransform *p, *q ;
	
	q = [ [ NCTransform alloc ] initWithScale:scale ] ;
	p = [ NCTransform transformByConcatenating:v toTransform:q ] ;
	[ q release ] ;
	return p ;
}

+ (id)transformByConcatenating:(NCTransform*)transform1 toTransform:(NCTransform*)transform2
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initByConcatenating:transform1 toTransform:transform2 ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithIdentity
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithIdentity ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithScale:(float)scale
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithScale:scale ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithTranslation:(NCVector*)u
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithTranslation:u ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithRotateX:(float)u
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithRotateX:u ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithRotateY:(float)u
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithRotateY:u ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

+ (id)transformWithRotateZ:(float)u
{
	NCTransform *p ;
	
	p = [ [ NCTransform alloc ] initWithRotateZ:u ] ;
	if ( p != nil ) {
		[ p autorelease ] ;
		return p ;
	}
	return nil ;
}

//  Private API
- (void)transformFloat:(float*)u to:(float*)result
{
	result[0] = a[0]*u[0] + a[1]*u[1] + a[2]*u[2] + a[3] ;
	result[1] = a[4]*u[0] + a[5]*u[1] + a[6]*u[2] + a[7] ;
	result[2] = a[8]*u[0] + a[9]*u[1] + a[10]*u[2] + a[11] ;
}

- (float)rotationMatrixElement:(int)i j:(int)j 
{
	int p ;
	
	p = i + j*4 ;
	if ( p >= 16 ) p = 0 ;

	return a[p] ;
}

- (float)translationElement:(int)i 
{
	if ( i >= 3 ) i = 0 ;
	return a[3 + i*4] ;
}

- (void)transform:(NCVector*)vector to:(NCVector*)result
{
	float u[3], v[3] ;
	
	[ vector get:u ] ;
	
	[ self transformFloat:u to:v ] ;
	[ result set:v ] ;
}

- (NCVector*)applyTransform:(NCVector*)vector
{
	float u[3], v[3] ;
	
	[ vector get:u ] ;
	
	[ self transformFloat:u to:v ] ;
	return [ NCVector vectorWithArray:v ] ;
}

- (float*)matrix
{
	return a ;
}

@end
