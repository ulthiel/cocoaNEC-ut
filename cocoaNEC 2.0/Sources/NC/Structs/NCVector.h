//
//  NCVector.h
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

#import <Cocoa/Cocoa.h>
#import "Config.h"

@interface NCVector : NSObject {
	float x ;
	float y ;
	float z ;
	float array[3] ;
}

- (id)initWithX:(float)ix y:(float)iy z:(float)iz ;
- (id)initWithVector:(NCVector*)v ;
- (id)initWithVectorArray:(float*)ix ;

+ (NCVector*)vectorWithX:(float)ix y:(float)iy z:(float)iz ;
+ (NCVector*)vectorWithVector:(NCVector*)v ;
+ (NCVector*)vectorWithVector:(NCVector*)v scale:(float)factor ;
+ (NCVector*)vectorWithArray:(float*)ix ;
+ (NCVector*)vectorWithSum:(NCVector*)v to:(NCVector*)u ;
+ (NCVector*)vectorWithDifference:(NCVector*)v from:(NCVector*)u ;

//  accumulate
- (void)addVector:(NCVector*)v ;
- (void)subtractVector:(NCVector*)v ;

//  value of vector
- (float)dotWithVector:(NCVector*)v ;
- (float)length ;

- (void)scale:(float)factor ;

//	value of components of vector
- (void)setX:(float)ix y:(float)iy z:(float)iz ;

- (float*)get:(float*)v ;
- (void)set:(float*)v ;

- (float)component:(int)index ;
- (float)x ;
- (void)setX:(float)v ;
- (float)y ;
- (void)setY:(float)v ;
- (float)z ;
- (void)setZ:(float)v ;


@end
