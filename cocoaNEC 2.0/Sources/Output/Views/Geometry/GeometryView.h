//
//  GeometryView.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/3/07.
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
#import "PrintableView.h"
#import "OutputGeometryElement.h"
#import "OutputTypes.h"
#import "WireCurrent.h"

@class NECOutput ;

@interface GeometryView : PrintableView {
	WireCurrent *wireCurrent ;	//  v0.81e
	NSMutableArray *arrayOfGeometryArrays, *feedpoints, *loads, *exceptions ;
	NSRect frame ;
	NSImage *hsvImage ;
	intType currentType ;
	float azAngle, elAngle, zoom, panx, pany, printWidth ;
	GeometryOptions geometryOptions ;
	NSPoint mouseDownLocation ;
	NSCursor *savedCursor ;
	NECOutput *client ;
	//	v0.75c
	NSAffineTransform *currentScale ;
	GeometryInfo *captionGeometryInfo ;
	int captionGeometryIndex ;					//  v0.81e
	GeometryInfo unitVectors[4] ;
}
- (void)updateWithArray:(NSArray*)array feedpoints:(NSArray*)feedpointArray loads:(NSArray*)loadArray exceptions:(NSArray*)exceptionArray options:(GeometryOptions*)options client:(NECOutput*)output ;
- (void)refreshCurrents:(intType)ctype azimuth:(float)az elevation:(float)el zoom:(float)zoomfactor options:(GeometryOptions*)options ;

- (void)setCurrentView:(WireCurrent*)view ;		//  v0.81e

- (void)clearPan ;

@end

#define	GEOMETRYNONE			0
#define	GEOMETRYCURRENT			1
#define	GEOMETRYPOWER			2
#define	GEOMETRYPHASE			3
#define	GEOMETRYRELATIVEPHASE	4
#define	GEOMETRYGRADIENT		5

