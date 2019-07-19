//
//  HelixGeometry.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/8/07.
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

#import "HelixGeometry.h"
#import "ApplicationDelegate.h"


@implementation HelixGeometry

- (NSString*)typeString
{
	return HelixTypeString ;
}

- (NSTextField*)transformField
{
	return helixTransform ;
}

- (int)numberOfSegments:(Expression*)e
{
	return [ self evalInt:helixIntMatrix row:0 cellName:"number of segments" ] ;
}

//	v0.55
- (int)excitationSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field
{
	return [ self excitationSegment:matrix segNumber:field segments:[ helixIntMatrix cellAtRow:0 column:0 ] ] ;
}

//	v0.55
- (NSString*)ncForGeometry:(int)index
{
	NSMutableString *result ;
	
	result = [ NSMutableString stringWithCapacity:128 ] ;
	[ result appendFormat:@"_e%d = helixCard(", index ] ;
	[ result appendArguments:helixFloatMatrix count:7 addition:@"," ] ;
	[ result appendArguments:helixIntMatrix count:1 addition:@"," ] ;
	[ result appendTransform:[ helixTransform stringValue ] addition:@");\n" ] ;

	return result ;
}

//  create plist array for helix
- (NSMutableDictionary*)makePlist 
{
	plist = [ self createGeometryForPlist ] ;
	[ plist setObject:[ self arrayForMatrix:helixIntMatrix count:1 ] forKey:@"ints" ] ;
	[ plist setObject:[ self arrayForMatrix:helixFloatMatrix count:7 ] forKey:@"floats" ] ;
	[ plist setObject:[ helixTransform stringValue ] forKey:@"transform" ] ;
	[ self addExcitationToDict:plist ] ;
	[ self addLoadToDict:plist ] ;
	return plist ;
}

//  create helix card from plist array
- (void)restoreGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	NSString *string ;
	
	[ self restoreCommonGeometryFieldsFromDictionary:dict ] ;
	[ self setMatrix:helixIntMatrix fromArray:[ dict objectForKey:@"ints" ] count:1 ] ;
	[ self setMatrix:helixFloatMatrix fromArray:[ dict objectForKey:@"floats" ] count:7 ] ;
	string = [ dict objectForKey:@"transform" ] ;
	if ( string == nil ) string = @"" ;
	[ helixTransform setStringValue:string ] ;
	[ self restoreExcitation:[ dict objectForKey:@"excitation" ] ] ;
	[ self restoreLoad:[ dict objectForKey:@"loading" ]  ] ;
	dirty = NO ;
}

@end
