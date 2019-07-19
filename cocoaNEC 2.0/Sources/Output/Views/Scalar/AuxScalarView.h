//
//  AuxScalarView.h
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

#import "OutputTypes.h"
#import "AuxView.h"

@interface AuxScalarView : AuxView {
	NSColor *backgroundColor, *textColor ;
	NSMutableDictionary *fontAttributes, *fontAttributesWithBackground, *fontAttributesNoBackground ;
	PlotInfo *plotInfo ;
	RXF *rxf ;
	float z0 ;
	intType plotType ;
	Boolean hasBackground ;
	NSColor *mainColor, *altColor ;
}

- (void)label:(PlotInfo*)plotInfo ;
- (void)setCaptionWithRXF:(RXF*)rp z0:(float)z plotType:(intType)plotType mainColor:(NSColor*)mainc altColor:(NSColor*)altc ;

@end
