//
//  Transform.h
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
	#import "coordinate.h"
	#import "OutputGeometryElement.h"

	@interface Transform : NSObject {

	}

	+ (void)initializeGeometryElements:(NSArray*)arrayOfElements origin:(Coordinate*)origin ;

	+ (void)rotateX:(NSArray*)arrayOfElements angle:(float)angle ;
	+ (void)rotateY:(NSArray*)arrayOfElements angle:(float)angle ;
	+ (void)rotateZ:(NSArray*)arrayOfElements angle:(float)angle ;
	+ (void)reset:(NSArray*)arrayOfElements ;
	
	+ (void)projectElevation:(NSArray*)arrayOfElements angle:(float)angle ;
	
	//	v0.75c
	+ (void)initializeUnitVectors:(GeometryInfo*)info ;
	+ (void)rotateUnitVectorsX:(GeometryInfo*)info angle:(float)angle ;
	+ (void)rotateUnitVectorsZ:(GeometryInfo*)info angle:(float)angle ;

	
	@end
