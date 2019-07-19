//
//  NCMultiplePatch.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/21/09.
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

#import "NCMultiplePatch.h"


@implementation NCMultiplePatch

// v0.77
- (void)setEnd3:(WireCoord*)vector
{
	end3 = *vector ;
}

- (void)setNX:(double)value
{
	nx = value ;
}

- (void)setNY:(double)value
{
	ny = value ;
}

- (NSArray*)geometryCards
{
	NSString *card1, *card2, *gmCard ;
	
	if ( tag <= 0 ) return [ NSArray array ] ;
	
	//  SM card
	//  v0.86
    //  v0.88
    card1 = [ [ NSString alloc ] initWithFormat:[ Config format:"SM%3d%5d%10s%10s%10s%10s%10s%10s" ],
             nx, ny, dtos(end1.x), dtos(end1.y), dtos(end1.z), dtos(end2.x), dtos(end2.y), dtos(end2.z) ] ;
    card2 = [ [ NSString alloc ] initWithFormat:[ Config format:"SC%3d%5d%10s%10s%10s" ],
             0, 0, dtos(end3.x), dtos(end3.y), dtos(end3.z) ] ;
	
	//  GM card
	gmCard = [ self gmCard ] ;
	if ( gmCard == nil ) [ NSArray arrayWithObjects:card1, card2, nil ] ; 	
	return [ NSArray arrayWithObjects:card1, card2, gmCard, nil ] ;
}

@end
