//
//  StringUtils.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/27/10.
//	-----------------------------------------------------------------------------
//  Copyright 2010-2016 Kok Chen, W7AY. 
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

#import "StringUtils.h"


@implementation StringUtils

//  v0.65 -- Xcode 3.2.1 SDK has problem with selecting cells with only spaces

//  prepend space only if the string is not empty
+ (NSString*)prependSpace:(NSString*)str
{
	if ( [ str length ] > 0 ) return [ @" " stringByAppendingString:str ] ;
	return @"" ;
}


@end
