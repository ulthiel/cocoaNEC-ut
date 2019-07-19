//
//  VariableObject.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/4/07.
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


#import "VariableObject.h"


//  An object of this class manages the data for each row of the Variables tableView.

@implementation VariableObject

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		name = value = comment = nil ;
		primary = nil ;
		plist = nil ;
	}
	return self ;
}

- (void)dealloc
{
	if ( name ) [ name autorelease ] ;
	if ( value ) [ value autorelease ] ;
	if ( comment ) [ comment autorelease ] ;
	if ( primary ) [ primary autorelease ] ;
	[ super dealloc ] ;
}

- (Boolean)empty
{
	if ( name && [ name length ] > 0 )  return NO ;
	if ( value && [ value length ] > 0 )  return NO ;
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

- (NSString*)value
{
	return ( ( !value ) ? @"" : value ) ;
}

- (Primary*)primaryValue
{
	if ( primary == nil ) primary = [ [ Primary alloc ] initWithDoubleString:[ self value ] ] ;
	return primary ;
}

- (void)setValue:(NSString*)str
{
	if ( value ) [ value autorelease ] ;
	value = [ [ NSString alloc ] initWithString:str ] ;
	[ primary autorelease ] ;
	primary = [ [ Primary alloc ] initWithDoubleString:value ] ;
}

- (NSString*)comment 
{
	return ( ( !comment ) ? @"" : comment ) ;
}

- (void)setComment:(NSString*)str
{
	if ( comment ) [ comment autorelease ] ;
	comment = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSMutableDictionary*)makeVariable 
{
	if ( name || value || comment ) {
		plist = [ [ NSMutableDictionary alloc ] init ] ;
		[ plist setValue:[ self name ] forKey:@"name" ] ;
		[ plist setValue:[ self value ] forKey:@"value" ] ;
		[ plist setValue:[ self comment ] forKey:@"comment" ] ;		
		return plist ;
	}
	return nil ;
}

- (void)releaseVariable
{
	if ( plist ) {
		[ plist removeAllObjects ] ;
		[ plist release ] ;
		plist = nil ;
	}
}

- (void)restoreVariable:(NSDictionary*)dict
{
	[ self setName:[ dict valueForKey:@"name" ] ] ;
	[ self setValue:[ dict valueForKey:@"value" ] ] ;
	[ self setComment:[ dict valueForKey:@"comment" ] ] ;
}

@end
