//
//  NCObject.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/14/07.
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

#import "NCObject.h"
#import "ApplicationDelegate.h"
#import "NC.h"
#import "NCCompiler.h"
#import "NCElement.h"
#import "NCValue.h"


@implementation NCObject

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		name = nil ;
		type = 0 ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = 0 ;
		value = [ [ NCValue alloc ] init ] ;
	}
	return self ;
}

//  v0.64 - value was leaking for NCFunctionObject
- (id)initWithoutValue
{
	self = [ super init ] ;
	if ( self ) {
		name = nil ;
		type = 0 ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = 0 ;
		value = nil ;
	}
	return self ;
}

- (id)initWithArrayElement:(int)index type:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		name = nil ;
		type = inType ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = index ;
		value = [ [ NCValue alloc ] init ] ;
	}
	return self ;
}

- (id)initWithVariable:(const char*)string type:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = inType ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = 0 ;
		value = [ [ NCValue alloc ] init ] ;
	}
	return self ;
}

//	v0.54
- (id)initWithArray:(const char*)string dimension:(int)dimension type:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = ARRAYTYPE ;
		arrayType = inType ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = 0 ;
		value = [ [ NCValue alloc ] initAsArray:dimension type:inType ] ;
	}
	return self ;
}

//	v0.54
- (id)initWithPointer:(const char*)string type:(int)inType
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = ARRAYTYPE ;
		arrayType = inType ;
		symClass = NCVARIABLE ;
		forwardReference = NO ;
		arrayIndex = 0 ;
		value = [ [ NCValue alloc ] initAsArray:0 type:inType ] ;
	}
	return self ;
}

//	v0.54
- (int)arrayType
{
	return arrayType ;
}

- (Boolean)isForwardReference
{
	return forwardReference ;
}

//  implemented by NCFunctionObject and NCForwardReferece
- (void)setFunction:(NCFunction*)inFunction
{
}

//  implemented by NCFunctionObject and NCForwardReferece
- (NCFunction*)function
{
	return nil ;
}

- (id)initWithRealVariable:(const char*)string value:(double)v
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = REALTYPE ;
		symClass = NCVARIABLE ;
		value = [ [ NCValue alloc ] init ] ;
		[ value setDoubleValue:v ] ;
	}
	return self ;
}

//  v0.77
- (id)initWithIntVariable:(const char*)string value:(int)v
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = INTTYPE ;
		symClass = NCVARIABLE ;
		value = [ [ NCValue alloc ] init ] ;
		[ value setIntValue:v ] ;
	}
	return self ;
}

//  v0.81b
- (id)initWithCoaxVariable:(const char*)string value:(int)v
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = COAXTYPE ;
		symClass = NCVARIABLE ;
		value = [ [ NCValue alloc ] initAsCoax:v ] ;
	}
	return self ;
}

- (id)initAsNil:(const char*)string
{
	self = [ super init ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = TRANSFORMTYPE ;
		symClass = NCVARIABLE ;
		value = [ [ NCValue alloc ] initWithType:type ] ;
	}
	return self ;
}

- (void)dealloc
{
	if ( value != nil ) [ value release ] ;				//  v0.64 handle new -initWithoutValue
	[ super dealloc ] ;
}

- (NSString*)name
{
	return name ;
}

- (int)intValue
{
	return [ value intValue ] ;
}

- (double)realValue
{
	return [ value doubleValue ] ;
}

- (void)setRealValue:(double)v
{
	[ value setDoubleValue:v ] ;
}

- (int)symClass
{
	return symClass ;
}

- (int)type
{
	return type ;
}

- (Boolean)isFunction
{
	return NO ;
}

- (Boolean)isRunModelFunction
{
	return NO ;
}

- (void)runtimeMessage:(NSString*)err stack:(RuntimeStack*)stack line:(int)line
{
	[ stack->errors addObject:[ NSString stringWithFormat:@"%s (line %d)", [ err UTF8String ], line ] ] ;
}

- (NCValue*)get:(RuntimeStack*)stack line:(int)line
{
	if ( [ value type ] <= 0 ) {
		[ self runtimeMessage:[ NSString stringWithFormat:@"Warning - variable '%s' uninitialized", [ name UTF8String ] ] stack:stack line:line ] ;
		if ( type == ELEMENTTYPE || type == VECTORTYPE ) [ value setElementValue:nil ] ;
		else if ( type == REALTYPE ) [ value setDoubleValue:0.0 ] ;
		else [ value setIntValue:0 ] ;
		return nil ;
	}
	return value ;
}

- (void)put:(NCValue*)ncvalue stack:(RuntimeStack*)stack line:(int)line
{
	[ value setFrom:ncvalue withType:type ] ;
}

- (NCValue*)value
{
	return value ;
}

@end
