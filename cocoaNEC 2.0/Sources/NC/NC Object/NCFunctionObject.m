//
//  NCFunctionObject.m
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

#import "NCFunctionObject.h"
#import "ApplicationDelegate.h"
#import "NC.h"
#import "NCCoax.h"
#import "NCCompiler.h"
#import "NCElement.h"
#import "NCFunction.h"
#import "NCValue.h"


@implementation NCFunctionObject

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		value = [ [ NCValue alloc ] init ] ;
	}
	return self ;
}

- (id)initWithVariable:(const char*)string type:(int)inType
{
	self = [ super initWithVariable:string type:inType ] ;
	if ( self ) {
		symClass = NCFUNCTION ;
	}
	return self ;	
}

- (id)initWithSystem:(const char*)string type:(int)inType selector:(SEL)inSelector argPrototypes:(short*)inPrototypes
{
	self = [ super initWithoutValue ] ;
	if ( self ) {
		name = [ NSString stringWithUTF8String:string ] ;
		type = inType ;
		selector = inSelector ;
		[ self setArgPrototypes:inPrototypes ] ;
		symClass = NCSYSTEM ;
		function = nil ;
		value = [ [ NCValue alloc ] init ] ;
	}
	return self ;
}

- (void)setFunction:(NCFunction*)inFunction
{
	function = inFunction ;
}

- (NCFunction*)function
{
	return function ;
}

- (NSArray*)arrayWithPrototypes:(short*)args
{
	int n ;
	NSMutableArray *array ;
	
	array = [ NSMutableArray arrayWithCapacity:4 ] ;
	
	for ( n = 0; n < 64; n++ ) {
		if ( *args == 0 ) return array ;
		[ array addObject:[ NSNumber numberWithShort:*args ] ] ;
	}
	return array ;
}

//	v0.52
- (int)evalFunctionAsInt:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result intValue ] ;
		}
		return 0  ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		result = [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
		return [ result intValue ] ;
	}
	return 0 ;
}

//	v0.52
- (double)evalFunctionAsReal:(RuntimeStack*)inStack args:(NSArray*)args system:(NCSystem*)system
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result doubleValue ] ;
		}
		return 0.0  ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		result = [ system performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
		return [ result doubleValue ] ;
	}
	return 0.0 ;
}

//	v0.52
- (NCElement*)evalFunctionAsElement:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result elementValue ] ;
		}
		return (NCElement*)[ NCValue undefinedValue ] ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		return [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
	}
	return nil ;
}

//	v0.81b
- (NCCoax*)evalFunctionAsCoax:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result coaxValue ] ;
		}
		return (NCCoax*)[ NCValue undefinedValue ] ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		result = [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
		return [ result coaxValue ] ;
	}
	return nil ;
}

//	v0.53
- (NCVector*)evalFunctionAsVector:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result vectorValue ] ;
		}
		return (NCVector*)[ NCValue undefinedValue ] ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		result = [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
		return [ result vectorValue ] ;
	}
	return nil ;
}

//	v0.53
- (NCTransform*)evalFunctionAsTransform:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	NCValue *result ;
	
	if ( symClass == NCFUNCTION ) {	
		if ( function ) {
			result = [ function execute:inStack initArguments:args ] ;
			if ( result ) return [ result transformValue ] ;
		}
		return (NCTransform*)[ NCValue undefinedValue ] ;
	}
	if ( symClass == NCSYSTEM ) {
		nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
		result = [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
		return [ result transformValue ] ;
	}
	return nil ;
}

//	v0.52
- (NCElement*)evalFunctionAsCard:(RuntimeStack*)inStack args:(NSArray*)args
{
	NC *nc ;
	
	nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
	return [ [ nc system ] performSelector:selector withObject:args withObject:[ self arrayWithPrototypes:argPrototypes ] ] ;
}

//  v0.52
- (void)evalFunctionAsVoid:(RuntimeStack*)inStack args:(NSArray*)args
{
	if ( symClass == NCFUNCTION ) {	
		if ( function ) [ function execute:inStack initArguments:args ] ;
		return ;
	}
	if ( symClass == NCSYSTEM ) {
		printf( "evalFunctionAsVoid should never call a system function?\n" ) ;
		return ;
	}
}

//  v0.52 -- arguments of user defined function
//	v0.54 --  changed to short instead of char
//  The char string contains types (e.e., INTTYPE, ELEMENTTYPE) and terminated by 0.
- (void)setArgPrototypes:(short*)prototypes
{
	int i ;
	
	for ( i = 0; i < 64; i++ ) {
		argPrototypes[i] = prototypes[i] ;
		if ( prototypes[i] == 0 ) return ;
	}
	argPrototypes[i] = 0 ;
}

- (short*)argPrototypes
{
	return argPrototypes ;
}

- (Boolean)isFunction
{
	return YES ;
}

- (Boolean)isRunModelFunction
{
	return [ name isEqualToString:@"runModel" ] ;
}

- (void)runBlock:(RuntimeStack*)stack
{
	if ( symClass != NCFUNCTION || function == nil ) return ;
	[ function execute:stack asReference:NO ] ;
}


@end
