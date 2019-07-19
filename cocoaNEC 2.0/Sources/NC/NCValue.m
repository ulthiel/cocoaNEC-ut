//
//  NCValue.m
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

#import "NCValue.h"
#import "NCBasicValue.h"
#import "NCParser.h"

@implementation NCValue

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		type = 0 ;
		intValue = 0 ;
		realValue = 0.0 ;
		elementValue = nil ;
		coaxValue = nil ;			//  v0.81b
		vectorValue = nil ;
		ncObject = nil ;
		transformValue = nil ;
		string = nil ;
		array = nil ;
		returnFlag = NO ;
		arrayDimension = 0 ;
	}
	return self ;
}

//  When init is called, the type is not specified (0), this allows the NC runtime to detect this as an unitialized variable.
//	initWithType sets a type for cases such as defining an NCValue for "nil".
- (id)initWithType:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		type = inType ;
		intValue = 0 ;
		realValue = 0.0 ;
		elementValue = nil ;
		coaxValue = nil ;			//  v0.81b
		vectorValue = nil ;
		ncObject = nil ;
		transformValue = nil ;
		string = nil ;
		array = nil ;
		returnFlag = NO ;
		arrayDimension = 0 ;
	}
	return self ;
}

//	0.54 -- dimesion == 0 is 
- (id)initAsArray:(int)dimension type:(int)inType
{
	int i ;
	NCObject *v ;

	self = [ super init ] ;
	if ( self ) {
		type = ARRAYTYPE ;
		intValue = 0 ;
		realValue = 0.0 ;
		elementValue = nil ;
		coaxValue = nil ;			//  v0.81b
		vectorValue = nil ;
		ncObject = nil ;
		transformValue = nil ;
		string = nil ;
		returnFlag = NO ;
		if ( array == nil ) array = [ [ NSMutableArray alloc ] initWithCapacity:dimension ] ; else [ array removeAllObjects ] ;
		for ( i = 0; i < dimension; i++ ) {
			v = [ [ NCObject alloc ] initWithArrayElement:i type:inType ] ;
			[ array addObject:v ] ;
			[ v release ] ;			//  array element retained by array
		}
		arrayDimension = ( dimension == 0 ) ? 65536 : dimension ;
	}
	return self ;
}

//	0.81b
- (id)initAsCoax:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		type = COAXTYPE ;
		intValue = 0 ;
		realValue = 0.0 ;
		elementValue = nil ;
		vectorValue = nil ;
		ncObject = nil ;
		transformValue = nil ;
		string = nil ;
		array = nil ;
		returnFlag = NO ;
		arrayDimension = 0 ;
		coaxValue = [ [ NCCoax alloc ] initWithType:inType ] ;
	}
	return self ;
}

//  0.54
- (intType)arrayDimension
{
	if ( array == nil ) return 0 ;
	return [ array count ] ;
}

- (void)dealloc
{
	if ( vectorValue ) [ vectorValue release ] ;
	if ( transformValue ) [ transformValue release ] ;
	if ( elementValue ) [ elementValue release ] ;
	if ( coaxValue ) [ coaxValue release ] ;
	if ( array ) [ array release ] ;
	if ( ncObject ) [ ncObject release ] ;
	[ super dealloc ] ;
}

+ (id)valueWithInt:(int)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setIntValue:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)breakValue
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setIntValue:0x80000000 ] ;
	return [ newValue autorelease ] ;
}

+ (id)voidValue 
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setVoidValue ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithDouble:(double)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setDoubleValue:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithString:(char*)str
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setStringValue:str ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithElement:(NCElement*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setElementValue:value ] ;			//  v0.64 value retained in -setElementValue
	return [ newValue autorelease ] ;
}

//  v0.81b
+ (id)valueWithCoax:(NCCoax*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setCoaxValue:[ value retain ] ] ;
	return [ newValue autorelease ] ;
}

//  create a NCValue object as a transform object and retain the transform
+ (id)valueWithVector:(NCVector*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setVectorValue:[ value retain ] ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithNCObject:(NCObject*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setNCObject:[ value retain ] ] ;
	return [ newValue autorelease ] ;	
}

+ (id)vectorWithX:(float)x y:(float)y z:(float)z
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setX:x y:y z:z ] ;
	return [ newValue autorelease ] ;
}

//  create a NCValue object as a transform object and retian the transform
+ (id)valueWithTransform:(NCTransform*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setTransformValue:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithValue:(NCValue*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFrom:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithNegatedValue:(NCValue*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFromNegated:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithVectorAdd:(NCValue*)vRight toVector:(NCValue*)vLeft
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFromAddingVector:vRight to:vLeft ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithVectorSubtract:(NCValue*)vRight fromVector:(NCValue*)vLeft
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFromSubtractingVector:vRight from:vLeft ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithIncrementValue:(NCValue*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFromIncremented:value ] ;
	return [ newValue autorelease ] ;
}

+ (id)valueWithDecrementValue:(NCValue*)value
{
	NCValue *newValue ;
	
	newValue = [ [ NCValue alloc ] init ] ;
	[ newValue setFromDecremented:value ] ;
	return [ newValue autorelease ] ;
}

//  undefined value has type = 0
+ (id)undefinedValue
{
	return [ [ [ NCValue alloc ] init ] autorelease ] ;
}

- (Boolean)isBreakValue
{
	return ( intValue == 0x80000000 ) ;
}

//  return flag is set in an NCValue that is set when we see a return statment
- (void)setReturnFlag:(Boolean)state 
{
	returnFlag = state ;
}

- (Boolean)returnFlag 
{
	return returnFlag ;
}

- (NSArray*)array
{
	return array ;
}

- (void)setFrom:(NCValue*)v withType:(int)inType
{
	type = inType ;
	
	intValue = [ v intValue ] ;
	realValue = [ v doubleValue ] ;
	string = [ v stringValue ] ;
	
	if ( elementValue != nil ) [ elementValue autorelease ] ;
	elementValue = ( [ v elementValue ] != nil )  ? [ [ v elementValue ] retain ] : nil ;
	
	//	v0.81b
	if ( coaxValue != nil ) [ coaxValue autorelease ] ;
	coaxValue = ( [ v coaxValue ] != nil )  ? [ [ v coaxValue ] retain ] : nil ;
	
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = ( [ v transformValue ] != nil ) ? [ [ NCTransform transformWithTransform:[ v transformValue ] ] retain ] : nil ;
	
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithVector:[ v vectorValue ] ] retain ] : nil ;
	
    //  v0.88 copy from NSArray to NSMutableArray
    [ array removeAllObjects ] ;
    if ( [ v array ] != nil ) {
        [ array addObjectsFromArray:[ v array ] ] ;
    }
}

- (void)setFrom:(NCValue*)v
{
	[ self setFrom:v withType:[ v type ] ] ;
}

- (void)setFromNegated:(NCValue*)v
{
	type = [ v type ] ;
	intValue = -[ v intValue ] ;
	realValue = -[ v doubleValue ] ;
	
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithVector:[ v vectorValue ] scale:(-1.0) ] retain ] : nil ;	
	
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = ( [ v transformValue ] != nil ) ? [ [ NCTransform transformWithTransform:[ v transformValue ] scale:(-1.0) ] retain ] : nil ;	
}

- (void)setFromAddingVector:(NCValue*)v to:(NCValue*)u
{
	type = [ u type ] ;
	intValue = realValue = 0 ;

	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithSum:[ v vectorValue ] to:[ u vectorValue ] ] retain ] : nil ;	
}

- (void)setFromSubtractingVector:(NCValue*)v from:(NCValue*)u
{
	type = [ u type ] ;
	intValue = realValue = 0 ;

	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithDifference:[ v vectorValue ] from:[ u vectorValue ] ] retain ] : nil ;	
}

- (void)setFromIncremented:(NCValue*)v
{
	type = [ v type ] ;
	intValue = [ v intValue ] + 1 ;
	realValue = [ v doubleValue ] + 1 ;
	
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithVector:[ v vectorValue ] scale:(-1.0) ] retain ] : nil ;	
	
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = ( [ v transformValue ] != nil ) ? [ [ NCTransform transformWithTransform:[ v transformValue ] scale:(-1.0) ] retain ] : nil ;	
}

- (void)setFromDecremented:(NCValue*)v
{
	type = [ v type ] ;
	intValue = [ v intValue ] - 1 ;
	realValue = [ v doubleValue ] - 1 ;
	
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithVector:[ v vectorValue ] scale:(-1.0) ] retain ] : nil ;	
	
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = ( [ v transformValue ] != nil ) ? [ [ NCTransform transformWithTransform:[ v transformValue ] scale:(-1.0) ] retain ] : nil ;	
}

//	same as setFrom:withType, but arrays are arrays of NCValue
- (void)setFromBasicValue:(NCBasicValue*)v withType:(int)inType
{
	intType i, count ;
	NSArray *p ;
	NCValue *value ;
	NCObject *object ;
	
	type = inType ;
	intValue = [ v intValue ] ;
	realValue = [ v doubleValue ] ;
	string = [ v stringValue ] ;
	
	if ( elementValue != nil ) [ elementValue autorelease ] ;
	elementValue = ( [ v elementValue ] != nil )  ? [ [ v elementValue ] retain ] : nil ;
	
	//	v0.81b
	if ( coaxValue != nil ) [ coaxValue autorelease ] ;
	coaxValue = ( [ v coaxValue ] != nil )  ? [ [ v coaxValue ] retain ] : nil ;
	
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = ( [ v transformValue ] != nil ) ? [ [ NCTransform transformWithTransform:[ v transformValue ] ] retain ] : nil ;
	
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = ( [ v vectorValue ] != nil ) ? [ [ NCVector vectorWithVector:[ v vectorValue ] ] retain ] : nil ;
	
	p = [ v array ] ;
	if ( p != nil && array != nil ) {
		count = [ p count ] ;
		for ( i = 0; i < count; i++ ) {
			object =  [ array objectAtIndex:i ] ;	//  NCObject
			value = [ object value ] ;
			[ value setFrom:[ p objectAtIndex:i ] ] ;
		} 
	}
}

- (void)setFromBasicValue:(NCBasicValue*)v
{
	[ self setFromBasicValue:v withType:[ v type ] ] ;
}

- (int)intValue
{
	return intValue ;
}

- (void)setIntValue:(int)value
{
	type = INTTYPE ;
	realValue = intValue = value ;
}

- (double)doubleValue
{
	return realValue ;
}

- (void)setDoubleValue:(double)value
{
	type = REALTYPE ;
	realValue = value ;
	intValue = value ;
}

- (char*)stringValue
{
	return string ;
}

- (void)setStringValue:(char*)pointer
{
	type = STRINGTYPE ;
	realValue = intValue = 0 ;
	string = pointer ;
}

//	v0.54
- (NCObject*)elementAtIndex:(int)i
{
	if ( array == nil ) return nil ;
	return [ array objectAtIndex:i ] ;
}

//  member
- (NCElement*)elementValue
{
	return elementValue ;
}

//  member
- (void)setElementValue:(NCElement*)value
{
	type = ELEMENTTYPE ;
	realValue = intValue = (int)value ;
	if ( elementValue != nil ) [ elementValue autorelease ] ;
	elementValue = [ value retain ] ;
}

//	v0.81b
- (NCObject*)coaxAtIndex:(int)i
{
	if ( array == nil ) return nil ;
	return [ array objectAtIndex:i ] ;
}

//  v0.81b
- (NCCoax*)coaxValue
{
	return coaxValue ;
}

//	v0.81b
- (void)setCoaxValue:(NCCoax*)value
{
	type = COAXTYPE ;
	realValue = intValue = (int)value ;
	if ( coaxValue != nil ) [ coaxValue autorelease ] ;
	coaxValue = [ value retain ] ;
}

- (NCVector*)vectorValue
{
	return vectorValue ;
}

- (void)setVectorValue:(NCVector*)vector
{
	type = VECTORTYPE ;
	realValue = intValue = (int)vector ;
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = [ [ NCVector vectorWithVector:vector ] retain ] ;
}

- (void)setNCObject:(NCObject*)obj
{
	type = OBJECTTYPE ;
	realValue = intValue = (int)obj ;
	if ( ncObject != nil ) [ ncObject autorelease ] ;
	ncObject = obj ;
}

- (NCObject*)ncObject 
{
	return ncObject ;
}

- (void)setX:(float)x y:(float)y z:(float)z ;
{
	type = VECTORTYPE ;
	realValue = intValue = x ;
	if ( vectorValue != nil ) [ vectorValue autorelease ] ;
	vectorValue = [ [ NCVector vectorWithX:x y:y z:z ] retain ] ;
}

- (NCTransform*)transformValue
{
	return transformValue ;
}

- (void)setTransformValue:(NCTransform*)transform
{
	type = TRANSFORMTYPE ;
	realValue = intValue = (int)transform ;
	if ( transformValue != nil ) [ transformValue autorelease ] ;
	transformValue = [ [ NCTransform transformWithTransform:transform ] retain ] ;
}

- (void)setVoidValue
{
	type = VOIDTYPE ;
	realValue = intValue = 0 ;
	elementValue = nil ;
	coaxValue = nil ;		//  v0.81b
}

- (int)type
{
	return type ;
}

- (int)arrayType
{
	NCValue *v ;
	
	if ( type != ARRAYTYPE ) return 0 ;
	v = [ array objectAtIndex:0 ] ;
	return [ v type ] ;		//  return type of one of the array element NCValue type
}

@end
