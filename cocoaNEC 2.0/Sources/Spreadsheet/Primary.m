//
//  Primary.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/3/07.
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

#import "Primary.h"
#import "awg.h"

//	Primary is the Object that is saved in the dictionaries.

@implementation Primary

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		value = 0.0 ;
		arguments = 0 ;
		func = nil ;
		type = primary_VAR ;
	}
	return self ;
}

- (id)initWithDouble:(double)v
{
	[ self init ] ;
	value = v ;
	return self ;
}

- (id)initWithDoubleString:(NSString*)str
{
	[ self init ] ;
	[ self setStringValue:str ] ;
	return self ;
}

//  function with no argument
- (id)initFunction:(FuncPtr)fn
{
	[ self init ] ;
	func = fn ;
	type = primary_FUNC ;
	return self ;
}

//  function with one argument
- (id)initFunctionWithArg:(FuncPtr)fn
{
	[ self init ] ;
	func = fn ;
	type = primary_FUNC ;
	arguments = 1 ;
	return self ;
}

//  function with two arguments
- (id)initFunctionWithTwoArgs:(FuncPtr)fn
{
	[ self init ] ;
	func = fn ;
	type = primary_FUNC ;
	arguments = 2 ;
	return self ;
}

- (int)type
{
	return type ;
}

- (int)arguments
{
	return arguments ;
}

- (void)setDoubleValue:(double)v
{
	value = v ;
}

- (double)doubleValue
{
	if ( func ) return (*func)( 0.0, 0.0 ) ;
	return value ;
}

- (double)doubleValue:(double)arg
{
	return (*func)( arg, 0.0 ) ;
}

- (double)doubleValue:(double)arg1 with:(double)arg2
{
	return (*func)( arg1, arg2 ) ;
}

- (void)setStringValue:(NSString*)str
{
	intType len ;
    int i, c ;
	char post[256] ;
	double v ;
	
	type = primary_VAR ;
	value = 0.0 ;
	if ( str == nil ) return ;
	len = [ str length ] ;
	if ( len <= 0 ) return ;
	
	//  scan past spaces
	for ( i = 0; i < len; i++ ) {
		c = [ str characterAtIndex:i ] ;
		if ( c != ' ' || c != '\t' ) break ;
	}
	str = [ str substringFromIndex:i ] ;
	len -= i ;
	if ( [ str characterAtIndex:0 ] == '#' ) {
		str = [ str substringFromIndex:1 ] ;
		c = [ str intValue ] ;
		if ( c < 0 ) c = 0 ; else if ( c > 40 ) c = 40 ;
		value = awg[c]*INCH*0.5 ;
		return ;
	}
	post[0] = 0 ;
	sscanf( [ str UTF8String ], "%le%s", &v, post ) ;
	c = post[0] ;
	
	switch ( c ) {
	case '\'':
		v *= FEET ;
		break ;
	case '"':
		v *= INCH ;
		break ;
	case 'n':					//  v0.74
		v *= NANO ;
		break ;
	case 'u':					//  v0.74
		v *= MICRO ;
		break ;
	case 'p':					//  v0.74
		v *= PICO ;
		break ;
	}	
	value = v ;
}


// --------------------------------------------------------------------
#ifdef EXAMPLE_OF_USAGE

static double _sin( double arg, double dummy )
{
	return sin( arg ) ;
}

- (void)class
{
	Primary *function, *variable ;
	
	variable = [ [ Primary alloc ] initWithDouble:3.14159 ] ;
	function = [ [ Primary alloc ] initFunctionWithArg:_sin ] ;
	.
	.
	.
	[ variable doubleValue ] ;
	[ function doubleValue:3.14145926 ] ;
}
#endif
// ---------------------------------------------------------------------

@end
