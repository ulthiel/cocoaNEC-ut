//
//  NCSystem.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/18/07.
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
#import "NCNode.h" 
#import "NCDeck.h"
#import "NCNetwork.h"
#import "NCSymbolTable.h"
#import "Feedpoint.h"
#import "RunInfo.h"
#import "Config.h"


@interface NCSystem : NSObject {
    int tag ;
    NCSymbolTable *symbolTable ;
    RuntimeStack *stack ;
    NSMutableArray *frequencyArray ;
    char modelName[256] ;
    
    NSMutableArray *azimuthPlots ;					//  array of elevation angles
    NSMutableArray *elevationPlots ;				//  array of azimuth angles
    NSMutableArray *radials ;						//  array of NCRadial objects
    
    NCObject *freqObject, *wlObject, *dieObject, *condObject ;		//  v0.55	Spreadsheet constants
    
    double dielectric ;
    double conductivity ;
    Boolean	isFreeSpace ;
    Boolean isPerfectGround ;
    Boolean isSommerfeld ;
    Boolean hasFrequencyDependentNetwork ;			//  v0.81 
    
    Boolean isUseExtendedKernel ;
    Boolean abort ;
    
    float azimuthPlotDistance ;
    float elevationPlotDistance ;
    
    double farFieldDisplacement ;					//  v0.81
    
    int documentNumber ;
    RunInfo result ;
    int runLoops ;
    Boolean useQuadPrecision ;
    Boolean keepDataBetweenModelRuns ;					//  v0.81d
    
    FeedpointInfo feedpointInfo ;
}

- (id)initIntoGlobals:(NCSymbolTable*)table documentNumber:(int)inDocumentNumber ;

- (id)initIntoSpreadsheetGlobals:(NCSymbolTable*)table ;
- (void)setSpreadSheetFrequency:(double)freq dielectric:(double)dielec conductivity:(double)conduct ;

- (RuntimeStack*)runtimeStack ;
- (void)setRuntimeStack:(RuntimeStack*)inStack ;

//	v0.81
- (void)setHasFrequencyDependentNetwork:(Boolean)value ;
- (Boolean)hasFrequencyDependentNetwork ;

- (int)tags ;		//  total geometry tags generated
- (NSArray*)frequencyArray ;
- (char*)modelName ;
- (void)setModelName:(char*)name ;

//  v0.81
- (double)farFieldDisplacement ;					
- (void)resetFarFieldDisplacement ;

- (NSArray*)azimuthPlots ;
- (float)azimuthPlotDistance ;
- (NSArray*)elevationPlots ;
- (float)elevationPlotDistance ;
- (NSArray*)radials ;
- (void)clearRadialsAndPlots ;

- (void)setRunLoops:(int)count ;

- (Boolean)abort ;
- (void)clearAbort ;
- (void)setAbort ;

- (Boolean)useQuadPrecision ;
- (void)setUseQuadPrecision:(Boolean)state ;

//  v0.81d
- (Boolean)keepDataBetweenModelRuns ;		
- (void)setKeepDataBetweenModelRuns:(Boolean)state ;

- (double)dielectric ;
- (double)conductivity ;
- (Boolean)isFreeSpace ;
- (Boolean)isPerfectGround ;
- (Boolean)isSommerfeld ;
- (Boolean)useExtendedKernel ;

// v0.77
- (NCWire*)newWire:(NCGeometry*)geometry radius:(double)radius segments:(int)segments ;
- (NCWire*)wireElement:(WireCoord*)end1 end2:(WireCoord*)end2 radius:(double)radius segments:(int)segments ;
- (NCNetwork*)newTransmissionline:(NCWire*)element1 to:(NCWire*)element2 impedance:(double)impedance ;
- (void)nec4Insulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity conductivity:(double)conductivity ;
- (void)yurkovInsulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity velocityFactor:(double)vf ;
- (void)cebikInsulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity ;

//  v0.81
- (NCWire*)newWire:(WireCoord*)end1 end2:(WireCoord*)end2 radius:(double)radius segments:(int)segments ;

//  v0.88
- (NCValue*)vswr:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointImpedanceReal:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointImpedanceImaginary:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointVoltageReal:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointVoltageImaginary:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointCurrentReal:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)feedpointCurrentImaginary:(NSArray*)args prototype:(NSArray*)prototype ;
- (NCValue*)runModel:(NSArray*)args prototype:(NSArray*)prototype ;

@end
