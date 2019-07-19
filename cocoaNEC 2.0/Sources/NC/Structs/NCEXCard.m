//
//  NCEXCard.m
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

#import "NCEXCard.h"


@implementation NCEXCard

- (id)initWithRuntime:(RuntimeStack*)rt
{
	self = [ super initWithRuntime:rt ] ;
	if ( self ) {
		i1 = 0 ;
		generate = 0 ;
	}
	return self ;
}

//	generate =	0	Excitation
//				1	Load
//				2	NetWork
- (void)setGenerate:(int)state 
{
	generate = state ;
}

- (NSArray*)geometryCards
{
	//  return no geometry cards
	return [ NSArray array ] ;
}

//	EX card
- (NSArray*)excitationCards
{
	NSString *card ;
	
	if ( generate != EXCITATIONCARD ) return [ NSArray array ] ;
	//  v0.86
    //  v0.88
    card = [ [ NSString alloc ] initWithFormat:[ Config formatWithType:"%2s%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
            type, i1, i2, i3, i4, dtos(f1), dtos(f2), dtos(f3), dtos(f4), dtos(f5), dtos(f6) ] ;

    return [ NSArray arrayWithObjects:card, nil ] ;
}

//	LD card
- (NSArray*)loadCards
{
	NSString *card ;
	
	if ( generate != LOADCARD ) return [ NSArray array ] ;
	//  v0.86
    //  v0.88
    card = [ [ NSString alloc ] initWithFormat:[ Config formatWithType:"%2s%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ], type, i1, i2, i3, i4, dtos(f1), dtos(f2), dtos(f3), "", "", "" ] ;

    return [ NSArray arrayWithObjects:card, nil ] ;
}

- (NSArray*)networkCards
{
	NSString *card ;
	
	if ( generate != NETWORKCARD ) return [ NSArray array ] ;
	//  v0.86
    //  v0.88
    card = [ [ NSString alloc ] initWithFormat:[ Config formatWithType:"%2s%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
            type, i1, i2, i3, i4, dtos(f1), dtos(f2), dtos(f3), dtos(f4), dtos(f5), dtos(f6) ] ;

    return [ NSArray arrayWithObjects:card, nil ] ;
}

@end
