//
//  NCCard.m
//  cocoaNEC
//
//  Created by Kok Chen on 5/30/09.
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

#import "NCCard.h"


@implementation NCCard


//  NCCards are saved in an NCFunctionObject
- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		tag = 0 ;
		type[0] = '*' ;
		type[1] = '*' ;
		type[2] = 0 ;
	}
	return self ;
}

- (void)setCardType:(char*)value
{
	type[0] = value[0] ;
	type[1] = value[1] ;
	type[2] = 0 ;
}

@end
