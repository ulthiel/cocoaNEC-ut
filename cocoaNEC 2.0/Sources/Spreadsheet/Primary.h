//
//  Primary.h
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

#import <Cocoa/Cocoa.h>
#import "Config.h"

#define	primary_VAR		1
#define	primary_FUNC	2


typedef double (*FuncPtr)( double, double ) ;

//  value conversions
#define	METRIC		1.0
#define	FEET		0.3048
#define	INCH		0.0254
#define	AWG			2.0					//  use awg table	
#define	MICRO		( 1e-6 )			//  v0.74
#define	NANO		( 1e-9 )			//  v0.74
#define	PICO		( 1e-12 )			//  v0.74

@interface Primary : NSObject {
    int type ;
    int arguments ;							// number of arguments (0 for variables)
    double value ;							// variable
    FuncPtr func ;							// function pointer
}

- (id)initWithDouble:(double)v ;
- (id)initWithDoubleString:(NSString*)str ;

- (id)initFunction:(FuncPtr)fn ;
- (id)initFunctionWithArg:(FuncPtr)fn ;
- (id)initFunctionWithTwoArgs:(FuncPtr)f ;

- (int)type ;
- (int)arguments ;
    
- (void)setDoubleValue:(double)v ;
- (void)setStringValue:(NSString*)str ;

- (double)doubleValue ;
- (double)doubleValue:(double)arg ;
- (double)doubleValue:(double)arg1 with:(double)arg2 ;


@end
