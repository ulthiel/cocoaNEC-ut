//
//  TransformObject.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/19/09.
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

#import "TransformObject.h"


@implementation TransformObject

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		name = nil ;
		transform = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		for ( i = 0; i < 6; i++ ) [ transform insertObject:@"0" atIndex:i ] ;
		plist = nil ;
	}
	return self ;
}

- (void)dealloc
{
	if ( name ) [ name autorelease ] ;
	[ transform autorelease ] ;
	[ super dealloc ] ;
}

- (Boolean)empty
{
	int i ;
	
	if ( name && [ name length ] > 0 )  return NO ;
	for ( i = 0; i < 6; i++ ) {
		if ( [ [ transform objectAtIndex:i ] length ] > 0 ) return NO ;
	}
	return YES ;
}

- (NSString*)name
{
	return ( ( !name ) ? @"" : name ) ;
}

- (void)setName:(NSString*)str
{
	if ( name ) [ name autorelease ] ;
	name = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)valueAtIndex:(int)i
{
	return [ transform objectAtIndex:i ] ;
}

- (void)setValue:(NSString*)str atIndex:(int)i
{
	if ( str == nil ) str = @"" ;
	[ transform replaceObjectAtIndex:i withObject:str ] ;
}

- (NSArray*)transform
{
	return transform ;
}

- (NSMutableDictionary*)makeTransform 
{
	if ( [ self empty ] == NO ) {
		plist = [ [ NSMutableDictionary alloc ] init ] ;
		[ plist setValue:[ self name ] forKey:@"name" ] ;
		[ plist setValue:transform forKey:@"transform" ] ;
		return plist ;
	}
	return nil ;
}

- (void)releaseTransform
{
	if ( plist ) {
		[ plist removeAllObjects ] ;
		[ plist release ] ;
		plist = nil ;
	}
}

- (void)restoreTransform:(NSDictionary*)dict
{
	NSArray *array ;
	int i ;
	
	[ self setName:[ dict valueForKey:@"name" ] ] ;
	array = [ dict valueForKey:@"transform" ] ;
	for ( i = 0; i < 6; i++ ) [ self setValue:[ array objectAtIndex:i ] atIndex:i ] ;
}

@end
