//
//  WireCurrent.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/15/12.
//	-----------------------------------------------------------------------------
//  Copyright 2012-2016 Kok Chen, W7AY. 
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
#import "OutputGeometryElement.h"
#import "Config.h"

@interface WireCurrent : NSView <NSWindowDelegate> {
	IBOutlet NSPopUpButton *currentTypeMenu ;
	NSArray *geometryArray ;
	NSColor *backgroundColor, *gridColor, *plotColor, *alphaColor ;
	int segmentOffset ;
	Boolean isActive ;
}

- (void)newInfo:(GeometryInfo*)segment array:(NSArray*)geometryArray ;
- (Boolean)active ;
- (void)setActive:(Boolean)state ;
- (void)hideWindow ;

@end
