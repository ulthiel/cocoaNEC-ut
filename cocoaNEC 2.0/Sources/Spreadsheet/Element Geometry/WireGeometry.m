//
//  WireGeometry.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/7/07.
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


#import "WireGeometry.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "CurrentSource.h" 

@implementation WireGeometry

- (NSString*)typeString
{
	return WireTypeString ;
}

- (NSTextField*)transformField
{
	return wireTransform ;
}

//  v0.55
- (int)excitationSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field
{
	return [ self excitationSegment:matrix segNumber:field segments:[ wireProperties cellAtRow:1 column:0 ] ] ;
}

//	v0.55
- (NSString*)ncForGeometry:(int)index
{
	NSMutableString *result ;
	
	elementIndex = index ;
	result = [ NSMutableString stringWithCapacity:128 ] ;
	[ result appendFormat:@"_e%d = wireCard(", index ] ;				//  v0.75e
	[ result appendArguments:wireCoord1 count:3 addition:@"," ] ;
	[ result appendArguments:wireCoord2 count:3 addition:@"," ] ;
	[ result appendArguments:wireProperties count:2 addition:@"," ] ;
	[ result appendTransform:[ wireTransform stringValue ] addition:@");\n" ] ;

	return result ;
}

- (NSString*)coordRow:(int)row matrix:(NSMatrix*)matrix
{
	return [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
}

- (void)setCoordRow:(int)row matrix:(NSMatrix*)matrix string:(NSString*)value
{
	[ [ matrix cellAtRow:row column:0 ] setStringValue:value ] ;
	dirty = YES ;
}

- (NSString*)componentOfEnd1:(int)index
{
	return [ self coordRow:index matrix:wireCoord1 ] ; 
}

- (void)setComponentOfEnd1:(int)index string:(NSString*)str 
{
	[ self setCoordRow:index matrix:wireCoord1 string:str ] ;
	dirty = YES ;
}

- (NSString*)componentOfEnd2:(int)index
{
	return [ self coordRow:index matrix:wireCoord2 ] ; 
}

- (void)setComponentOfEnd2:(int)index string:(NSString*)str 
{
	[ self setCoordRow:index matrix:wireCoord2 string:str ] ;
	dirty = YES ;
}

- (NSString*)radiusFormula
{
	return [ self coordRow:0 matrix:wireProperties ] ;
}

- (void)setRadiusFormula:(NSString*)str
{
	[ self setCoordRow:0 matrix:wireProperties string:str ] ;
	dirty = YES ;
}

- (NSString*)segmentsFormula
{
	return [ self coordRow:1 matrix:wireProperties ] ;
}

- (void)setSegmentsFormula:(NSString*)str
{
	[ self setCoordRow:1 matrix:wireProperties string:str ] ;
	dirty = YES ;
}

//	cell where number of segments is defined
- (id)fieldForNumberOfSegments
{
	return [ wireProperties cellAtRow:1 column:0 ] ;
}

//	cell where wire radius is defined
- (id)fieldForWireRadius
{
	return [ wireProperties cellAtRow:0 column:0 ] ;
}

//	cell where x,y,z coordinate of wire is defined
- (id)fieldForCoordinate1:(int)component
{
	return [ wireCoord1 cellAtRow:component column:0 ] ;
}

//	cell where x,y,z coordinate of wire is defined
- (id)fieldForCoordinate2:(int)component
{
	return [ wireCoord2 cellAtRow:component column:0 ] ;
}

//  evaluate info from formulas and return 
- (WireInfo*)info
{
	int i ;

	info.segments = [ self numberOfSegments ] ;
	info.radius = [ self wireRadius ] ;
	for ( i = 0; i < 3; i++ ) info.from[i] = [ self valueOfCoordinate1:i ] ;
	for ( i = 0; i < 3; i++ ) info.to[i] = [ self valueOfCoordinate2:i ] ;

	info.tag = startingTag ;
	
	info.excitationLocation = 0 ;
	info.excitationKind = [ [ [ exMenu selectedTabViewItem ] identifier ] intValue ] ;
	
	switch ( info.excitationKind ) {
	default:
		break ;
	case 1:
		//  voltage
		info.excitationLocation = [ self excitationSegment:exLocationMatrix segNumber:exLocationSegment ] ;
		for ( i = 0; i < 2; i++ ) info.excitationVector[i] = [ (ApplicationDelegate*)[ NSApp delegate ] doubleValueForObject:[ exVoltageMatrix cellAtRow:i column:0 ] ] ;
		break ;
	case 2:
		//  current
		info.excitationLocation = [ self excitationSegment:curLocationMatrix segNumber:curLocationSegment ] ;
		for ( i = 0; i < 2; i++ ) info.excitationVector[i] = [ (ApplicationDelegate*)[ NSApp delegate ] doubleValueForObject:[ currentMatrix cellAtRow:i column:0 ] ] ;
		break ;
	}
	return &info ;
}

- (Boolean)empty
{
	int i ;
	
	for ( i = 0; i < 3; i++ ) if ( [ [ self coordRow:i matrix:wireCoord1 ] length ] > 0 ) return NO ;
	for ( i = 0; i < 3; i++ ) if ( [ [ self coordRow:i matrix:wireCoord2 ] length ] > 0 ) return NO ;
	for ( i = 0; i < 2; i++ ) if ( [ [ self coordRow:i matrix:wireProperties ] length ] > 0 ) return NO ;	
	return YES ;
}

- (NSArray*)networkForExcitationCards 
{
	printf( "networks for excitationcards -- deprecated\n" ) ;
	return [ NSArray array ] ;
}

//  v0.41 warn instead of forcing number of segments to 3
- (void)tooFewSegments
{
	[ AlertExtension modalAlert:@"Too few segments in wire." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nDue to a bug in nec2c, a wire that has an excitation or a load must have at least 3 segments.  No exitation will be generated.\n" ] ;
}

- (NSArray*)excitationCards:(Expression*)e 
{
	printf( "WireGeometry:excitationCards - deprecated.\n" ) ;
	return [ NSArray array ] ;
}

- (NSArray*)loadingCards:(Expression*)e 
{
	printf( "WireGeometry:loadingCards - deprecated\n" ) ;
	return [ NSArray array ] ;
}

- (double)maxDimension
{
	double p, q ;
	int i ;
	
	[ self info ] ;
	p = fabs ( info.from[0] ) ;
	for ( i = 1; i < 3; i++ ) {
		q = fabs ( info.from[i] ) ;
		if ( q > p ) p = q ;
	}
	for ( i = 0; i < 3; i++ ) {
		q = fabs ( info.to[i] ) ;
		if ( q > p ) p = q ;
	}
	return p ;
}

//  create plist array for wire
- (NSMutableDictionary*)makePlist 
{
	if ( [ self empty ] ) return nil ;	
	plist = [ self createGeometryForPlist ] ;
	[ plist setObject:[ self arrayForMatrix:wireCoord1 count:3 ] forKey:@"coord1" ] ;
	[ plist setObject:[ self arrayForMatrix:wireCoord2 count:3 ] forKey:@"coord2" ] ;
	[ plist setObject:[ self arrayForMatrix:wireProperties count:2 ] forKey:@"properties" ] ;
	[ plist setObject:[ wireTransform stringValue ] forKey:@"transform" ] ;
	[ self addExcitationToDict:plist ] ;
	[ self addLoadToDict:plist ] ;
	return plist ;
}

//  create wire card from plist array
- (void)restoreGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	NSString *string ;
	
	[ self restoreCommonGeometryFieldsFromDictionary:dict ] ;
	[ self setMatrix:wireCoord1 fromArray:[ dict objectForKey:@"coord1" ] count:3 ] ;
	[ self setMatrix:wireCoord2 fromArray:[ dict objectForKey:@"coord2" ] count:3 ] ;
	[ self setMatrix:wireProperties fromArray:[ dict objectForKey:@"properties" ] count:2 ] ;
	string = [ dict objectForKey:@"transform" ] ;
	if ( string == nil ) string = @"" ;
	[ wireTransform setStringValue:string ] ;
	[ self restoreExcitation:[ dict objectForKey:@"excitation" ] ] ;
	[ self restoreLoad:[ dict objectForKey:@"loading" ]  ] ;
	dirty = NO ;
}

@end
