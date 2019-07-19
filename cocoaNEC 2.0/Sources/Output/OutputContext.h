//
//  OutputContext.h
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

#import <Cocoa/Cocoa.h>
#import "NECEngines.h"
#import "OutputTypes.h"
#import "RunInfo.h"

@class GeometryPlot ;
@class RadiationPattern ;

#define MAXFEEDPOINTS	64


@interface OutputContext : NSObject {
	
	NSString *name ;
	NSString *hollerith ;
	NSString *lpt ;
	NSString *source ;

	NSMutableArray *hollerithArray ;
	NSMutableArray *structureArray ;
	NSMutableArray *loadArray ;
	NSMutableArray *frequencyArray ;
	NSMutableArray *arrayOfFeedpointArrays ;		// in a frequency sweep, there are multiple Feedpoint arrays
	NSMutableArray *patternArray ;					//  array of arrays of radiation pattern
	NSMutableArray *geometryArray ;
	GeometryPlot *geometryPlot ;
	NSString *necOutput ;
	
	NSArray *exceptions ;
	NSMutableArray *azimuthPatterns ;
	NSMutableArray *elevationPatterns ;
	NSArray *previousFeedpointArray ;
	RadiationPattern *previousAzimuthPattern ;
	RadiationPattern *previousElevationPattern ;
	double efficiency ;
	
	int frequencyCount ;
	double currentFrequency ;
	GeometryOptions geometryOptions ;
	
	//  ground
	Boolean usesSommerfeld ;
	Boolean freespace ;
	Boolean perfectGround ;
	double dielectric ;
	double conductivity ;
		
	//	v0.62 AGT
	double averageGain ;
	
	//	v0.70 SWR chart and scalar chart selection
	FeedpointCache feedpointCache[MAXFEEDPOINTS], dummyFeedpointCache ;
	intType selectedFeedpointNumber ;
	
	float elapsed ;
	RunInfo *runInfo ;
	int engine ;
}

- (id)initWithName:(NSString*)str hollerith:(NSString*)hstr lpt:(NSString*)lstr source:(NSString*)src exceptions:(NSArray*)ex geometryOptions:(GeometryOptions*)options ;
- (void)replaceWithName:(NSString*)str hollerith:(NSString*)hollerith lpt:(NSString*)lpt source:(NSString*)src exceptions:(NSArray*)ex geometryOptions:(GeometryOptions*)options resetAllArrays:(Boolean)resetAllArrays ;
- (NSArray*)exceptions ;
- (void)resetState:(Boolean)all ;	//  v0.81 private API (for NEC4Context)

- (NSString*)name ;
- (void)setName:(NSString*)str ;
- (NSString*)hollerith ;
- (void)setHollerith:(NSString*)str ;
- (NSString*)lpt ;
- (void)setLpt:(NSString*)lpt ;
- (NSString*)source ;
- (void)setSource:(NSString*)lpt ;
- (NSString*)modifiedSourceName:(NSString*)src ;
- (NSString*)modifiedSourceName:(NSString*)src engine:(int)eng ;

//  v0.70 : frequecy, set and index that was last clicked in SWR view (freq = 0 if not set)
- (FeedpointCache*)feedpointCache:(intType)index ;
- (FeedpointCache*)selectedFeedpointCache ;
- (void)setFeedpointCache:(FeedpointCache*)feed feedpointNumber:(intType)index ;
- (intType)selectedFeedpointNumber ;

// knec2cEngine, kNEC4Engine, etc
- (int)engine ;

- (RunInfo*)runInfo ;
- (void)setRunInfo:(RunInfo*)info ;

- (float)elapsedTime ;

- (void)createContext:(Boolean)resetAllArrays ;			//  v0.81 added resetAllArrays
- (void)redrawGeometry:(GeometryOptions*)options ;		//  v0.81d

- (NSArray*)hollerithCards ;
- (NSArray*)structureElements ;
- (NSArray*)arrayOfFeedpoints ;
- (NSArray*)loads ;
- (NSString*)necOutput ;			//  Text of NEC-2 output	
- (NSArray*)elevationPatterns ;		//  array of RadiationPatterns
- (NSArray*)azimuthPatterns ;		//  array of RadiationPatterns
- (NSArray*)radiationPatterns ;		//  array of RadiationPatterns
- (NSArray*)frequencies ;
- (NSArray*)geometryElements ;

- (NSArray*)previousAzimuthPatterns ;
- (NSArray*)previousElevationPatterns ;
- (NSArray*)previousFeedpointArray ;

- (double)dielectricConstant ;
- (double)conductivity ;
- (double)efficiency ;
- (Boolean)usesSommerfeld ;
- (Boolean)freespace ;
- (Boolean)perfectGround ;
- (double)averageGain ;			//  v0.62

//  RunInfo data
- (void)setDirectivity:(double)value ;
- (void)setMaxGain:(double)gain ;
- (void)setMaxElevation:(double)value ;
- (void)setMaxAzimuth:(double)value ;
- (void)setFrontToBack:(double)value ;
- (void)setFrontToRear:(double)value ;
- (void)setFeedpoints:(NSArray*)array ;
- (void)setEfficiency ;

//  used by subclass (NEC4Context)
- (void)parseFrequency:(FILE*)f ;
- (void)parseEfficiency:(FILE*)f ;

@end
