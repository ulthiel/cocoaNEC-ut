//
//  RadiationPattern.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/23/07.
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
#import "Config.h"

@interface RadiationPattern : NSObject {
    NSArray *array ;
    float mintheta, maxtheta ;
    float minphi, maxphi ;
    float meanTheta, meanPhi ;
    float maxTheta, maxPhi ;
    float maxDBv, maxDBh, maxDBt, maxDBl, maxDBr ;
    float thetaAtMaxGain, phiAtMaxGain ;
    double frequency ;
    Boolean isReference ;
    Boolean isSweep ;
    float dPhi, dTheta ;		//  v0.69
}

- (id)initWithArray:(NSArray*)inputArray frequency:(double)freq ;
- (void)setSweep:(Boolean)sweep ;

- (NSArray*)array ;
- (intType)count ;
- (Boolean)isReference ;
- (Boolean)isSweep ;

- (float)thetaRange ;
- (float)meanTheta ;
- (float)maxTheta ;
- (float)phiRange ;
- (float)meanPhi ;
- (float)maxPhi ;
- (float)maxDBv ;
- (float)maxDBh ;
- (float)maxDBt ;
- (float)maxDBl ;				//  v0.67
- (float)maxDBr ;				//  v0.67
- (float)thetaAtMaxGain ;
- (float)phiAtMaxGain ;
- (double)frequency ;
- (float)dPhi ;					//  v0.69
- (float)dTheta ;				//  v0.69

@end
