//
//  NCValue.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/21/07.
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
#import "NCElement.h"
#import "NCCoax.h"
#import "NCVector.h"
#import	"NCTransform.h"
#import "NCObject.h"

@class NCBasicValue ;

@interface NCValue : NSObject {
	int type ;
	int intValue ;
	double realValue ;
	char *string ;
	NCElement *elementValue ;
	NCCoax *coaxValue ;				//  v0.81b
	NCVector *vectorValue ;
	NCTransform *transformValue ;
	NCObject *ncObject ;
	NSMutableArray *array ;			//  array of NCObjects
	int arrayDimension ;
	int member ;
	Boolean returnFlag ;
}

- (id)initWithType:(int)type ;
- (id)initAsArray:(int)dimension type:(int)inType ;
- (id)initAsCoax:(int)inType ;		//  v0.81b

+ (id)valueWithInt:(int)value ;
+ (id)valueWithDouble:(double)value ;
+ (id)valueWithElement:(NCElement*)value ;
+ (id)valueWithCoax:(NCCoax*)value ;
+ (id)valueWithVector:(NCVector*)value ;
+ (id)valueWithNCObject:(NCObject*)value ;
+ (id)valueWithTransform:(NCTransform*)transform ;
+ (id)vectorWithX:(float)x y:(float)y z:(float)z ;
+ (id)valueWithString:(char*)string ;
+ (id)undefinedValue ;
+ (id)breakValue ;
+ (id)voidValue ;

+ (id)valueWithValue:(NCValue*)original ;
+ (id)valueWithNegatedValue:(NCValue*)original ;
+ (id)valueWithIncrementValue:(NCValue*)value ;
+ (id)valueWithDecrementValue:(NCValue*)value ;

+ (id)valueWithVectorAdd:(NCValue*)vRight toVector:(NCValue*)vLeft ;
+ (id)valueWithVectorSubtract:(NCValue*)vRight fromVector:(NCValue*)vLeft ;

- (void)setFrom:(NCValue*)v ;
- (void)setFrom:(NCValue*)v withType:(int)inType ;
- (void)setFromNegated:(NCValue*)v ;
- (void)setFromIncremented:(NCValue*)v ;
- (void)setFromDecremented:(NCValue*)v ;
- (void)setFromAddingVector:(NCValue*)v to:(NCValue*)u ;
- (void)setFromSubtractingVector:(NCValue*)v from:(NCValue*)u ;
- (void)setFromBasicValue:(NCBasicValue*)v ;

- (int)intValue ;
- (void)setIntValue:(int)value ;

- (double)doubleValue ;
- (void)setDoubleValue:(double)value ;

- (char*)stringValue ;
- (void)setStringValue:(char*)pointer ;

- (NCElement*)elementValue ;
- (void)setElementValue:(NCElement*)value ;
- (NCObject*)elementAtIndex:(int)i ;

//	v0.81b
- (NCCoax*)coaxValue ;
- (void)setCoaxValue:(NCCoax*)value ;
- (NCObject*)coaxAtIndex:(int)i ;

- (NCVector*)vectorValue ;
- (void)setVectorValue:(NCVector*)value ;
- (void)setX:(float)x y:(float)y z:(float)z ;

- (void)setNCObject:(NCObject*)obj ;
- (NCObject*)ncObject ;

- (NCTransform*)transformValue ;
- (void)setTransformValue:(NCTransform*)value ;

- (NSArray*)array ;

- (void)setVoidValue ;

- (Boolean)isBreakValue ;

- (void)setReturnFlag:(Boolean)state ;
- (Boolean)returnFlag ;

- (int)type ;
- (intType)arrayDimension ;
- (int)arrayType ;

@end
