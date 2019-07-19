//
//  NCElement.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/20/07.
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

#import "NCElement.h"


@implementation NCElement

- (NSArray*)geometryCards
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

- (NSArray*)excitationCards
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

- (NSArray*)networkCardsForCurrentExcitation
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

- (NSArray*)loadCards
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

//	v0.81
- (double)segmentLength
{
	//  override by NCWire
	return 1e6 ;
}

//	v0.75a
- (NSArray*)loadCardsForInsulatedWire
{
	printf( "loadCardsForInsulatedWire called but not override by NCWire\n" ) ;
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

- (NSArray*)networkCardsForFrequency:(double)frequency
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

- (NSArray*)currentGeometryCards:(int)tags
{
	//  override by subclasses that are concrete Geometry Elements
	return [ NSArray array ] ;
}

@end
