//
//  NCExcitation.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/22/07.
//	-----------------------------------------------------------------------------
//  Copyright 2007-2016 Kok Chen, W7AY. 
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

#import "NCExcitation.h"


@implementation NCExcitation

- (id)initWithType:(int)inType real:(double)r imag:(double)i
{
	self = [ super init ] ;
	if ( self ) {
		//  v0.85
		switch ( inType ) {
		case CURRENTPHASORD:
			// change to radians
			i *= 1.745329252E-02 ;
			//  pass through switch
		case CURRENTPHASOR:
			real = r*cos( i ) ;
			imag = r*sin( i ) ;
			type = CURRENTEXCITATION ;
			break ;
		default:
			type = inType ;
			real = r ;
			imag = i ;
			break ;
		}
	}
	return self ;
}

//  v0.51 -- incdent plane waves
- (id)initWithType:(int)inType theta:(double)t phi:(double)p eta:(double)e
{
	self = [ super init ] ;
	if ( self ) {
		type = inType ;
		theta = t ;
		phi = p ;
		eta = e ;
	}
	return self ;
}

- (int)excitationType
{
	return type ;
}

- (double)real
{
	return real ;
}

- (double)imag
{
	return imag ;
}

- (double)theta
{
	return theta ;
}

- (double)phi
{
	return phi ;
}

- (double)eta
{
	return eta ;
}

@end
