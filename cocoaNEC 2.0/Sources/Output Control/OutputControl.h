//
//  OutputControl.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/26/07.
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

@interface OutputControl : NSObject {
    IBOutlet id window ;
    IBOutlet id precisionMatrix ;
    IBOutlet id azimuth0Matrix ;
    IBOutlet id azimuth1Matrix ;
    IBOutlet id azimuth2Matrix ;
    IBOutlet id azimuthDistance ;
    IBOutlet id elevationAngle ;
    IBOutlet id elevation0Matrix ;
    IBOutlet id elevation1Matrix ;
    IBOutlet id elevation2Matrix ;
    IBOutlet id elevationDistance ;
    IBOutlet id azimuthAngle ;
    IBOutlet id ekMatrix ;
    IBOutlet id d3Matrix ;
    
    NSMatrix *azimuthMatrix[3] ;
    NSMatrix *elevationMatrix[3] ;
    
    float elevationAngles[3] ;
    float azimuthAngles[3] ;
            
    NSWindow *controllingWindow ;
    
    NSArray *retainedNibObjects ;
}

- (void)setDefaultPattern:(Boolean)seton ;

- (Boolean)isQuadPrecision ;
- (Boolean)isExtendedkernel ;
- (Boolean)is3DSelected ;

- (NSMutableDictionary*)makeDictionaryForPlist  ;
- (void)restoreFromDictionary:(NSDictionary*)dict ;

- (float*)elevationAnglesForAzimuthPlot ;
- (float*)azimuthAnglesForElevationPlot ;

- (int)numberOfAzimuthPlots ;
- (int)numberOfElevationPlots ;

- (float)azimuthDistance ;
- (float)elevationDistance ;

- (IBAction)closeSheet:(id)sender ;
- (void)showSheet:(NSWindow*)controllingWindow ;	

@end
