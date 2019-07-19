//
//  WireGeometry.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/7/07.
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


	#import "ElementGeometry.h"

	typedef struct {
		int segments ;
		double radius ;
		double from[3], to[3] ;
		int excitationKind ;			//  0 = none, 1 = voltage, 2 = current, 3 = Hollerith
		int tag ;
		int excitationLocation ;		//  segment number (1 based)
		double excitationVector[2] ;	//  real and imaginary parts of vooltage or current
	} WireInfo ;

	@interface WireGeometry : ElementGeometry {
		WireInfo info ;
	}
	
	- (WireInfo*)info ;
	
	- (NSString*)radiusFormula ;
	- (void)setRadiusFormula:(NSString*)str ;
	
	- (NSString*)segmentsFormula ;
	- (void)setSegmentsFormula:(NSString*)str ;
	
	@end
