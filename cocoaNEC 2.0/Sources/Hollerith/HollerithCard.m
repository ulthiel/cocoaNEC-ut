//
//  HollerithCard.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/20/07.
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

#import "HollerithCard.h"


@implementation HollerithCard


- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		image = note = nil ;
		ignore = NO ;
	}
	return self ;
}

- (NSString*)imageField
{
	return ( image != nil ) ? image : @"" ;
}

- (void)setImage:(NSString*)str
{
	if ( image ) [ image release ] ;
	image = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)ignoreField
{
	return ( ignore ) ? @"*" : @"" ;
}

- (Boolean)ignore
{
	return ignore ;
}

- (void)setIgnore:(NSString*)str
{
	intType length ;
    
	ignore = NO ;
	
	if ( str == nil ) return ;
	length = [ str length ] ;
	if ( length == 0 ) return ;
	
	if ( length == 1 ) {
		ignore = ( [ str characterAtIndex:0 ] == '*' ) ;
		return ;
	}
	ignore = ( [ str characterAtIndex:0 ] == '*' || [ str characterAtIndex:1 ] == '*' ) ;
}

- (NSString*)noteField
{
	return ( note != nil ) ? note : @"" ;
}

- (void)setNote:(NSString*)str
{
	if ( note ) [ note release ] ;
	note = [ [ NSString alloc ] initWithString:str ] ;
}

@end
