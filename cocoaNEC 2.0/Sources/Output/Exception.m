//
//  Exception.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/23/07.
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

#import "Exception.h"
#import "WireTypes.h"


@implementation Exception

//  Exceptions have a NEC-2 tag and a wireType
//	This allows the geometry view to process them as special cases:
//		- ignore radials if the output options says so
//		- handle current segments differently

- (id)initWithRadial:(intType)wireTag
{
	self = [ super init ] ;
	if ( self ) {
		wireType = RADIALEXCEPTION ;
		tag = wireTag ;
	}
	return self ;
}

- (id)initWithCurrentSource:(intType)wireTag targetTag:(intType)targetTag targetSegment:(intType)targetSegment
{
	self = [ super init ] ;
	if ( self ) {
		wireType = CURRENTEXCEPTION ;
		tag = wireTag ;
		tagOfTarget = targetTag ;
		segmentOfTarget = targetSegment ;
	}
	return self ;
}

//	v0.81
//	This flags the Geometry view to not draw wire
- (id)initWithTermination:(intType)wireTag targetTag:(intType)targetTag targetSegment:(int)targetSegment
{
	self = [ super init ] ;
	if ( self ) {
		wireType = TERMINATIONEXCEPTION ;
		tag = wireTag ;
		tagOfTarget = targetTag ;
		segmentOfTarget = targetSegment ;
	}
	return self ;
}

+ (id)exceptionForRadial:(intType)wireTag
{
	Exception *exception ;
	
	exception = [ [ Exception alloc ] initWithRadial:wireTag ] ;
	return [ exception autorelease ] ;
}

+ (id)exceptionForCurrentSource:(intType)wireTag targetTag:(intType)targetTag targetSegment:(intType)targetSegment
{
	Exception *exception ;
	
	exception = [ [ Exception alloc ] initWithCurrentSource:wireTag targetTag:targetTag targetSegment:targetSegment ] ;
	return [ exception autorelease ] ;
}

+ (id)exceptionForTermination:(intType)wireTag targetTag:(intType)targetTag targetSegment:(int)targetSegment
{
	Exception *exception ;
	
	exception = [ [ Exception alloc ] initWithTermination:wireTag targetTag:targetTag targetSegment:targetSegment ] ;
	return [ exception autorelease ] ;
}

- (intType)wireType
{
	return wireType ;
}

- (intType)tag
{
	return tag ;
}

- (intType)tagOfTarget
{
	return tagOfTarget ;
}

- (intType)segmentOfTarget
{
	return segmentOfTarget ;
}

@end
