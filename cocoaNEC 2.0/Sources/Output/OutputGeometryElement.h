//
//  OutputGeometryElement.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/1/07.
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
	#import "coordinate.h"

	typedef struct {
		int tag ;
		int segment ;
		float length ;
		float real ;
		float imag ;
		float mag ;
		float phase ;
		float current ;					//  mag normalized to 1.0
		float angle ;					//  phase relative to largest current, normalized to 1 (1.0 == 360 degrees)
		float currentGradient ;
		float maxCurrent ;				//  v0.81e used for normalizing real and imaginary component in WireCurrent
		Coordinate coord ;
		Coordinate end[2] ;
	} GeometryInfo ;
	
	typedef struct {
		GeometryInfo v[4] ;
	} UnitVectors ;

	@interface OutputGeometryElement : NSObject {
		GeometryInfo g ;
	}
	
	- (id)initWithLine:(char*)string ;
	- (GeometryInfo*)info ;
	- (int)tag ;
	
	- (NSComparisonResult)compareZ:(OutputGeometryElement*)cpr ;

	@end
