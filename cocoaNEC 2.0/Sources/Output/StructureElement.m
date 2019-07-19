//
//  StructureElement.m
//  cocoaNEC
//
//  Created by Kok Chen on 4/14/08.
//	-----------------------------------------------------------------------------
//  Copyright 2008-2016 Kok Chen, W7AY. 
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

#import "StructureElement.h"


@implementation StructureElement

//	v0.75g: modified to work with NEC-4's output for Helix
- (Boolean)parseStructure:(char*)string wireNumber:(int)wireNumber segments:(int)segments start:(int)start tag:(int)tag
{
	int wire ;
	NSString *check ;
	
	if ( strlen( string ) < 16 ) return NO ;
	wire = -1 ;
	check = [ NSString stringWithUTF8String:string ] ;

	if ( [ check rangeOfString:@"ARC RADIUS:" ].location != NSNotFound ) {
		float arcRadius, startAngle, endAngle ;
		//  GA card
		g.end[0].x = g.end[0].y = g.end[0].z = g.end[1].x = g.end[1].y = g.end[1].z = 0.0 ;
		sscanf( string, "%d  ARC RADIUS:%f  FROM:%f TO:%f DEGREES%f %d %d %d %d", &wire, &arcRadius, &startAngle, &endAngle, &g.radius, &g.segments, &g.startSegment, &g.endSegment, &g.tag ) ;
		if ( wire < 0 ) return NO ;
		if ( g.segments <= 0 ) g.segments = 1 ;
		g.wire = wire ;
		return YES ;
	}

	if ( [ check rangeOfString:@"HELIX STRUCTURE" ].location != NSNotFound ) {
		float spacing, length ;
		//  GH card for NEC-2
		//	HELIX STRUCTURE - SPACING OF TURNS:    0.700 AXIAL LENGTH:    0.500     0.001
		g.end[0].x = g.end[0].y = g.end[0].z = g.end[1].x = g.end[1].y = g.end[1].z = 0.0 ;
		sscanf( string, "%d HELIX STRUCTURE - SPACING OF TURNS: %f AXIAL LENGTH: %f %f %d %d %d %d", &wire, &spacing, &length, &g.radius, &g.segments, &g.startSegment, &g.endSegment, &g.tag ) ;
		if ( wire < 0 ) return NO ;
		if ( g.segments <= 0 ) g.segments = 1 ;
		g.wire = wire ;
		return YES ;
	}
	
	if ( [ check rangeOfString:@"SPIRAL DATA" ].location != NSNotFound ) {
		//  GH card for NEC-4
		//	SPIRAL DATA: TURNS=    0.7000  LENGTH=  5.0000E-01  H.RAD=  1.0000E+00  1.0000E+00  W.RAD=  1.0000E+00  1.0000E+00
		g.end[0].x = g.end[0].y = g.end[0].z = g.end[1].x = g.end[1].y = g.end[1].z = 0.0 ;
		g.segments = segments ;
		g.wire = wireNumber ;
		g.startSegment = start ;
		g.endSegment = start + segments - 1 ;
		g.tag = tag ;
		return YES ;
	}

	if ( [ check rangeOfString:@"STRUCTURE ROTATED" ].location != NSNotFound ) {
		//  GR cards are processed by OutputContext.m
		return NO ;
	}

	if ( [ check rangeOfString:@"STRUCTURE REFLECTED" ].location != NSNotFound ) {
		//  GX cards are processed by OutputContext.m
		return NO ;
	}
	
	sscanf( string, "%d %f %f %f %f %f %f %f %d %d %d %d", &wire, &g.end[0].x, &g.end[0].y, &g.end[0].z, &g.end[1].x, &g.end[1].y, &g.end[1].z, &g.radius, &g.segments, &g.startSegment, &g.endSegment, &g.tag ) ;
	if ( wire < 0 ) return NO ;
	if ( g.segments <= 0 ) g.segments = 1 ;
	g.wire = wire ;
	return YES ;
}

- (id)initWithLine:(char*)string
{
	self = [ super init ] ;
	if ( self ) {
		if ( ![ self parseStructure:string wireNumber:0 segments:0 start:0 tag:0 ] ) {
			[ self autorelease ] ;
			return nil ;
		}
	}
	return self ;
}

//	For NEC-4 to include wire number
- (id)initWithLine:(char*)string wireNumber:(int)wireNumber segments:(int)segments start:(int)start tag:(int)tag
{
	self = [ super init ] ;
	if ( self ) {
		if ( ![ self parseStructure:string wireNumber:wireNumber segments:segments start:start tag:tag ] ) {
			[ self autorelease ] ;
			return nil ;
		}
	}
	return self ;
}

- (id)initWithStructureElement:(StructureElement*)old
{
	self = [ super init ] ;
	if ( self ) {
		g = *[ old info ] ;		//  make copy
	}
	return self ;
}

- (StructureInfo*)info
{
	return &g ;
}

- (int)tag
{
	return g.tag ;
}

@end
