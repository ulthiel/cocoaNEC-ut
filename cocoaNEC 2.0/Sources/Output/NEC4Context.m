//
//  NEC4Context.m
//  cocoaNEC
//
//  Created by Kok Chen on 4/11/08.
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

#import "NEC4Context.h"
#import "Feedpoint.h"
#import "GeometryPlot.h"
#import "NEC4StructureImpedance.h"
#import "OutputGeometryElement.h"
#import "PatternElement.h"
#import "RadiationPattern.h"
#import "StructureElement.h"


//	NEC4Context subclass of OutputContext class handles the format exceptions for NEC-4 (vs nec2c).

@implementation NEC4Context

- (id)initWithName:(NSString*)str hollerith:(NSString*)hstr lpt:(NSString*)lstr source:(NSString*)src exceptions:(NSArray*)ex geometryOptions:(GeometryOptions*)options
{
	int engine4 ;
	
	engine4 = [ [ NSApp delegate ] engine ] ;
	
	self = [ super initWithName:str hollerith:hstr lpt:lstr source:[ self modifiedSourceName:src engine:engine4 ] exceptions:ex geometryOptions:options ] ;
	if ( self ) {
		engine = engine4 ;
	}
	return self ;
}

- (void)parseFeedpoint:(FILE*)f
{
	NSMutableArray *feedpointArray ;
	Feedpoint *feed ;
	char line[160] ;
	
	fgets( line, 160, f ) ;	//  skip blank line
	if ( fgets( line, 160, f ) == nil || strncmp( line, "   TAG   SEG", 12 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "   NO.", 6 ) != 0  ) return ;
	
	feedpointArray = [ NSMutableArray array ] ;  //  pass ownership of feedpointArray to araayOfFeedpointArrays
	
	while ( fgets( line, 160, f ) != nil ) {	
		feed =  [ [ Feedpoint alloc ] initWithLine:&line[0] frequency:currentFrequency exceptions:exceptions ] ;
		if ( feed == nil ) break ;
		[ feedpointArray addObject:[ feed autorelease ] ] ;
	}
	[ arrayOfFeedpointArrays addObject:feedpointArray ] ;	
}

- (void)parseGround:(FILE*)f
{
	char line[160], *s ;
	int i, blankline ;
	
	freespace = perfectGround = usesSommerfeld = NO ;
	dielectric = 10.0 ;
	conductivity = 0.04 ;
	
	blankline = 0 ;
	for ( i = 0; i < 20; i++ ) {
		if ( fgets( line, 160, f ) == nil ) return ;
		
		if ( line[0] == '\n' || line[0] == '\r' ) {
			//  return from parseGround if 3 blank lines are seen
			blankline++ ;
			if ( blankline >= 3 ) break ;
		}
		else {
			blankline = 0 ;
			s = line ;
			while ( *s == ' ' ) s++ ;
			if ( strncmp( "FREE SPACE", s, 10 ) == 0 ) {
				freespace = YES ;
				break ;
			}
			if ( strncmp( "PERFECT GROUND", s, 14 ) == 0 ) {
				perfectGround = YES ;
				break ;
			}
			if ( strncmp( "FINITE GROUND.  SOMMERFELD SOLUTION", s, 35 ) == 0 ) usesSommerfeld = YES ;
			if ( strncmp( "RELATIVE DIELECTRIC CONST.", s, 26 ) == 0 ) sscanf( s, "RELATIVE DIELECTRIC CONST.=%lf", &dielectric ) ;
			if ( strncmp( "CONDUCTIVITY=", s, 13 ) == 0 ) {
				sscanf( s, "CONDUCTIVITY=%lf", &conductivity ) ;
				break ;
			}
		}
	}
}

- (void)parseRadiationPattern:(FILE*)f
{
	PatternElement *element ;
	NSMutableArray *array ;
	RadiationPattern *pattern ;
	char line[160] ;
	int i ;
	
	for ( i = 0; i < 6; i++ ) {
		//  parse until - - ANGLES seen
		if ( fgets( line, 160, f ) == nil ) return ;
		if ( strncmp( line, "  - - ANGLES", 12 ) == 0 ) break ;
	}
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  THETA", 7 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, " DEGREES", 8 ) != 0  ) return ;
	
	array = [ [ NSMutableArray alloc ] init ] ;		//  ownership passes on to RadationPattern	
	while ( fgets( line, 160, f ) != nil ) {	
		element = [ [ PatternElement alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		[ array addObject:[ element autorelease ] ] ;
	}
	pattern = [ [ RadiationPattern alloc ] initWithArray:array frequency:currentFrequency ] ;
	[ array release ] ;
	if ( pattern == nil ) return ;					// v0.82
	[ patternArray addObject:[ pattern autorelease ] ] ;
}

//  create array of array of GeometryElement with the same tag numbers
- (void)parseCurrentLocation:(FILE*)f
{
	OutputGeometryElement *element ;
	NSMutableArray *arrayOfGeometryElements ;
	char line[160] ;
	int i, tag, currentTag = -1 ;
	
	//  record only one geometry/current set when there is a frequency sweep
	if ( frequencyCount > 1 ) return ;
	
	for ( i = 0; i < 3; i++ ) fgets( line, 160, f ) ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  SEG", 5 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  NO.", 5 ) != 0  ) return ;
		
	arrayOfGeometryElements = [ NSMutableArray array ] ;	
	while ( fgets( line, 160, f ) != nil ) {	
		element = [ [ OutputGeometryElement alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		tag = [ element tag ] ;
		
		if ( currentTag >= 0 && tag != currentTag ) {
			//  new tag seen, add element
			if ( [ arrayOfGeometryElements count ] > 0 ) [ geometryArray addObject:arrayOfGeometryElements ] ;
			//  create the next list of elements
			arrayOfGeometryElements = [ NSMutableArray array ] ;
		}
		[ arrayOfGeometryElements addObject:element ] ;
		currentTag = tag ;
		[ element release ] ;	//  ownership passed to arrayOfGeometryElements
	}
	//  collect last arrayOfGeometryElements
	if ( [ arrayOfGeometryElements count ] > 0 ) [ geometryArray addObject:arrayOfGeometryElements ] ;

	//  finally pass on to geometry plot
	[ geometryPlot updateGeometryInfo:geometryArray exceptions:exceptions options:&geometryOptions frequency:currentFrequency ] ;
}

//  create array structure specification ( "wires" )
- (void)parseStructureSpecification:(FILE*)f
{
	int i, wireNumber, segments = 0, start = 0, end, tag = 0 ;
	char line[160], check[8] ;
	StructureElement *element ;
	NSRange range ;
	
	for ( i = 0; i < 6; i++ ) fgets( line, 160, f ) ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  WIRE", 6 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  NO.", 5 ) != 0  ) return ;

	while ( fgets( line, 160, f ) != nil ) {
		wireNumber = -1 ;
		memcpy( check, line, 7 ) ;
		check[7] = 0 ;
		sscanf( check, "%d", &wireNumber ) ;
		if ( wireNumber > 0 ) {
			range = [ [ NSString stringWithCString:line encoding:NSASCIIStringEncoding ] rangeOfString:@"THIS WIRE IS AN ARCHIMEDES SPIRAL OR HELIX" ] ;
			if ( range.location != NSNotFound ) {
				//  v0.75g: Helix found
				segments = start = end = 0 ;
				sscanf( &line[range.location+range.length], "%d %d %d %d", &segments, &start, &end, &tag ) ;
				//  read next line
				fgets( line, 160, f ) ;
			}
			element = [ [ StructureElement alloc ] initWithLine:&line[0] wireNumber:wireNumber segments:segments start:start tag:tag ] ;
			if ( element != nil ) {		
				[ structureArray addObject:element ] ;
			}
			continue ;
		}
		//  look for a non empty line that 
		if ( ( strlen( line ) > 8 ) && ( line[3] != ' ' || line[4] != ' ' || line[5] != ' ' ) ) break ;
	}
}

//	v0.77 -  impedance loading format for NEC-4
- (void)parseImpedanceLoading:(FILE*)f
{
	char line[160] ;
	StructureImpedance *element ;
	
	//  skip two lines for NEC4
	fgets( line, 160, f ) ;
	fgets( line, 160, f ) ;

	if ( fgets( line, 160, f ) == nil || strncmp( line, "       LOCATION", 15 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "    ITAG", 8 ) != 0  ) return ;
	
	while ( 1 ) {
		//  skip blank line between loads in NEC-4
		fgets( line, 160, f ) ;
		if ( fgets( line, 160, f ) == nil ) break ;
		element = [ [ NEC4StructureImpedance alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		[ loadArray addObject:element ] ;
		[ element release ] ;
	}
}

//	v0.81d  added resetAllArrays to keep feedpoints in a control() loop
- (void)parseOutputFile:(NSString*)path resetAllArrays:(Boolean)resetAllArrays
{
	FILE *f ;
	char line[160], *cline ;
	int i ;
    intType n, directions ;
	float solidAngle ;
	RadiationPattern *radiationPattern ;
	
	[ self resetState:resetAllArrays ] ;
		
	f = fopen( [ path UTF8String ], "r" ) ;
	if ( f ) {

		while ( fgets( line, 160, f ) ) {

			cline = line ;
			while ( *cline && ( *cline == ' ' || *cline == '-' ) ) cline++ ;

			if ( strncmp( cline, "RUN TIME", 8 ) == 0 ) {
				elapsed = 0.0 ;
				sscanf( &line[13], "%f", &elapsed ) ;
				continue ;
			}
			if ( strncmp( cline, "ANTENNA INPUT PARAMETERS", 24 ) == 0 ) {
				[ self parseFeedpoint:f ] ;
				continue ;
			}
			if ( strncmp( cline, "ANTENNA ENVIRONMENT", 19 ) == 0 ) {
				[ self parseGround:f ] ;
				continue ;
			}
			//  v0.62
			if ( strncmp( cline, "AVERAGE POWER GAIN", 18 ) == 0 ) {
				solidAngle = 0 ;
				averageGain = 0 ;
				sscanf( cline, "AVERAGE POWER GAIN= %le       SOLID ANGLE USED IN AVERAGING=(%f)", &averageGain, &solidAngle ) ;
				if ( solidAngle < 3.9 ) averageGain = 0 ;
				continue ;
			}
			if ( strncmp( cline, "FREQUENCY - - - -", 17 ) == 0 ) {
				[ self parseFrequency:f ] ;
				continue ;
			}
			if ( strncmp( cline, "RADIATION PATTERNS", 18 ) == 0 ) {
				[ self parseRadiationPattern:f ] ;
				continue ;
			}
			if ( strncmp( cline, "POWER BUDGET", 12 ) == 0 ) {
				fgets( line, 160, f ) ; // skip blank line for NEC-4.
				[ self parseEfficiency:f ] ;
				continue ;
			}
			if ( strncmp( cline, "CURRENTS AND LOCATION", 21 ) == 0 ) {
				[ self parseCurrentLocation:f ] ;
				continue ;
			}
			if ( strncmp( cline, "STRUCTURE SPECIFICATION", 23 ) == 0 ) {
				[ self parseStructureSpecification:f ] ;
				continue ;
			}
			if ( strncmp( cline, "STRUCTURE IMPEDANCE LOADING", 27 ) == 0 ) {	//  v0.77
				[ self parseImpedanceLoading:f ] ;
				continue ;
			}
		}
		fclose( f ) ;
	}
	//  check how many radiation patterns we have
	
	Boolean isSweep = ( [ frequencyArray count ] > 1 ) ;
	
	n = [ patternArray count ] ;
	for ( i = 0; i < n; i++ ) {
		radiationPattern = [ patternArray objectAtIndex:i ] ;
		[ radiationPattern setSweep:isSweep ] ;
		directions = [ radiationPattern count ] ;
		if ( [ radiationPattern thetaRange ] == 0 ) [ azimuthPatterns addObject:radiationPattern ] ;
		else if ( [ radiationPattern phiRange ] == 0 ) [ elevationPatterns addObject:radiationPattern ] ;
	}
}

@end
