//
//  SWRView.h
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

#import "AuxSWRView.h"
#import "DataView.h"


@interface SWRView : DataView {
	IBOutlet AuxSWRView *auxSWRView ;
	IBOutlet NSButton *showAllCheckbox ;
	IBOutlet NSButton *smartInterpolationCheckbox ;
	//IBOutlet NSWindow *colorWindow ;
	
	//  note: cannot make NSColorWell into NSMatrix
	IBOutlet NSColorWell *colorWell0 ;
	IBOutlet NSColorWell *colorWell1 ;
	IBOutlet NSColorWell *colorWell2 ;
	IBOutlet NSColorWell *colorWell3 ;
	IBOutlet NSColorWell *colorWell4 ;
	IBOutlet NSColorWell *colorWell5 ;
	IBOutlet NSColorWell *colorWell6 ;
	IBOutlet NSColorWell *colorWell7 ;
	IBOutlet NSColorWell *colorWell8 ;
	IBOutlet NSColorWell *colorWell9 ;
	IBOutlet NSColorWell *colorWell10 ;
	IBOutlet NSColorWell *colorWell11 ;
	IBOutlet NSColorWell *colorWell12 ;
	IBOutlet NSColorWell *colorWell13 ;
	IBOutlet NSColorWell *colorWell14 ;
	IBOutlet NSColorWell *colorWell15 ;
	
	NSColorWell *colorWell[16] ;
	NSColor *refColor, *refCenterColor ;
	float swrCircle ;
	float geometricScale ;
	float adjustedScale ;
	NSPoint center ;
	
	//  v0.70 to handle printing thin lines using alpha
	float currentLinewidth ;
	float currentRed, currentGreen, currentBlue ;
}

@property (strong) IBOutlet NSWindow *colorWindow ;

- (void)setSWRCircle:(float)circle ;
- (void)openColorManager ;

- (AuxSWRView*)auxView ;
- (Boolean)showAllFeedpoints ;

//	v0.73 smart interpolation support
- (Boolean)doSmartInterpolate ;
- (void)setSmartInterpolate:(Boolean)state ;

//  v0.70 get and set NSColor of well
- (NSColor*)wellColor:(int)index ;
- (void)setWellColor:(int)index color:(NSColor*)color ;
//	v0.70 let printing SWRView get its color wells from the GUI SWRView
- (NSColorWell*)colorWell:(int)i ;
- (void)setColorWell:(int)index fromColorWell:(NSColorWell*)well ;


@end
