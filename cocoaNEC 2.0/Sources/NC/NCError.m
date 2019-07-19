//
//  NCError.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/15/07.
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

#import "NCError.h"


@implementation NCError

- (id)initWithPointer:(const unsigned char*)ptr string:(NSString*)error line:(int)atline
{
	self = [ super init ] ;
	if ( self ) {
		errorPtr = ptr ;
		errorString = error ;
		line = atline ;
	}
	return self ;
}

//  object for recording errors
+ (id)errorWithPointer:(const unsigned char*)ptr string:(NSString*)error line:(int)atline
{
	NCError *result ;
	
	result = [ [ NCError alloc ] initWithPointer:ptr string:error line:atline ] ;
	if ( !result ) return nil ;
	return [ result autorelease ] ;
}

- (const unsigned char*)pointer
{
	return errorPtr ;
}

- (NSString*)string
{
	return errorString ;
}

- (int)line
{
	return line ;
}

@end
