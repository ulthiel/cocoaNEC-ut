//
//  PatternView.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/22/07.
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
#import "AuxPatternView.h"
#import "PrintableView.h"
#import "Polarization.h"
#import "OutputTypes.h"

@class RadiationPattern ;

@interface PatternView : PrintableView {
	IBOutlet AuxPatternView *auxPatternView ;
	NSRect frame ;
	double rho ;
	intType gainPolarization ;
	int *circle, minorMin, majorMin ;
	NSBezierPath *circles, *minorCircles ;
	NSMutableDictionary *captionAttributes, *smallInfoAttributes ;
	Boolean isElevation ;
	Boolean isEmbedded ;
	NSMutableArray *arrayOfRadiationPatterns, *arrayOfReferencePatterns, *arrayOfPreviousPatterns ;
	NSColor *refColor, *defaultColor, *plotColor[MAXCOLORWELLS] ;
}

- (id)initWithFrame:(NSRect)inFrame isElevation:(Boolean)isElevation ;
- (void)updateColorsFromColorWells:(ColorWells*)wells ;
- (void)changeColor:(NSColorWell*)well ;
- (void)setIsEmbedded:(Boolean)state ;

- (void)clearPatterns ;
- (void)updatePatternWithArray:(NSArray*)array refArray:(NSArray*)ref prevArray:(NSArray*)prev ;

- (void)drawPattern:(NSAffineTransform*)scale ;
- (void)plotGain:(NSBezierPath*)path gain:(float*)gain maxGain:(float)maxGain elementArray:(NSArray*)array count:(intType)count ;

- (NSArray*)makeCaptions:(intType)count reference:(RadiationPattern*)ref previous:(RadiationPattern*)ref ;

- (void)setGainScale:(double)s ;
- (void)setGainPolarization:(intType)pol ;

- (AuxPatternView*)auxView ;
- (Boolean)isElevation ;

@end
