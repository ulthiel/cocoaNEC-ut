//
//  NCGeometry.h
//  cocoaNEC
//
//  Created by Kok Chen on 5/4/12.
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

#import "NCVector.h"
#import "NCStructs.h"

//  v0.77 : coordinates now changed to a WireCoord structure
@interface NCGeometry : NSObject {
	WireCoord end1 ;
	WireCoord end2 ;
}

- (id)initWithEnd1:(WireCoord*)e1 end2:(WireCoord*)e2 ;
- (id)geometryFrom:(double)start to:(double)end ;
+ (id)geometryWithEnd1:(WireCoord*)e1 end2:(WireCoord*)e2 ;
+ (id)geometryFromCoord:(WireCoord*)e1 delta:(WireCoord*)delta ;

- (void)shortenEndsBy:(double)delta ;

+ (WireCoord)addCoord:(WireCoord*)delta toCoord:(WireCoord*)coord ;
+ (WireCoord)subtractCoord:(WireCoord*)delta fromCoord:(WireCoord*)coord ;
+ (WireCoord)midpointBetweenCoord:(WireCoord*)w1 andCoord:(WireCoord*)w2 ;
+ (WireCoord)scaleCoord:(WireCoord*)coord factor:(double)r ;
+ (WireCoord)scaleCoord:(WireCoord*)coord toLength:(double)r ;
+ (double)distanceBetweenCoord:(WireCoord*)coord1 andCoord:(WireCoord*)coord2 ;
+ (double)magnitudeOfCoord:(WireCoord*)coord ;
+ (double)dotProduct:(WireCoord*)coord1 withCoord:(WireCoord*)coord2 ;
+ (WireCoord)crossProduct:(WireCoord*)coord1 withCoord:(WireCoord*)coord2 ;

- (WireCoord*)end:(int)which ;
- (WireCoord*)end1 ;
- (void)setEnd1:(WireCoord*)coord ;
- (void)setEnd1FromVector:(NCVector*)vector ;
- (WireCoord*)end2 ;
- (void)setEnd2:(WireCoord*)coord ;
- (void)setEnd2FromVector:(NCVector*)vector ;
- (WireCoord)midpoint ;
- (WireCoord)midpointWithDisplacement:(double)displacement ;	//  v0.81
- (WireCoord)coordAtFraction:(double)fraction ;
- (WireCoord)span ;
- (WireCoord)spanWithLength:(double)length ;
- (double)length ;

@end
