/*
 *  OutputTypes.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 6/17/11.
 */
 
//	-----------------------------------------------------------------------------
//  Copyright 2011-2016 Kok Chen, W7AY. 
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


#import <AppKit/AppKit.h>       //  for NSColorWell
#import "Config.h"


#define	MAXCOLORWELLS	16

typedef struct {
	int numberOfWells ;
	NSColorWell *colorWell[MAXCOLORWELLS] ;
} ColorWells ;

typedef struct {
	Boolean hasData ;
	float width ;
	float height ;
	float minFreq ;
	float maxFreq ;
	float decade ;
	float pixelsPerFrequencyGrid, firstFrequencyGrid ;
	float frequencyLabelGrid, firstFrequencyLabel ;
	NSString *labelFormat ;
	int y0, dataOffset, pixelsPerMinorVerticalGrid, pixelsPerVerticalGrid ;
	float unitsPerVerticalGrid ;
} PlotInfo ;

//	RX, UV, frequency and presorted index and feedpointNumber for each element of RXFArray in Dataview.h.
typedef struct {
	NSPoint rx ;
	NSPoint uv ;
	NSPoint viewLocation ;
	float frequency ;
	int index ;					//  presorted index
	int frequencyIndex ;
} RXF ;

typedef struct {
	float frequency ;
	intType frequencies ;
	intType frequencyIndex ;
	intType feedpointNumber ;
} FeedpointCache ;

//	v0.81d
typedef struct {
	Boolean radials ;
	Boolean distributedLoads ;
} GeometryOptions ;

#define	kRXPlotType				0
#define	kImpedancePlotType		1
#define	kSWRPlotType			2
#define	kReturnLossPlotType		3

