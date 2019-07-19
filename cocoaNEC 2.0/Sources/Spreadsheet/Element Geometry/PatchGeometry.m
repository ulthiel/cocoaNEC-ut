//
//  PatchGeometry.m
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


#import "PatchGeometry.h"


@implementation PatchGeometry

- (NSString*)typeString
{
	return PatchTypeString ;
}

- (NSTextField*)transformField
{
	return patchTransform ;
}

- (NSString*)ncForGeometry:(int)index
{
	NSMutableString *result ;
	
	elementIndex = index ;
	
	result = [ NSMutableString stringWithCapacity:128 ] ;
	switch ( [ patchShape indexOfSelectedItem ] ) {
	case 1:
		[ result appendFormat:@"_e%d = rectangularPatchCard(", index ] ;
		[ result appendArguments:patchFloatMatrix1 count:6 addition:@"," ] ;
		[ result appendArguments:patchFloatMatrix2 count:3 addition:@"," ] ;
		[ result appendTransform:[ patchTransform stringValue ] addition:@");\n" ] ;
		break ;
	case 2:
		[ result appendFormat:@"_e%d = triangularPatchCard(", index ] ;
		[ result appendArguments:patchFloatMatrix1 count:6 addition:@"," ] ;
		[ result appendArguments:patchFloatMatrix2 count:3 addition:@"," ] ;
		[ result appendTransform:[ patchTransform stringValue ] addition:@");\n" ] ;
		break ;
	case 3:
		[ result appendFormat:@"_e%d = quadrilateralPatchCard(", index ] ;
		[ result appendArguments:patchFloatMatrix1 count:6 addition:@"," ] ;
		[ result appendArguments:patchFloatMatrix2 count:6 addition:@"," ] ;
		[ result appendTransform:[ patchTransform stringValue ] addition:@");\n" ] ;
		break ;
	default:
		[ result appendFormat:@"_e%d = patchCard(", index ] ;
		[ result appendArguments:patchFloatMatrix1 count:6 addition:@"," ] ;
		[ result appendTransform:[ patchTransform stringValue ] addition:@");\n" ] ;
	}
	return result ;
}

//  create plist array for patch
- (NSMutableDictionary*)makePlist 
{
	plist = [ self createGeometryForPlist ] ;
	[ plist setObject:[ patchShape titleOfSelectedItem ] forKey:@"patchShape" ] ;
	[ plist setObject:[ self arrayForMatrix:patchFloatMatrix1 count:6 ] forKey:@"patchMatrix1" ] ;
	[ plist setObject:[ self arrayForMatrix:patchFloatMatrix2 count:6 ] forKey:@"patchMatrix2" ] ;
	[ plist setObject:[ patchTransform stringValue ] forKey:@"transform" ] ;
	[ self addExcitationToDict:plist ] ;
	[ self addLoadToDict:plist ] ;
	return plist ;
}

//  create patch card from plist array
- (void)restoreGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	NSObject *object ;
	NSString *string ;
	int index ;
	
	[ self restoreCommonGeometryFieldsFromDictionary:dict ] ;
	
	//  v0.55  attempt compatibility with pre v0.55 patches
	object = [ dict objectForKey:@"patchShape" ] ;
	if ( object != nil ) {
		[ patchShape selectItemWithTitle:[ dict objectForKey:@"patchShape" ] ] ;
	}
	else {
		index = [ [ dict objectForKey:@"patchShape1" ] intValue ] ;
		[ patchShape selectItemAtIndex:index ] ;
	}
	if ( [ patchShape indexOfSelectedItem ] < 0 ) {
		[ patchShape selectItemAtIndex:0 ] ;
	}
	
	[ self setMatrix:patchFloatMatrix1 fromArray:[ dict objectForKey:@"patchMatrix1" ] count:6 ] ;
	[ self setMatrix:patchFloatMatrix2 fromArray:[ dict objectForKey:@"patchMatrix2" ] count:6 ] ;
	string = [ dict objectForKey:@"transform" ] ;
	if ( string == nil ) string = @"" ;
	[ patchTransform setStringValue:string ] ;
	[ self restoreExcitation:[ dict objectForKey:@"excitation" ] ] ;
	[ self restoreLoad:[ dict objectForKey:@"loading" ]  ] ;
	dirty = NO ;
}

@end
