//
//  Pattern3dView.h
//  cocoaNEC
//
//  Created by Kok Chen on 10/18/07.
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

#import "RadiationPattern.h"
#import "PrintableView.h"
#import "Polarization.h"

typedef struct {
    float power ;
    float x, y, z ;
    float shade ;
} Node ;

typedef struct {
    float x0, y0, z0, p0 ;
    float x1, y1, z1, p1 ;
    float x2, y2, z2, p2 ;
    float x3, y3, z3, p3 ;
    float power ;
    float s0, s1, s2, s3 ;
} Patch ;

@interface Pattern3dView : PrintableView {
    RadiationPattern *pattern ;
    Node node[91][121] ;			//  2 degree x 3 degree resolution
    float center[91][121] ;
    NSColor *plotColor[257] ;
    
    NSAffineTransform *scale ;
    double rho ;
    double azimuth ;
    intType gainPolarization ;
    Boolean usePhong ;
    float contrast ;
}

- (void)setPattern:(RadiationPattern*)pattern ;
- (RadiationPattern*)pattern ;
- (void)setGainScale:(double)s ;
- (double)gainScale ;
- (void)setAngle:(float)angle ;
- (float)angle ;
- (void)setContrast:(float)value ;
- (float)contrast ;
- (void)setGainPolarization:(intType)pol ;
- (void)setPlotType:(intType)type ;
- (int)plotType ;
	
@end
