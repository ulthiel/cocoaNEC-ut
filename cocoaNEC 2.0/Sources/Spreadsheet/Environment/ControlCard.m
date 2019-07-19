//
//  ControlCard.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/15/07.
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

#import "ControlCard.h"

@implementation ControlCard

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		hollerith = nil ;
	}
	return self ;
}

- (NSString*)hollerith
{
	return ( ( !hollerith ) ? @"" : hollerith ) ;
}

- (void)setHollerith:(NSString*)str
{
	if ( hollerith ) [ hollerith autorelease ] ;
	hollerith = [ [ NSString alloc ] initWithString:str ] ;
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

- (NSString*)ignoreField
{
	return ( ignore ) ? @"*" : @"" ;
}

- (void)setIgnore:(NSString*)str
{
	intType length ;
	
	if ( str != nil ) {
		length = [ str length ] ;
		if ( length == 1 || length == 2 ) {
			ignore = ( [ str characterAtIndex:length-1 ] == '*' ) ;
			return ;
		}
	}
	ignore = NO ;
}

- (Boolean)ignoreCard
{
	return ignore ;
}

- (NSDictionary*)dictForCard
{
	NSMutableDictionary *dict ;
	
	dict = [ [ NSMutableDictionary alloc ] init ] ;
	[ dict setObject:[ [ self hollerith ] uppercaseString ] forKey:@"hollerith" ] ;
	[ dict setObject:[ self ignoreField ] forKey:@"ignore" ] ;
	[ dict setObject:[ self comment ] forKey:@"comment" ] ;
	return dict ;
}

- (void)setCardFromDict:(NSDictionary*)dict
{
	[ self setHollerith:[ dict objectForKey:@"hollerith" ] ] ;
	[ self setIgnore:[ dict objectForKey:@"ignore" ] ] ;
	[ self setComment:[ dict objectForKey:@"comment" ] ] ;
}

@end
