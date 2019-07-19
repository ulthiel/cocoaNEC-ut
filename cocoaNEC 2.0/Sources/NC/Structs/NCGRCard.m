//
//  NCGRCard.m
//  cocoaNEC
//
//  Created by Kok Chen on 5/31/09.
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

#import "NCGRCard.h"


@implementation NCGRCard

//  handles both GR andGX cards
- (NSArray*)geometryCards
{
	NSString *card ;
	
	//  v0.86
    //  v0.88
    card = [ [ NSString alloc ] initWithFormat:[ Config formatWithType:"%2s%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
        type, i1, i2, "", "", "", "", "", "", "" ] ;

    return [ NSArray arrayWithObjects:card, nil ] ;
}

@end
