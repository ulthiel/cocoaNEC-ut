//
//  GlobalContext.m
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


#import "GlobalContext.h"
#include <math.h>


//  library functions
static double _sinp( double arg, double dummy ) ;
static double _sind( double arg, double dummy ) ;
static double _asinp( double arg, double dummy ) ;
static double _asind( double arg, double dummy ) ;
static double _cosp( double arg, double dummy ) ;
static double _cosd( double arg, double dummy ) ;
static double _acosp( double arg, double dummy ) ;
static double _acosd( double arg, double dummy ) ;
static double _tanp( double arg, double dummy ) ;
static double _tand( double arg, double dummy ) ;
static double _atanp( double arg, double dummy ) ;
static double _atand( double arg, double dummy ) ;
static double _atan2p( double arg1, double arg2 ) ;
static double _atan2d( double arg1, double arg2 ) ;

static double _sinh( double arg, double dummy ) ;
static double _cosh( double arg, double dummy ) ;
static double _tanh( double arg, double dummy ) ;
static double _asinh( double arg, double dummy ) ;
static double _acosh( double arg, double dummy ) ;
static double _atanh( double arg, double dummy ) ;

static double _sqrt( double arg, double dummy ) ;
static double _pow( double arg1, double arg2 ) ;

static double _exp( double arg, double dummy ) ;
static double _log( double arg, double dummy ) ;
static double _log10( double arg, double dummy ) ;

#define	PI	3.14159265358979
#define	RAD	( PI/180.0 )
#define	DEG	( 180.0/PI )


@implementation GlobalContext

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		libraryDict = [ [ NSMutableDictionary alloc ] initWithCapacity:32 ] ;
		
		//  create Prinary objects for trig functions that evaluate with degrees and with radians
		sinp = [ [ Primary alloc ] initFunctionWithArg:_sinp ] ;
		sind = [ [ Primary alloc ] initFunctionWithArg:_sind ] ;
		cosp = [ [ Primary alloc ] initFunctionWithArg:_cosp ] ;
		cosd = [ [ Primary alloc ] initFunctionWithArg:_cosd ] ;
		tanp = [ [ Primary alloc ] initFunctionWithArg:_tanp ] ;
		tand = [ [ Primary alloc ] initFunctionWithArg:_tand ] ;
		atanp = [ [ Primary alloc ] initFunctionWithArg:_atanp ] ;
		atand = [ [ Primary alloc ] initFunctionWithArg:_atand ] ;
		atan2p = [ [ Primary alloc ] initFunctionWithArg:_atan2p ] ;
		atan2d = [ [ Primary alloc ] initFunctionWithArg:_atan2d ] ;
		asinp = [ [ Primary alloc ] initFunctionWithArg:_asinp ] ;
		asind = [ [ Primary alloc ] initFunctionWithArg:_asind ] ;
		acosp = [ [ Primary alloc ] initFunctionWithArg:_acosp ] ;
		acosd = [ [ Primary alloc ] initFunctionWithArg:_acosd ] ;
		
		[ libraryDict setObject:sind forKey:@"sind" ] ;
		[ libraryDict setObject:cosd forKey:@"cosd" ] ;
		[ libraryDict setObject:tand forKey:@"tand" ] ;
		[ libraryDict setObject:atand forKey:@"atand" ] ;
		[ libraryDict setObject:atan2d forKey:@"atan2d" ] ;
		[ libraryDict setObject:asind forKey:@"asind" ] ;
		[ libraryDict setObject:acosd forKey:@"acosd" ] ;
		
		[ libraryDict setObject:sinp forKey:@"sin" ] ;
		[ libraryDict setObject:cosp forKey:@"cos" ] ;
		[ libraryDict setObject:tanp forKey:@"tan" ] ;
		[ libraryDict setObject:atanp forKey:@"atan" ] ;
		[ libraryDict setObject:atan2p forKey:@"atan2" ] ;
		[ libraryDict setObject:asinp forKey:@"asin" ] ;
		[ libraryDict setObject:acosp forKey:@"acos" ] ;
		
		//  hyperbolic functions
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_sinh ] forKey:@"sinh" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_cosh ] forKey:@"cosh" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_tanh ] forKey:@"tanh" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_asinh ] forKey:@"asinh" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_acosh ] forKey:@"acosh" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_atanh ] forKey:@"atanh" ] ;
		//  other library functions
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithArg:_sqrt ] forKey:@"sqrt" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithTwoArgs:_pow ] forKey:@"pow" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithArg:_exp ] forKey:@"exp" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithArg:_log ] forKey:@"log" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithArg:_log10 ] forKey:@"log10" ] ;
		[ libraryDict setObject:[ [ Primary alloc ] initFunctionWithArg:_log ] forKey:@"ln" ] ;
		//  constants
		[ libraryDict setObject:[ [ Primary alloc ] initWithDouble:asin(1.0)*2 ] forKey:@"pi" ] ;
	}
	return self ;
}

- (NSMutableDictionary*)library
{
	return libraryDict ;
}

//  library functions (convert from two double precision arguments to native arguments of Unix math library

static double _sinp( double arg, double dummy ) { return sin( arg ) ; }

static double _sind( double arg, double dummy ) { return sin( arg*RAD ) ; }

static double _asinp( double arg, double dummy ) { return asin( arg ) ; }

static double _asind( double arg, double dummy ) { return DEG*asin( arg ) ; }

static double _cosp( double arg, double dummy ) { return cos( arg ) ; }

static double _cosd( double arg, double dummy ) { return cos( arg*RAD ) ; }

static double _acosp( double arg, double dummy ) { return acos( arg ) ; }

static double _acosd( double arg, double dummy ) { return DEG*acos( arg ) ; }

static double _tanp( double arg, double dummy ) { return tan( arg ) ; }

static double _tand( double arg, double dummy ) { return tan( arg*RAD ) ; }

static double _atanp( double arg, double dummy ) { return atan( arg ) ; }

static double _atand( double arg, double dummy ) { return ( DEG*atan( arg ) ) ; }

static double _atan2p( double arg1, double arg2 ) { return atan2( arg1, arg2 ) ; }

static double _atan2d( double arg1, double arg2 ) { return ( DEG*atan2( arg1, arg2 ) ) ; }

static double _sinh( double arg, double dummy ) { return sinh( arg ) ; }

static double _cosh( double arg, double dummy ) { return cosh( arg ) ; }

static double _tanh( double arg, double dummy ) { return tanh( arg ) ; }

static double _asinh( double arg, double dummy ) { return asinh( arg ) ; }

static double _acosh( double arg, double dummy ) { return acosh( arg ) ; }

static double _atanh( double arg, double dummy ) { return atanh( arg ) ; }

static double _sqrt( double arg, double dummy ) { return sqrt( arg ) ; }

static double _pow( double arg1, double arg2 ) { return pow( arg1, arg2 ) ; }

static double _exp( double arg, double dummy ) { return exp( arg ) ; }

static double _log( double arg, double dummy ) { return log( arg ) ; }

static double _log10( double arg, double dummy ) { return log10( arg ) ; }

@end
