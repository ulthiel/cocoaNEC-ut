//
//  StructureElement.h
//  cocoaNEC
//
//  Created by Kok Chen on 4/14/08.
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

	#import <Cocoa/Cocoa.h>
	#import "coordinate.h"

	typedef struct {
		int wire ;
		int segments ;
		Coordinate end[2] ;
		float radius ;
		int startSegment ;
		int endSegment ;
		int tag ;					//  NOTE: tag is not unique, different wires could have the same tag.  segment numbers (startSegment, endSegment) are however unique.
	} StructureInfo ;

	@interface StructureElement : NSObject {
		StructureInfo g ;
	}
	
	- (id)initWithLine:(char*)string ;
	- (id)initWithLine:(char*)string wireNumber:(int)wireNumber segments:(int)segments start:(int)start tag:(int)tag ;
	- (id)initWithStructureElement:(StructureElement*)old ;
	
	- (StructureInfo*)info ;
	- (int)tag ;
	
	@end
