//
//  ArcGeometry.m
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


#import "ArcGeometry.h"

@implementation ArcGeometry

- (NSString*)typeString
{
	return ArcTypeString ;
}

- (NSTextField*)transformField
{
	return arcTransform ;
}

- (int)numberOfSegments:(Expression*)e
{
	return [ self evalInt:arcIntMatrix row:0 cellName:"number of segments" ] ;
}

- (int)excitationSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field
{
	return [ self excitationSegment:matrix segNumber:field segments:[ arcIntMatrix cellAtRow:0 column:0 ] ] ;
}

- (NSString*)ncForGeometry:(int)index
{
	NSMutableString *result ;
	
	elementIndex = index ;
	
	result = [ NSMutableString stringWithCapacity:128 ] ;
	[ result appendFormat:@"_e%d = arcCard(", index ] ;
	[ result appendArguments:arcFloatMatrix count:4 addition:@"," ] ;
	[ result appendArguments:arcIntMatrix count:1 addition:@"," ] ;
	[ result appendTransform:[ arcTransform stringValue ] addition:@");\n" ] ;

	return result ;
}

//  create plist array for arc
- (NSMutableDictionary*)makePlist 
{
	plist = [ self createGeometryForPlist ] ;
	[ plist setObject:[ self arrayForMatrix:arcIntMatrix count:1 ] forKey:@"ints" ] ;
	[ plist setObject:[ self arrayForMatrix:arcFloatMatrix count:4 ] forKey:@"floats" ] ;
	[ plist setObject:[ arcTransform stringValue ] forKey:@"transform" ] ;
	[ self addExcitationToDict:plist ] ;
	[ self addLoadToDict:plist ] ;
	return plist ;
}

//  create arc card from plist array
- (void)restoreGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	NSString *string ;
	
	[ self restoreCommonGeometryFieldsFromDictionary:dict ] ;
	[ self setMatrix:arcIntMatrix fromArray:[ dict objectForKey:@"ints" ] count:1 ] ;
	[ self setMatrix:arcFloatMatrix fromArray:[ dict objectForKey:@"floats" ] count:4 ] ;
	string = [ dict objectForKey:@"transform" ] ;
	if ( string == nil ) string = @"" ;
	[ arcTransform setStringValue:string ] ;
	[ self restoreExcitation:[ dict objectForKey:@"excitation" ] ] ;
	[ self restoreLoad:[ dict objectForKey:@"loading" ]  ] ;
	dirty = NO ;
}


@end
