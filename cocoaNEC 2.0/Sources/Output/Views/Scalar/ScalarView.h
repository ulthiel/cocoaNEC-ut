//
//  ScalarView.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/7/11.
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

#import "DataView.h"
#import "AuxScalarView.h"

typedef struct {
    float vScale, vOffset ;
    float hOffset ;
    float pixelsPerMHz ;        //  = hScale
} PlotScale ;

@interface ScalarView : DataView {
	IBOutlet AuxScalarView *auxScalarView ;
	IBOutlet NSPopUpButton *plotTypeMenu ;
	IBOutlet NSPopUpButton *plotScaleMenu ;
	NSColor *plotColor, *alternatePlotColor, *plotColorWithBackground, *plotColorNoBackground, *alternatePlotColorWithBackground, *alternatePlotColorNoBackground ;
	NSColor *backgroundColor, *textColor ;
	NSMutableDictionary *fontAttributes, *fontAttributesWithBackground, *fontAttributesNoBackground ;
	
	int samples ;
	float frequencyOffset ;
	ScalarView *printView ;					// the companion printing ScalarView
	
	//  drawing scheme
	float gridRed, gridGreen, gridBlue, lineWidth ;
	Boolean hasBackground ;
	
    NSRect canvasBounds ;
    PlotScale plotScale ;
	PlotInfo plotInfo ;
	intType selectedType, selectedScale, scalarType ;
	intType scalarGainMenu[4] ;					//  one per plotTypeMenu index
	float scalarScrollerLocation[4] ;		//  one per plotTypeMenu index
}

- (intType)plotType ;
- (AuxScalarView*)auxView ;
- (void)setRXScaleMenu ;
- (float)scrollOffset ;
- (void)setScrollOffset:(float)v ;
- (void)updatePlotType ;
- (void)setPrintView:(ScalarView*)pView ;

@end
