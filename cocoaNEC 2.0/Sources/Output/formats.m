/*
 *  formats.c
 *  cocoaNEC
 *
 *  Created by Kok Chen on 9/24/07.
 */

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


#include "formats.h"
#include <math.h>
#import <Foundation/NSString.h>


//  create floating point numbers that fit in a 10 character field
const char* dtos( double value ) 
{
	double p ;
	NSString *fmt ;
	
	p = fabs( value ) ;
	
	if ( p < 1.0e-9 ) {
		p = 0 ;
		value = 0 ;
	}
	
	if ( value >= 0 ) {
		if ( p == 0 ) fmt = @"%10.6f" ;
		else if ( p < .001 ) fmt = @"%10.2E" ;
		else if ( p < 10.0 ) fmt = @"%10.6f" ;
		else if ( p < 100.0 ) fmt = @"%10.5f" ;
		else if ( p < 1000.0 ) fmt = @"%10.4f" ;
		else if ( p < 10000.0 ) fmt = @"%10.3f" ;
		else fmt = @"%10.3E" ;
	}
	else {
		if ( p == 0 ) fmt = @"%10.5f" ;
		else if ( p < .001 ) fmt = @"%10.2E" ;
		else if ( p < 10.0 ) fmt = @"%10.5f" ;
		else if ( p < 100.0 ) fmt = @"%10.4f" ;
		else if ( p < 1000.0 ) fmt = @"%10.3f" ;
		else fmt = @"%10.2E" ;
	}

	return [ [ NSString stringWithFormat:fmt, value ] UTF8String ] ;
}

const char* dtosExtended( double value ) 
{
	double p ;
	NSString *fmt ;
	
	p = fabs( value ) ;
	
	if ( value >= 0 ) {
		if ( p == 0 ) fmt = @"%10.6f" ;
		else if ( p < .001 ) fmt = @"%10.3E" ;
		else if ( p < 10.0 ) fmt = @"%10.6f" ;
		else if ( p < 100.0 ) fmt = @"%10.5f" ;
		else if ( p < 1000.0 ) fmt = @"%10.4f" ;
		else if ( p < 10000.0 ) fmt = @"%10.3f" ;
		else fmt = @"%10.3E" ;
	}
	else {
		if ( p == 0 ) fmt = @"%10.5f" ;
		else if ( p < .001 ) fmt = @"%10.2E" ;
		else if ( p < 10.0 ) fmt = @"%10.5f" ;
		else if ( p < 100.0 ) fmt = @"%10.4f" ;
		else if ( p < 1000.0 ) fmt = @"%10.3f" ;
		else if ( p < 10000.0 ) fmt = @"%10.2f" ;
		else fmt = @"%10.2E" ;
	}
	
	return [ [ NSString stringWithFormat:fmt, value ] UTF8String ] ;
}
