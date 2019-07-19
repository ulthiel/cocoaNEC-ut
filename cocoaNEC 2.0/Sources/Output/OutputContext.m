//
//  OutputContext.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/21/07.
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

#import "OutputContext.h"
#import "necEngines.h"
#import "Feedpoint.h"
#import "OutputGeometryElement.h"
#import "GeometryPlot.h"
#import "RadiationPattern.h"
#import "PatternElement.h"
#import "StructureElement.h"
#import "StructureImpedance.h"
#import "NewArray.h"

//  Holds the output for each antenna model so that Output.m can quickly recreate them as it flips through models.

@implementation OutputContext

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		//  v0.70 -- selection for each feedpoint
		dummyFeedpointCache.frequency = 0 ;	
		dummyFeedpointCache.frequencyIndex = dummyFeedpointCache.frequencies = dummyFeedpointCache.feedpointNumber = 0 ;
		for ( i = 0; i < MAXFEEDPOINTS; i++ ) feedpointCache[i] = dummyFeedpointCache ;
		selectedFeedpointNumber = -1 ;

		name = hollerith = lpt = source = nil ;
		hollerithArray = newArray() ;
		structureArray = newArray() ;
		frequencyArray = newArray() ;
		arrayOfFeedpointArrays = newArray() ;
		loadArray = newArray() ;
		patternArray = newArray() ;
		azimuthPatterns = newArray() ;
		elevationPatterns = newArray() ;
		geometryArray = newArray() ;
		geometryOptions.radials = geometryOptions.distributedLoads = NO ;
		geometryPlot = [ [ GeometryPlot alloc ] initWithStructure:structureArray ] ;
		necOutput = nil ;
		previousAzimuthPattern = previousElevationPattern = nil ;
		previousFeedpointArray = nil ;
		currentFrequency = DefaultFrequency ;
		efficiency = 100.0 ;
		runInfo = nil ;
		engine = knec2cEngine ;		//  default engine
	}
	return self ;
}

- (id)initWithName:(NSString*)str hollerith:(NSString*)hstr lpt:(NSString*)lstr source:(NSString*)src exceptions:(NSArray*)ex geometryOptions:(GeometryOptions*)options
{
	[ self init ] ;
	[ self setName:str ] ;
	[ self setHollerith:hstr ] ;
	[ self setLpt:lstr ] ;
	[ self setSource:src ] ;
	geometryOptions = *options ;
	if ( necOutput ) [ necOutput release ] ;
	necOutput = [ [ NSString stringWithContentsOfFile:lstr encoding:NSASCIIStringEncoding error:nil ] retain ] ;
	if ( exceptions ) [ exceptions release ] ;
	exceptions = ex ;
	if ( exceptions ) [ exceptions retain ] ;
	[ self createContext:YES ] ;
	return self ;
}

//	v0.70
- (FeedpointCache*)feedpointCache:(intType)index ;
{
	if ( index < 0 || index >= MAXFEEDPOINTS ) return &dummyFeedpointCache ;
	return &feedpointCache[index] ;
}

//  v0.70
- (void)setFeedpointCache:(FeedpointCache*)feed feedpointNumber:(intType)index
{
	if ( index < 0 || index >= MAXFEEDPOINTS ) return ;
	feedpointCache[index] = *feed ;
	selectedFeedpointNumber = index ;
}

//	v0.70
- (intType)selectedFeedpointNumber
{
	return selectedFeedpointNumber ;
}

- (FeedpointCache*)selectedFeedpointCache
{
	return [ self feedpointCache:selectedFeedpointNumber ] ;
}

- (NSArray*)exceptions
{
	return exceptions ;
}

//	v0.81d check geometryOptions instead of just radials
- (void)redrawGeometry:(GeometryOptions*)new
{
	if ( new->radials == geometryOptions.radials && new->distributedLoads == geometryOptions.distributedLoads ) return ;
	geometryOptions = *new ;
	[ geometryPlot updateGeometryInfo:geometryArray exceptions:exceptions options:&geometryOptions frequency:currentFrequency ] ;
}

- (NSString*)modifiedSourceName:(NSString*)src engine:(int)eng
{
	switch ( eng ) {	//  v0.78
	case kNEC41Engine:
		return [ src stringByAppendingString:@" (NEC-4.1)" ] ;
	case kNEC42Engine:
	case kNEC42EngineGN2:
		return [ src stringByAppendingString:@" (NEC-4.2)" ] ;
	}
	return src ;
}

//  modified source name for current engine
- (NSString*)modifiedSourceName:(NSString*)src
{
	return [ self modifiedSourceName:src engine:engine ] ;
}

//  replace existing context with new input
//	v0.81d added resetAllArrays
- (void)replaceWithName:(NSString*)str hollerith:(NSString*)hstr lpt:(NSString*)lstr source:(NSString*)inSrc exceptions:(NSArray*)ex geometryOptions:(GeometryOptions*)options resetAllArrays:(Boolean)resetAllArrays
{
	NSString *src ;
	
	[ hollerithArray removeAllObjects ] ;
	[ frequencyArray removeAllObjects ] ;

	//  0.46
	if ( previousFeedpointArray ) [ previousFeedpointArray release ] ;
	previousFeedpointArray = nil ;
	if ( [ arrayOfFeedpointArrays count ] >= 1 ) previousFeedpointArray = [ [ arrayOfFeedpointArrays objectAtIndex:0 ] retain ] ;

	if ( resetAllArrays ) [ arrayOfFeedpointArrays removeAllObjects ] ;
	[ patternArray removeAllObjects ] ;
	
	src = [ self modifiedSourceName:inSrc ] ;
	
	//  keep the previous primary azimuth pattern
	if ( previousAzimuthPattern ) [ previousAzimuthPattern release ] ;
	previousAzimuthPattern = nil ;
	if ( [ azimuthPatterns count ] >= 1 ) previousAzimuthPattern = [ [ azimuthPatterns objectAtIndex:0 ] retain ] ;
	[ azimuthPatterns removeAllObjects ] ;
	
	//  keep the previous primary azimuth pattern
	if ( previousElevationPattern ) [ previousElevationPattern release ] ;
	previousElevationPattern = nil ;
	if ( [ elevationPatterns count ] >= 1 ) previousElevationPattern = [ [ elevationPatterns objectAtIndex:0 ] retain ] ;
	[ elevationPatterns removeAllObjects ] ;
	[ geometryArray removeAllObjects ] ;
	[ self setName:str ] ;
	[ self setHollerith:hstr ] ;
	[ self setLpt:lstr ] ;
	[ self setSource:src ] ;
	geometryOptions = *options ;
	if ( necOutput ) [ necOutput release ] ;
	necOutput = [ [ NSString stringWithContentsOfFile:lstr encoding:NSASCIIStringEncoding error:nil ] retain ] ;
	if ( exceptions ) [ exceptions release ] ;
	exceptions = ex ;
	if ( exceptions ) [ exceptions retain ] ;
	[ self createContext:resetAllArrays ] ;
}


- (void)dealloc
{
	[ hollerithArray release ] ;
	[ frequencyArray release ] ;
	[ arrayOfFeedpointArrays release ] ;
	[ patternArray release ] ;
	[ azimuthPatterns release ] ;
	[ elevationPatterns release ] ;
	[ geometryArray release ] ;
	[ geometryPlot release ] ;
	
	if ( structureArray ) [ structureArray release ] ;			//  v0.64
	
	if ( previousAzimuthPattern ) [ previousAzimuthPattern release ] ;
	if ( previousElevationPattern ) [ previousElevationPattern release ] ;
	if ( previousFeedpointArray ) [ previousFeedpointArray release ] ;
	
	if ( name ) [ name release ] ;
	if ( hollerith ) [ hollerith release ] ;
	if ( lpt ) [ lpt release ] ;
	if ( necOutput ) [ necOutput release ] ;
	[ exceptions release ] ;
	[ super dealloc ] ;
}

- (void)parseFeedpoint:(FILE*)f
{
	NSMutableArray *feedpointArray ;
	Feedpoint *feed ;
	char line[160] ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  TAG   SEG", 11 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  No:", 5 ) != 0  ) return ;
	
	feedpointArray = [ NSMutableArray array ] ;  //  NOTE for v0.64: pass ownership of feedpointArray to araayOfFeedpointArrays
	
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
	int i ;
	
	freespace = perfectGround = usesSommerfeld = NO ;
	dielectric = 10.0 ;
	conductivity = 0.04 ;

	for ( i = 0; i < 5; i++ ) {
		if ( fgets( line, 160, f ) == nil ) return ;
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
		if ( strncmp( "FINITE GROUND - SOMMERFELD", s, 26 ) == 0 ) usesSommerfeld = YES ;
		if ( strncmp( "RELATIVE DIELECTRIC CONST:", s, 26 ) == 0 ) sscanf( s, "RELATIVE DIELECTRIC CONST:%lf", &dielectric ) ;
		if ( strncmp( "CONDUCTIVITY:", s, 13 ) == 0 ) {
			sscanf( s, "CONDUCTIVITY:%lf", &conductivity ) ;
			break ;
		}
	}
}

- (void)parseFrequency:(FILE*)f
{
	float freq ;
	char line[160] ;
	
	if ( fgets( line, 160, f ) == nil  ) return ;
	if ( line[0] == '\n' || line[0] == '\r' ) fgets( line, 160, f ) ;	//  NEC-4 has an extra blank line

	freq = 0 ;
	sscanf( line, "                                FREQUENCY=%f", &freq ) ;
	if ( freq < 0.1 ) return ;
	
	frequencyCount++ ;
	currentFrequency = freq ;
	[ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
}

- (void)parseEfficiency:(FILE*)f
{
	float value ;
	char line[160] ;
	int i ;
	
	efficiency = 100.0 ;
	for ( i = 0; i < 6; i++ ) {
		if ( fgets( line, 160, f ) == nil || strlen( line ) < 5 ) return ;
		value = -1 ;
		sscanf( line, "                               EFFICIENCY    =%f", &value ) ;
		if ( value >= 0 ) {
			efficiency = value ;
			return ;
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
	
	for ( i = 0; i < 5; i++ ) {
		//  nec2c has 4 blank lines
		fgets( line, 160, f ) ;
	}
	if ( strncmp( line, " ---- ANGLES", 12 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  THETA", 7 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, " DEGREES", 8 ) != 0  ) return ;
	
	array = [ [ NSMutableArray alloc ] init ] ;		//  array for RadationPattern	
	while ( fgets( line, 160, f ) != nil ) {	
		element = [ [ PatternElement alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		[ array addObject:element ] ;
		[ element release ] ;					//  v0.64
	}	
	pattern = [ [ RadiationPattern alloc ] initWithArray:array frequency:currentFrequency ] ;
	[ array release ] ;
	if ( pattern == nil ) return ;				//  v0.82
	[ patternArray addObject:pattern ] ;
	[ pattern release ] ;						//  v0.64
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
	
	for ( i = 0; i < 2; i++ ) fgets( line, 160, f ) ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "   SEG", 6 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "   No:", 6 ) != 0  ) return ;
		
	arrayOfGeometryElements = [ NSMutableArray array ] ;	
	while ( fgets( line, 160, f ) != nil ) {	
		element = [ [ OutputGeometryElement alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		tag = [ element tag ] ;
		
		if ( currentTag >= 0 && tag != currentTag ) {
			//  new tag seen, add element
			if ( [ arrayOfGeometryElements count ] > 0 ) {
				[ geometryArray addObject:arrayOfGeometryElements ] ;
			}
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

- (void)duplicateStructure:(int)times incr:(int)increment
{
	intType i, j, count ;
    int nextSegment, diff ;
	StructureInfo *g ;
	StructureElement *element ;

	count = [ structureArray count ] ;
	nextSegment = 0 ;
	for ( i = 0; i < count; i++ ) {
		element = [ structureArray objectAtIndex:i ] ;
		g = [ element info ] ;
		if ( g->endSegment > nextSegment ) nextSegment = g->endSegment ;
	}
	nextSegment++ ;		// next unused segment number 
	//  make copies existing Structure elements 
	for ( i = 0; i < count; i++ ) {
		/// start at 1 since the base element is already defined
		for ( j = 1; j < times; j++ ) {
			element = [ [ StructureElement alloc ] initWithStructureElement:[ structureArray objectAtIndex:i ] ] ;
			g = [ element info ] ;
			g->tag += increment*j ;
			diff = g->endSegment - g->startSegment ;
			g->startSegment = nextSegment;
			g->endSegment = nextSegment + diff ;
			nextSegment = g->endSegment+1 ;
			[ structureArray addObject:element ] ;
			[ element release ] ;						//  v0.64
		}
	}
}

- (void)generateRotatedStructure:(char*)line
{
	int times, increment ;
	char axis ;
	
	times = 0 ;
	increment = 0 ;
	sscanf( line, "  STRUCTURE ROTATED ABOUT %c-AXIS %d TIMES - LABELS INCREMENTED BY %d", &axis, &times, &increment ) ;
	if ( times < 2 || increment < 1 ) return ;
	[ self duplicateStructure:times incr:increment ] ;
}

- (void)generateReflectedStructure:(char*)line
{
	int times, increment ;
	char x, y, z ;

	increment = 0 ;
	x = 0 ;
	y = 0 ;
	z = 0 ;
	sscanf( line, "  STRUCTURE REFLECTED ALONG THE AXES %c %c %c - TAGS INCREMENTED BY %d", &x, &y, &z, &increment ) ;

	times = 1 ;
	if ( x == 'X' ) times *= 2 ;
	if ( y == 'Y' ) times *= 2 ;
	if ( z == 'Z' ) times *= 2 ;
	if ( times < 2 || increment < 1 ) return ;
	
	[ self duplicateStructure:times incr:increment ] ;
}

//  create array structure specification ( "wires" )
- (void)parseStructureSpecification:(FILE*)f
{
	int i ;
	char line[160] ;
	StructureElement *element ;
	NSString *check ;
	
	for ( i = 0; i < 4; i++ ) fgets( line, 160, f ) ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  WIRE", 6 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "   No:", 6 ) != 0  ) return ;
	
	while ( fgets( line, 160, f ) != nil ) {
		element = [ [ StructureElement alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) {
			check = [ NSString stringWithUTF8String:&line[0] ] ;
			if ( [ check rangeOfString:@"STRUCTURE ROTATED" ].location != NSNotFound ) [ self generateRotatedStructure:&line[0] ] ;
			if ( [ check rangeOfString:@"STRUCTURE REFLECTED" ].location != NSNotFound ) [ self generateReflectedStructure:&line[0] ] ;
			if ( [ check rangeOfString:@"RADIUS X1" ].location != NSNotFound ) continue ;						//  sub field of Helix v0.75f
			if ( [ check rangeOfString:@"THE PITCH ANGLE IS" ].location != NSNotFound ) continue ;				//  sub field of Helix v0.75f
			if ( [ check rangeOfString:@"THE CONE ANGLE" ].location != NSNotFound ) continue ;					//  sub field of Helix GM card v0.75f
			if ( [ check rangeOfString:@"THE STRUCTURE HAS BEEN MOVED" ].location != NSNotFound ) continue ;	//  sub field of Helix GM card v0.75f
			else break ;
		}
		else {
			[ structureArray addObject:element ] ;
			[ element release ] ;						//  v0.64
		}
	}
}

- (void)parseImpedanceLoading:(FILE*)f
{
	char line[160] ;
	StructureImpedance *element ;
	
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  LOCATION", 10 ) != 0  ) return ;
	if ( fgets( line, 160, f ) == nil || strncmp( line, "  ITAG", 6 ) != 0  ) return ;

	while ( fgets( line, 160, f ) != nil ) {
		element = [ [ StructureImpedance alloc ] initWithLine:&line[0] ] ;
		if ( element == nil ) break ;
		[ loadArray addObject:element ] ;
		[ element release ] ;							//  v0.64
	}
}

//	v0.81d
//	(Private API)
- (void)resetState:(Boolean)all
{
	frequencyCount = 0 ;					// this prevents multiple geometry plots when there is a frequency sweep
	averageGain = 0 ;
	[ frequencyArray removeAllObjects ] ;
	[ structureArray removeAllObjects ] ;
	[ loadArray removeAllObjects ] ;
	[ patternArray removeAllObjects ] ;
	[ elevationPatterns removeAllObjects ] ;
	[ azimuthPatterns removeAllObjects ] ;
	[ geometryArray removeAllObjects ] ;
	if ( all ) [ arrayOfFeedpointArrays removeAllObjects ] ;	// v0.81d moved to -reset
}

- (void)parseOutputFile:(NSString*)path resetAllArrays:(Boolean)resetAllArrays
{
	FILE *f ;
	char line[160], *cline ;
	int i, ms, first ;
    intType n, directions ;
	float solidAngle ;
	RadiationPattern *radiationPattern ;
	
	[ self resetState:resetAllArrays ] ;

	f = fopen( [ path UTF8String ], "r" ) ;
	if ( f ) {
		while ( fgets( line, 160, f ) ) {
	
			cline = line ;
			while ( *cline && ( *cline == ' ' || *cline == '-' ) ) cline++ ;
			first = cline[0] ;

			if ( first == 'T' && strncmp( cline, "TOTAL RUN TIME:", 15 ) == 0 ) {
				ms = 0 ;
				sscanf( &line[17], "%d", &ms ) ;
				elapsed = ms*0.001 ;
				continue ;
			}
			if ( first == 'A' ) {
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
					sscanf( cline, "AVERAGE POWER GAIN:  %le - SOLID ANGLE USED IN AVERAGING: (%f)", &averageGain, &solidAngle ) ;
					if ( solidAngle < 3.9 ) averageGain = 0 ;
					continue ;
				}
			}
			if ( first == 'F' && strncmp( cline, "FREQUENCY -------", 17 ) == 0 ) {
				[ self parseFrequency:f ] ;
				continue ;
			}
			if ( first == 'R' && strncmp( cline, "RADIATION PATTERNS", 18 ) == 0 ) {
				[ self parseRadiationPattern:f ] ;
				continue ;
			}
			if ( first == 'P' && strncmp( cline, "POWER BUDGET", 12 ) == 0 ) {
				[ self parseEfficiency:f ] ;
				continue ;
			}
			if ( first == 'C' && strncmp( cline, "CURRENTS AND LOCATION", 21 ) == 0 ) {
				[ self parseCurrentLocation:f ] ;
				continue ;
			}
			if ( first == 'S' ) {
				if ( strncmp( cline, "STRUCTURE SPECIFICATION", 23 ) == 0 ) {
					[ self parseStructureSpecification:f ] ;
					continue ;
				}
				if ( strncmp( cline, "STRUCTURE IMPEDANCE LOADING", 27 ) == 0 ) {
					[ self parseImpedanceLoading:f ] ;
					continue ;
				}
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
		else {
			if ( [ radiationPattern phiRange ] == 0 ) [ elevationPatterns addObject:radiationPattern ] ;
		}
	}
}

- (float)elapsedTime
{
	return elapsed ;
}

- (RunInfo*)runInfo
{
	return runInfo ;
}

- (void)setRunInfo:(RunInfo*)info
{
	runInfo = info ;
	runInfo->directivity = -1.0 ;
}

- (void)createHollerith:(NSString*)path
{
	FILE *h ;
	char str[160], *s ;
	int i, n ;
	
	[ hollerithArray removeAllObjects ] ;
	if ( path == nil ) return ;
	
	h = fopen( [ path UTF8String ], "r" ) ;
	if ( h ) {
		for ( i = 0; i < 2000; i++ ) {
			s = fgets( str, 159, h ) ;
			if ( s == nil ) break ;
			n = (int)strlen( s ) ;
			if ( n > 1 ) s[n-1] = 0 ;
			[ hollerithArray addObject:[ NSString stringWithUTF8String:s ] ] ;
		}
		fclose( h ) ;
	}
}

- (NSArray*)hollerithCards
{
	return hollerithArray ;
}

- (NSArray*)structureElements
{
	return structureArray ;
}

- (NSArray*)arrayOfFeedpoints
{
	return arrayOfFeedpointArrays ;
}

- (NSArray*)loads
{
	return loadArray ;
}

- (NSArray*)frequencies
{
	return frequencyArray ;
}

- (NSArray*)elevationPatterns
{
	return elevationPatterns ;
}

- (NSArray*)azimuthPatterns
{
	return azimuthPatterns ;
}

- (NSArray*)previousAzimuthPatterns
{
	if ( previousAzimuthPattern ) return [ NSArray arrayWithObjects:previousAzimuthPattern, nil ]  ;
	return [ NSArray array ] ;
}

- (NSArray*)previousElevationPatterns
{
	if ( previousElevationPattern ) return [ NSArray arrayWithObjects:previousElevationPattern, nil ] ;
	return [ NSArray array ]  ;
}

- (NSArray*)previousFeedpointArray
{
	return previousFeedpointArray ;
}

- (NSArray*)radiationPatterns
{
	return patternArray ;
}

- (double)dielectricConstant
{
	return dielectric ;
}

- (double)conductivity
{
	return conductivity ;
}

- (double)averageGain
{
	return averageGain ;
}

- (Boolean)usesSommerfeld
{
	return usesSommerfeld ;
}

- (Boolean)freespace
{
	return freespace ;
}

- (Boolean)perfectGround
{
	return perfectGround ;
}

- (NSArray*)geometryElements
{
	return geometryArray ;
}

- (NSString*)necOutput
{
	return necOutput ;
}

//	v0.81d added resetAllArrays
- (void)createContext:(Boolean)resetAllArrays
{
	[ self createHollerith:hollerith ] ;
	[ self parseOutputFile:lpt resetAllArrays:resetAllArrays ] ;
}

- (NSString*)name
{
	return ( ( name == nil ) ? @"" : name ) ;
}

- (void)setName:(NSString*)str
{
	if ( name ) [ name release ] ;
	name = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)hollerith
{
	return ( ( hollerith == nil ) ? @"" : hollerith ) ;
}

- (void)setHollerith:(NSString*)str
{
	if ( hollerith ) [ hollerith release ] ;
	hollerith = ( str == nil ) ? nil : [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)lpt
{
	return ( ( lpt == nil ) ? @"" : lpt ) ;
}

- (void)setLpt:(NSString*)str
{
	if ( lpt ) [ lpt release ] ;
	lpt = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)source
{
	return ( ( source == nil ) ? @"" : source ) ;
}

- (void)setSource:(NSString*)str
{
	if ( source ) [ source release ] ;
	source = ( str == nil ) ? nil : [ [ NSString alloc ] initWithString:str ] ;
}

- (void)setDirectivity:(double)value
{
	if ( runInfo ) runInfo->directivity = value ;
}

- (void)setMaxGain:(double)value
{
	if ( runInfo ) {
		runInfo->maxGain = value ;
		runInfo->averageGain = averageGain ;		//  v0.62
	}
}

- (void)setMaxElevation:(double)value
{
	if ( runInfo ) runInfo->elevationAngleAtMaxGain = value ;
}

- (void)setMaxAzimuth:(double)value
{
	if ( runInfo ) runInfo->azimuthAngleAtMaxGain = value ;
}

- (void)setFrontToBack:(double)value
{
	if ( runInfo ) runInfo->frontToBackRatio = value ;
}

- (void)setFrontToRear:(double)value
{
	if ( runInfo ) runInfo->frontToRearRatio = value ;
}

- (void)setFeedpoints:(NSArray*)array
{
	if ( runInfo ) runInfo->feedpointArray = array ;
}

- (void)setEfficiency
{
	if ( runInfo ) runInfo->efficiency = efficiency ;
}

- (double)efficiency
{
	return efficiency ;
}

- (int)engine
{
	return engine ;
}

@end
