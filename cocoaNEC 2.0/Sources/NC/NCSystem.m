//
//  NCSystem.m
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

#import "NCSystem.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "NC.h"
#import "NCCoaxCable.h"
#import "NCExcitation.h"
#import "NCFunctionObject.h"
#import "NCLine.h"
#import "NCRadials.h"
#import "NCTaperedWire.h"
#import "NCTermination.h"
#import "NCTerminationF.h"

#import "NCHelix.h"
#import "NCPatch.h"
#import "NCMultiplePatch.h"
#import	"NCGACard.h"
#import	"NCGCCard.h"
#import	"NCGRCard.h"
#import	"NCGSCard.h"
#import	"NCSPCard.h"
#import "NCEXCard.h"
#include <complex.h>

//  system functions for NC

@implementation NCSystem

#define	radians	( 3.141592653589/180.0 )

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		stack = nil ;
		strcpy( modelName, "cocoaNEC" ) ;
		frequencyArray = [ [ NSMutableArray alloc ] initWithCapacity:10 ] ;
		azimuthPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		elevationPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		azimuthPlotDistance = 5000.0 ;
		elevationPlotDistance = 5000.0 ;
		radials = [ [ NSMutableArray alloc ] initWithCapacity:2 ] ;
		documentNumber = 0 ;
	}
	return self ;
}

//	v0.55
- (float)azimuthPlotDistance
{
	return azimuthPlotDistance ;
}

//	v0.55
- (float)elevationPlotDistance
{
	return elevationPlotDistance ;
}

- (void)dealloc
{
	[ azimuthPlots release ] ;
	[ elevationPlots release ] ;
	[ radials release ] ;
	[ frequencyArray release ] ;
	[ super dealloc ] ;
}

- (void)makeSystem:(Boolean)asSpreadsheet
{
	short noPrototype[] = { 0 } ;
	short boolPrototype[] = { INTTYPE, 0 } ;
	short intPrototype[] = { INTTYPE, 0 } ;
	short realPrototype[] = { REALTYPE, 0 } ;
	short complexPrototype[] = { REALTYPE, REALTYPE, 0 } ;
	short sweepPrototype[] = { REALTYPE, REALTYPE, INTTYPE, 0 } ;										//  v0.70
	short insulatePrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;						//  v0.73
	short cebikInsulatePrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, 0 } ;							//  v0.77
	short plotAnglePrototype[] = { REALTYPE, 0 } ;
	short varPrototype[] = { VARARGS, 0 } ;
	short radialsPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, 0 } ;
	short conductivityPrototype[] = { ELEMENTTYPE, REALTYPE, 0 } ;
	short complexElementPropertyPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, 0 } ;
	short rlcElementPropertyPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;			//  v0.83
	short complexElementPropertySegmentPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, INTTYPE, 0 } ;
	short planewaveElementPropertyPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short rlcLoadPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short simpleLoadPrototype[] = { ELEMENTTYPE, REALTYPE, 0 } ;                                        //  v0.92
	
	short wirePrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, 0 } ;
	short taperedWirePrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;

	short wireCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, 0 } ;
	short arcCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short helixCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short patchCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short rectpatchCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short quadpatchCardPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short multipatchCardPrototype[] = { INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;

	short transmissionLinePrototype[] = { ELEMENTTYPE, ELEMENTTYPE, REALTYPE, 0 } ;
	short longTransmissionLinePrototype[] = { ELEMENTTYPE, ELEMENTTYPE, REALTYPE, REALTYPE, 0 } ;
	short fullTransmissionLinePrototype[] = { ELEMENTTYPE, ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short necRadialsPrototype[] = { REALTYPE, REALTYPE, INTTYPE, 0 } ;
	
	//  wire related system functions
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"wire" type:ELEMENTTYPE selector:@selector(wire:prototype:) argPrototypes:wirePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"taperedWire" type:ELEMENTTYPE selector:@selector(taperedWire:prototype:) argPrototypes:taperedWirePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"line" type:ELEMENTTYPE selector:@selector(line:prototype:) argPrototypes:wirePrototype ] ] ;

	//  Spreadsheet support
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"wireCard" type:ELEMENTTYPE selector:@selector(wireCard:prototype:) argPrototypes:wireCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"arcCard" type:ELEMENTTYPE selector:@selector(arcCard:prototype:) argPrototypes:arcCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"helixCard" type:ELEMENTTYPE selector:@selector(helixCard:prototype:) argPrototypes:helixCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"patchCard" type:ELEMENTTYPE selector:@selector(patchCard:prototype:) argPrototypes:patchCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"rectangularPatchCard" type:ELEMENTTYPE selector:@selector(rectangularPatchCard:prototype:) argPrototypes:rectpatchCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"triangularPatchCard" type:ELEMENTTYPE selector:@selector(triangularPatchCard:prototype:) argPrototypes:rectpatchCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"quadrilateralPatchCard" type:ELEMENTTYPE selector:@selector(quadrilateralPatchCard:prototype:) argPrototypes:quadpatchCardPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"multiplePatchCard" type:ELEMENTTYPE selector:@selector(multiplePatchCard:prototype:) argPrototypes:multipatchCardPrototype ] ] ;

	//  loading
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"impedanceLoad" type:INTTYPE selector:@selector(impedanceLoad:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"lumpedSeriesLoad" type:INTTYPE selector:@selector(lumpedSeriesLoad:prototype:) argPrototypes:rlcLoadPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"lumpedParallelLoad" type:INTTYPE selector:@selector(lumpedParallelLoad:prototype:) argPrototypes:rlcLoadPrototype ] ] ;
  
    //  loading v0.92
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"resistiveLoad" type:INTTYPE selector:@selector(lumpedRLoad:prototype:) argPrototypes:simpleLoadPrototype ] ] ;
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"capacitiveLoad" type:INTTYPE selector:@selector(lumpedCLoad:prototype:) argPrototypes:simpleLoadPrototype ] ] ;
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"inductiveLoad" type:INTTYPE selector:@selector(lumpedLLoad:prototype:) argPrototypes:simpleLoadPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"distributedSeriesLoad" type:INTTYPE selector:@selector(distributedSeriesLoad:prototype:) argPrototypes:rlcLoadPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"distributedParallelLoad" type:INTTYPE selector:@selector(distributedParallelLoad:prototype:) argPrototypes:rlcLoadPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"conductivity" type:INTTYPE selector:@selector(conductivity:prototype:) argPrototypes:conductivityPrototype ] ] ;

	//  v0.81
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"impedanceTermination" type:INTTYPE selector:@selector(impedanceTermination:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;

	//  termination v0.83
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"lumpedSeriesTermination" type:INTTYPE selector:@selector(seriesRLCTermination:prototype:) argPrototypes:rlcElementPropertyPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"lumpedParallelTermination" type:INTTYPE selector:@selector(parallelRLCTermination:prototype:) argPrototypes:rlcElementPropertyPrototype ] ] ;
	
    //  termination v0.92
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"resistiveTermination" type:INTTYPE selector:@selector(lumpedRTermination:prototype:) argPrototypes:simpleLoadPrototype ] ] ;
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"capacitiveTermination" type:INTTYPE selector:@selector(lumpedCTermination:prototype:) argPrototypes:simpleLoadPrototype ] ] ;
    [ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"inductiveTermination" type:INTTYPE selector:@selector(lumpedLTermination:prototype:) argPrototypes:simpleLoadPrototype ] ] ;

	//  dielectric sheaths
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"insulate" type:INTTYPE selector:@selector(insulate:prototype:) argPrototypes:insulatePrototype ] ] ;				//  v0.73
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"yurkovInsulate" type:INTTYPE selector:@selector(yurkovInsulate:prototype:) argPrototypes:insulatePrototype ] ] ;  //  v0.73
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"cebikInsulate" type:INTTYPE selector:@selector(cebikInsulate:prototype:) argPrototypes:cebikInsulatePrototype ] ] ;  //  v0.73

	//  spreadsheet loading
	short loadAtSegmentsPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, INTTYPE, INTTYPE, INTTYPE, 0 } ;
	short conductivityAtSegmentsPrototype[] = { ELEMENTTYPE, REALTYPE, INTTYPE, INTTYPE, 0 } ;
	short impedanceAtSegmentsPrototype[] = { ELEMENTTYPE, REALTYPE, REALTYPE, INTTYPE, INTTYPE, 0 } ;	

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"seriesLoadAtSegments" type:INTTYPE selector:@selector(seriesLoadAtSegments:prototype:) argPrototypes:loadAtSegmentsPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"parallelLoadAtSegments" type:INTTYPE selector:@selector(parallelLoadAtSegments:prototype:) argPrototypes:loadAtSegmentsPrototype ] ] ;	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"conductivityAtSegments" type:INTTYPE selector:@selector(conductivityAtSegments:prototype:) argPrototypes:conductivityAtSegmentsPrototype ] ] ;	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"impedanceAtSegments" type:INTTYPE selector:@selector(impedanceAtSegments:prototype:) argPrototypes:impedanceAtSegmentsPrototype ] ] ;	

	//  excitation
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"voltageFeed" type:INTTYPE selector:@selector(voltageFeed:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"currentFeed" type:INTTYPE selector:@selector(currentFeed:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"voltageFeedAtSegment" type:INTTYPE selector:@selector(voltageFeedAtSegment:prototype:) argPrototypes:complexElementPropertySegmentPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"currentFeedAtSegment" type:INTTYPE selector:@selector(currentFeedAtSegment:prototype:) argPrototypes:complexElementPropertySegmentPrototype ] ] ;	
	//  added v0.85
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"currentFeedWithPhasor" type:INTTYPE selector:@selector(currentFeedWithPhasor:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"currentFeedWithPhasord" type:INTTYPE selector:@selector(currentFeedWithPhasord:prototype:) argPrototypes:complexElementPropertyPrototype ] ] ;	

	//  incident plane wave excitation
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"incidentPlaneWave" type:INTTYPE selector:@selector(incidentPlaneWave:prototype:) argPrototypes:planewaveElementPropertyPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"rightPolarizedIncidentPlaneWave" type:INTTYPE selector:@selector(righthandPlaneWave:prototype:) argPrototypes:planewaveElementPropertyPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"leftPolarizedIncidentPlaneWave" type:INTTYPE selector:@selector(lefthandPlaneWave:prototype:) argPrototypes:planewaveElementPropertyPrototype ] ] ;
	
	//  network and transmission lines
	short networkPrototype[] = { ELEMENTTYPE, ELEMENTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short networkAtSegmentsPrototype[] = { ELEMENTTYPE, INTTYPE, ELEMENTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short transmissionAtSegmentsPrototype[] = { ELEMENTTYPE, INTTYPE, ELEMENTTYPE, INTTYPE, REALTYPE, REALTYPE, 0 } ;		//  v0.85 accept length parameter (REALTYPE)

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"network" type:INTTYPE selector:@selector(network:prototype:) argPrototypes:networkPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"networkAtSegments" type:INTTYPE selector:@selector(networkAtSegments:prototype:) argPrototypes:networkAtSegmentsPrototype ] ] ;								//  v0.55

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"transmissionLine" type:INTTYPE selector:@selector(transmissionLine:prototype:) argPrototypes:transmissionLinePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedTransmissionLine" type:INTTYPE selector:@selector(crossedTransmissionLine:prototype:) argPrototypes:transmissionLinePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"longTransmissionLine" type:INTTYPE selector:@selector(longTransmissionLine:prototype:) argPrototypes:longTransmissionLinePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedLongTransmissionLine" type:INTTYPE selector:@selector(crossedLongTransmissionLine:prototype:) argPrototypes:longTransmissionLinePrototype ] ] ;			//  v0.48
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"terminatedTransmissionLine" type:INTTYPE selector:@selector(terminatedTransmissionLine:prototype:) argPrototypes:fullTransmissionLinePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedTerminatedTransmissionLine" type:INTTYPE selector:@selector(crossedTerminatedTransmissionLine:prototype:) argPrototypes:fullTransmissionLinePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"transmissionLineAtSegments" type:INTTYPE selector:@selector(transmissionLineAtSegments:prototype:) argPrototypes:transmissionAtSegmentsPrototype ] ] ;				//  v0.55

	//  Physical transmission line models (specific to cocoaNEC) v0.77
	short coaxPrototype[] = { ELEMENTTYPE, ELEMENTTYPE, COAXTYPE, 0 } ;
	short terminatedCoaxPrototype[] = { ELEMENTTYPE, ELEMENTTYPE, COAXTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short endFedCoaxPrototype[] = { ELEMENTTYPE, INTTYPE, ELEMENTTYPE, INTTYPE, COAXTYPE, 0 } ;
	short endFedTerminatedCoaxPrototype[] = { ELEMENTTYPE, INTTYPE, ELEMENTTYPE, INTTYPE, COAXTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short coaxModelPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"coax" type:INTTYPE selector:@selector(coax:prototype:) argPrototypes:coaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedCoax" type:INTTYPE selector:@selector(crossedCoax:prototype:) argPrototypes:coaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"terminatedCoax" type:INTTYPE selector:@selector(terminatedCoax:prototype:) argPrototypes:terminatedCoaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedTerminatedCoax" type:INTTYPE selector:@selector(crossedTerminatedCoax:prototype:) argPrototypes:terminatedCoaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"coaxModel" type:COAXTYPE selector:@selector(coaxModel:prototype:) argPrototypes:coaxModelPrototype ] ] ;
	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"coaxWithShield" type:INTTYPE selector:@selector(coaxWithShield:prototype:) argPrototypes:coaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedCoaxWithShield" type:INTTYPE selector:@selector(crossedCoaxWithShield:prototype:) argPrototypes:coaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"terminatedCoaxWithShield" type:INTTYPE selector:@selector(terminatedCoaxWithShield:prototype:) argPrototypes:terminatedCoaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"crossedTerminatedCoaxWithShield" type:INTTYPE selector:@selector(crossedTerminatedCoaxWithShield:prototype:) argPrototypes:terminatedCoaxPrototype ] ] ;
    
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"endFedCoax" type:INTTYPE selector:@selector(endFedCoax:prototype:) argPrototypes:endFedCoaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"endFedTerminatedCoax" type:INTTYPE selector:@selector(endFedTerminatedCoax:prototype:) argPrototypes:endFedTerminatedCoaxPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"twinleadModel" type:COAXTYPE selector:@selector(twinleadModel:prototype:) argPrototypes:coaxModelPrototype ] ] ;
    
    //  added twinlead family v 0.92
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"twinlead" type:INTTYPE selector:@selector(twinlead:prototype:) argPrototypes:coaxPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"terminatedTwinlead" type:INTTYPE selector:@selector(terminatedTwinlead:prototype:) argPrototypes:terminatedCoaxPrototype ] ] ;
	
	//  environment system functions
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"setFrequency" type:INTTYPE selector:@selector(setFrequency:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"addFrequency" type:INTTYPE selector:@selector(addFrequency:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"frequencySweep" type:INTTYPE selector:@selector(frequencySweep:prototype:) argPrototypes:sweepPrototype ] ] ;	//  v0.70

	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"radials" type:INTTYPE selector:@selector(radials:prototype:) argPrototypes:radialsPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"azimuthPlotForElevationAngle" type:INTTYPE selector:@selector(azimuthPlotForElevationAngle:prototype:) argPrototypes:plotAnglePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"elevationPlotForAzimuthAngle" type:INTTYPE selector:@selector(elevationPlotForAzimuthAngle:prototype:) argPrototypes:plotAnglePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"setAzimuthPlotDistance" type:INTTYPE selector:@selector(setAzimuthPlotDistance:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"setElevationPlotDistance" type:INTTYPE selector:@selector(setElevationPlotDistance:prototype:) argPrototypes:realPrototype ] ] ;

	//  math functions
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"sin" type:REALTYPE selector:@selector(sin:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"sind" type:REALTYPE selector:@selector(sind:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"cos" type:REALTYPE selector:@selector(cos:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"cosd" type:REALTYPE selector:@selector(cosd:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"tan" type:REALTYPE selector:@selector(tan:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"tand" type:REALTYPE selector:@selector(tand:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"atan" type:REALTYPE selector:@selector(atan:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"atand" type:REALTYPE selector:@selector(atand:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"atan2" type:REALTYPE selector:@selector(atan2:prototype:) argPrototypes:complexPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"atan2d" type:REALTYPE selector:@selector(atan2d:prototype:) argPrototypes:complexPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"asin" type:REALTYPE selector:@selector(asin:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"asind" type:REALTYPE selector:@selector(asind:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"acos" type:REALTYPE selector:@selector(acos:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"acosd" type:REALTYPE selector:@selector(acosd:prototype:) argPrototypes:realPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"sqrt" type:REALTYPE selector:@selector(sqrt:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"pow" type:REALTYPE selector:@selector(pow:prototype:) argPrototypes:complexPrototype ] ] ;
    //  Bug fix Jan 25, 2018, was typo to sqrt selector, reported by K6AVP
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"exp" type:REALTYPE selector:@selector(exp:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"ln" type:REALTYPE selector:@selector(log:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"log" type:REALTYPE selector:@selector(log:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"log10" type:REALTYPE selector:@selector(log10:prototype:) argPrototypes:realPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"abs" type:INTTYPE selector:@selector(abs:prototype:) argPrototypes:intPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"fabs" type:REALTYPE selector:@selector(fabs:prototype:) argPrototypes:realPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"sinh" type:REALTYPE selector:@selector(sinh:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"cosh" type:REALTYPE selector:@selector(cosh:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"tanh" type:REALTYPE selector:@selector(tanh:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"asinh" type:REALTYPE selector:@selector(asinh:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"acosh" type:REALTYPE selector:@selector(acosh:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"atanh" type:REALTYPE selector:@selector(atanh:prototype:) argPrototypes:realPrototype ] ] ;

	//  grounds
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"freespace" type:INTTYPE selector:@selector(freeSpace:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"poorGround" type:INTTYPE selector:@selector(poorGround:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"averageGround" type:INTTYPE selector:@selector(averageGround:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"goodGround" type:INTTYPE selector:@selector(goodGround:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"perfectGround" type:INTTYPE selector:@selector(perfectGround:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"freshWaterGround" type:INTTYPE selector:@selector(freshWater:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"saltWaterGround" type:INTTYPE selector:@selector(saltWater:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"ground" type:INTTYPE selector:@selector(ground:prototype:) argPrototypes:complexPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"useSommerfeldGround" type:INTTYPE selector:@selector(useSommerfeldGround:prototype:) argPrototypes:boolPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"useExtendedKernel" type:INTTYPE selector:@selector(useExtendedKernel:prototype:) argPrototypes:boolPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"necRadials" type:INTTYPE selector:@selector(useNECRadials:prototype:) argPrototypes:necRadialsPrototype ] ] ;

	//  system
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"useQuadPrecision" type:INTTYPE selector:@selector(useQuadPrecision:prototype:) argPrototypes:intPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"keepDataBetweenModelRuns" type:INTTYPE selector:@selector(keepDataBetweenModelRuns:prototype:) argPrototypes:intPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"printf" type:INTTYPE selector:@selector(print:prototype:) argPrototypes:varPrototype ] ] ;	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"pause" type:INTTYPE selector:@selector(pause:prototype:) argPrototypes:realPrototype ] ] ;

	if ( !asSpreadsheet ) {
		[ symbolTable addObject:[ [ NCObject alloc ] initWithRealVariable:"pi" value:3.14159265358979323 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithRealVariable:"c" value:299.792458 ] ] ;
		//  v0.81b coax constants
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG6" value:RG6Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG6hdtv" value:RG6HDTVCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG6catv" value:RG6CATVCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG8" value:RG8Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG8foam" value:RG8FoamCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG8X" value:RG8xCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG11" value:RG11Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG11foam" value:RG11FoamCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG58" value:RG58Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG58foam" value:RG58FoamCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG59" value:RG59Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG59foam" value:RG59FoamCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG62" value:RG62Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG174" value:RG174Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"RG213" value:RG213Coax ] ] ;

		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR100" value:LMR100Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR200" value:LMR200Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR240" value:LMR240Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR300" value:LMR300Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR400" value:LMR400Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR600" value:LMR600Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LMR900" value:LMR900Coax ] ] ;

		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"BuryFLEX" value:BURYFLEXCoax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LDF4" value:LDF4Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LDF5" value:LDF5Coax ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"LDF6" value:LDF6Coax ] ] ;
		
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman551" value:Wireman551 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman552" value:Wireman552 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman553" value:Wireman553 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman554" value:Wireman554 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman551wet" value:Wireman551Ice ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman552wet" value:Wireman552Ice ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman553wet" value:Wireman553Ice ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Wireman554wet" value:Wireman554Ice ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Generic450ohm" value:Window450Type ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"Generic600ohm" value:Ladder600Type ] ] ;

        //  v0.92 added JSC Wire and Cable #1318 (18 AWG)
		[ symbolTable addObject:[ [ NCObject alloc ] initWithCoaxVariable:"JSC1318" value:JSC1318 ] ] ;
	}
	else {
		[ symbolTable addObject:[ [ NCObject alloc ] initWithRealVariable:"g_pi" value:3.14159265358979323 ] ] ;
		[ symbolTable addObject:[ [ NCObject alloc ] initWithRealVariable:"g_c" value:299.792458 ] ] ;
		// these should be set before executing a function
		[ symbolTable addObject:freqObject = [ [ NCObject alloc ] initWithRealVariable:"g_frequency" value:DefaultFrequency ] ] ;
		[ symbolTable addObject:wlObject = [ [ NCObject alloc ] initWithRealVariable:"g_wavelength" value:299.792458/DefaultFrequency ] ] ;
		[ symbolTable addObject:dieObject = [ [ NCObject alloc ] initWithRealVariable:"g_dielectric" value:20.0 ] ] ;
		[ symbolTable addObject:condObject = [ [ NCObject alloc ] initWithRealVariable:"g_conductivity" value:0.0303 ] ] ;
	}
	[ symbolTable addObject:[ [ NCObject alloc ] initAsNil:"nil" ] ] ;
	
	//  NEC Geometry cards
	short gwPrototype[] = { INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short gaPrototype[] = { INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short gcPrototype[] = { REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short grPrototype[] = { INTTYPE, INTTYPE, 0 } ;
	short gsPrototype[] = { REALTYPE, 0 } ;
	short spPrototype[] = { INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short smPrototype[] = { INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gwCard" type:CARDTYPE selector:@selector(gw:prototype:) argPrototypes:gwPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gaCard" type:CARDTYPE selector:@selector(ga:prototype:) argPrototypes:gaPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gcCard" type:CARDTYPE selector:@selector(gc:prototype:) argPrototypes:gcPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"ghCard" type:CARDTYPE selector:@selector(gh:prototype:) argPrototypes:gwPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gmCard" type:CARDTYPE selector:@selector(gm:prototype:) argPrototypes:gwPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"grCard" type:CARDTYPE selector:@selector(gr:prototype:) argPrototypes:grPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gsCard" type:CARDTYPE selector:@selector(gs:prototype:) argPrototypes:gsPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"gxCard" type:CARDTYPE selector:@selector(gx:prototype:) argPrototypes:grPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"spCard" type:CARDTYPE selector:@selector(sp:prototype:) argPrototypes:spPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"scCard" type:CARDTYPE selector:@selector(sc:prototype:) argPrototypes:spPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"smCard" type:CARDTYPE selector:@selector(sm:prototype:) argPrototypes:smPrototype ] ] ;

	//  NEC control cards
	short exPrototype[] = { INTTYPE, INTTYPE, INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short ldPrototype[] = { INTTYPE, INTTYPE, INTTYPE, INTTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"exCard" type:CARDTYPE selector:@selector(ex:prototype:) argPrototypes:exPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"ldCard" type:CARDTYPE selector:@selector(ld:prototype:) argPrototypes:ldPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"ntCard" type:CARDTYPE selector:@selector(nt:prototype:) argPrototypes:exPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"tlCard" type:CARDTYPE selector:@selector(tl:prototype:) argPrototypes:exPrototype ] ] ;
	
	//	vectors v0.53
	short vectorPrototype[] = { REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short vectorArgPrototype[] = { VECTORTYPE, 0 } ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"vect" type:VECTORTYPE selector:@selector(vect:prototype:) argPrototypes:vectorPrototype ] ] ;

	//	transform functions v0.53
	short vectorWirePrototype[] = { TRANSFORMTYPE, VECTORTYPE, VECTORTYPE, REALTYPE, INTTYPE, 0 } ;
	short vectorTaperedWirePrototype[] = { TRANSFORMTYPE, VECTORTYPE, VECTORTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	short matrixPrototype[] = { TRANSFORMTYPE, INTTYPE, INTTYPE, 0 } ;
	short translationPrototype[] = { TRANSFORMTYPE, INTTYPE, 0 } ;
	short setMatrixPrototype[] = { REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, REALTYPE, 0 } ;
	
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"identityTransform" type:TRANSFORMTYPE selector:@selector(identityTransform:prototype:) argPrototypes:noPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"translateTransform" type:TRANSFORMTYPE selector:@selector(translateTransform:prototype:) argPrototypes:vectorArgPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"rotateX" type:TRANSFORMTYPE selector:@selector(rotateX:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"rotateY" type:TRANSFORMTYPE selector:@selector(rotateY:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"rotateZ" type:TRANSFORMTYPE selector:@selector(rotateZ:prototype:) argPrototypes:realPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"matrixElement" type:REALTYPE selector:@selector(matrixElement:prototype:) argPrototypes:matrixPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"translationElement" type:REALTYPE selector:@selector(translationElement:prototype:) argPrototypes:translationPrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"transformWithMatrix" type:TRANSFORMTYPE selector:@selector(transformWithMatrix:prototype:) argPrototypes:setMatrixPrototype ] ] ;

	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"wirev" type:ELEMENTTYPE selector:@selector(wirev:prototype:) argPrototypes:vectorWirePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"linev" type:ELEMENTTYPE selector:@selector(linev:prototype:) argPrototypes:vectorWirePrototype ] ] ;
	[ symbolTable addObject:[ [ NCFunctionObject alloc ] initWithSystem:"taperedWirev" type:ELEMENTTYPE selector:@selector(taperedWirev:prototype:) argPrototypes:vectorTaperedWirePrototype ] ] ;
}

//	v0.81  unique displacement of a wiresegment in the far field
- (double)farFieldDisplacement
{
	farFieldDisplacement += 0.5 ;
	return farFieldDisplacement ;
}

//  v0.81
- (void)resetFarFieldDisplacement
{
	farFieldDisplacement = 999.5 ;			
}

- (id)initIntoGlobals:(NCSymbolTable*)table documentNumber:(int)inDocumentNumber
{
	self = [ super init ] ;
	if ( self ) {
		tag = 0 ;
		symbolTable = table ;
		stack = nil ;
		documentNumber = inDocumentNumber ;
		strcpy( modelName, "cocoaNEC" ) ;
		runLoops = 0 ;						// block runModel
		useQuadPrecision = abort = keepDataBetweenModelRuns = NO ;

		azimuthPlotDistance = 5000.0 ;
		elevationPlotDistance = 5000.0 ;
		[ self resetFarFieldDisplacement ] ;
		
		//  default to good ground
		conductivity = 0.0303 ;
		dielectric = 20.0 ;
		isFreeSpace = isPerfectGround = isSommerfeld = isUseExtendedKernel = NO ;
		[ self makeSystem:NO ] ;
		frequencyArray = [ [ NSMutableArray alloc ] initWithCapacity:10 ] ;
		azimuthPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		elevationPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		radials = [ [ NSMutableArray alloc ] initWithCapacity:2 ] ;
	}
	return self ;
}

//	v0.55
- (id)initIntoSpreadsheetGlobals:(NCSymbolTable*)table
{
	self = [ super init ] ;
	if ( self ) {
		tag = 0 ;
		symbolTable = table ;
		stack = nil ;
		documentNumber = 0 ;
		strcpy( modelName, "cocoaNEC" ) ;
		runLoops = 0 ;						// block runModel
		useQuadPrecision = abort = keepDataBetweenModelRuns = NO ;
		
		azimuthPlotDistance = 5000.0 ;
		elevationPlotDistance = 5000.0 ;
		[ self resetFarFieldDisplacement ] ;
	
		//  default to good ground
		conductivity = 0.0303 ;
		dielectric = 20.0 ;
		isFreeSpace = isPerfectGround = isSommerfeld = isUseExtendedKernel = NO ;

		[ self makeSystem:YES ] ;
		frequencyArray = [ [ NSMutableArray alloc ] initWithCapacity:10 ] ;
		azimuthPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		elevationPlots = [ [ NSMutableArray alloc ] initWithCapacity:6 ] ;
		radials = [ [ NSMutableArray alloc ] initWithCapacity:2 ] ;
	}
	return self ;
}

//	v0.77
static double doubleValue( NSArray* args, int index ) 
{
	NCValue *value ;
	
	value = [ args objectAtIndex:index ] ;
	return ( ( value != nil ) ? [ value doubleValue ] : 0 ) ;
}

//	v0.77
static int intValue( NSArray* args, int index ) 
{
	NCValue *value ;
	
	value = [ args objectAtIndex:index ] ;
	return ( ( value != nil ) ? [ value intValue ] : 0 ) ;
}

//	v0.77
static WireCoord coordValue( NSArray* args, int index ) 
{
	WireCoord end ;
	
	end.x = doubleValue( args, index ) ;
	end.y = doubleValue( args, index+1 ) ;
	end.z = doubleValue( args, index+2 ) ;
	
	return end ;
}

//  v0.55
- (void)setSpreadSheetFrequency:(double)freq dielectric:(double)dielec conductivity:(double)conduct
{
	if ( freq < .00001 ) freq = .00001 ;
	
	[ freqObject setRealValue:freq ] ;
	[ wlObject setRealValue:299.792458/freq ] ;
	[ dieObject setRealValue:dielec ] ;
	[ condObject setRealValue:conduct ] ;
}

- (int)tags
{	
	return tag ;
}

- (void)setRuntimeStack:(RuntimeStack*)inStack 
{
	stack = inStack ;
}

//	v0.81b
- (RuntimeStack*)runtimeStack
{
	return stack ;
}

//	v0.81
- (void)setHasFrequencyDependentNetwork:(Boolean)value 
{
	hasFrequencyDependentNetwork = value ;
}

//	v0.81
- (Boolean)hasFrequencyDependentNetwork
{
	return hasFrequencyDependentNetwork ;
}

//  v0.78
//	function regures NEC-4 to work.  Returns true if NEC-4 is selected
- (Boolean)functionRequiresNEC42:(char*)name
{
	int engine ;
	
	engine = [ [ NSApp delegate ] engine ];	
	if ( engine == kNEC42Engine || engine == kNEC42EngineGN2 ) return YES ;
	
	if ( stack != nil ) [ stack->errors addObject:[ NSString stringWithFormat:@"The function %s requires NEC-4.2 engine to run, please select NEC-4.2 in cocoaNEC preferences", name ] ] ;
	return NO ;
}

//  v0.73
//	function regures NEC-4 to work.  Returns true if NEC-4 is selected
- (Boolean)functionRequiresNEC4:(char*)name
{
	int engine ;
	
	//  v0.78
	engine = [ [ NSApp delegate ] engine ];	
	if ( engine == kNEC41Engine || engine == kNEC42Engine ) return YES ;
	
	if ( stack != nil ) [ stack->errors addObject:[ NSString stringWithFormat:@"The function %s requires NEC-4 engine to run, please select NEC-4.1 or NEC-4.2 in cocoaNEC preferences", name ] ] ;
	return NO ;
}

- (NCValue*)freeSpace:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 0.0 ;
	dielectric = 1.0 ;
	isFreeSpace = YES ;
	isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)poorGround:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 0.001 ;
	dielectric = 3.0 ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)averageGround:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 0.005 ;
	dielectric = 13.0 ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)goodGround:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 0.0303 ;
	dielectric = 20.0 ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)perfectGround:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 5000.0 ;
	dielectric = 1000.0 ;
	isFreeSpace = NO ;
	isPerfectGround = YES ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)freshWater:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 0.001 ;
	dielectric = 80.0 ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)saltWater:(NSArray*)args prototype:(NSArray*)prototype
{
	conductivity = 5.0 ;
	dielectric = 81.0 ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)ground:(NSArray*)args prototype:(NSArray*)prototype
{
	dielectric = doubleValue( args, 0 ) ;
	conductivity = doubleValue( args, 1 ) ;
	isFreeSpace = isPerfectGround = NO ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)useSommerfeldGround:(NSArray*)args prototype:(NSArray*)prototype
{
	isSommerfeld = ( intValue( args, 0 ) != 0 ) ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)useExtendedKernel:(NSArray*)args prototype:(NSArray*)prototype
{
	isUseExtendedKernel = ( intValue( args, 0 ) != 0 ) ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)useNECRadials:(NSArray*)args prototype:(NSArray*)prototype
{
	NC *nc = [ [ NSApp delegate ] currentNC ] ;
	NECRadials *necRadials = [ nc necRadials ] ;
	
	necRadials->useNECRadials = YES ;
	necRadials->length = doubleValue( args, 0 ) ;
	necRadials->wireRadius = doubleValue( args, 1 ) ;
	necRadials->n = intValue( args, 2 ) ;
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)sin:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:sin( arg ) ] ;
}

- (NCValue*)sind:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:sin( arg*radians ) ] ;
}

- (NCValue*)cos:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:cos( arg ) ] ;
}

- (NCValue*)cosd:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:cos( arg*radians ) ] ;
}

- (NCValue*)tan:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:tan( arg ) ] ;
}

- (NCValue*)tand:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:tan( arg*radians ) ] ;
}

- (NCValue*)atan:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:atan( arg ) ] ;
}

- (NCValue*)atand:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:atan( arg )/radians ] ;
}

- (NCValue*)atan2:(NSArray*)args prototype:(NSArray*)prototype
{
	double y = doubleValue( args, 0 ) ;
	double x = doubleValue( args, 1 ) ;
	return [ NCValue valueWithDouble:atan2( y, x ) ] ;
}

- (NCValue*)atan2d:(NSArray*)args prototype:(NSArray*)prototype
{
	double y = doubleValue( args, 0 ) ;
	double x = doubleValue( args, 1 ) ;
	return [ NCValue valueWithDouble:atan2( y, x )/radians ] ;
}

- (NCValue*)asin:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:asin( arg ) ] ;
}

- (NCValue*)asind:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:asin( arg )/radians ] ;
}

- (NCValue*)acos:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:acos( arg ) ] ;
}

- (NCValue*)acosd:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:acos( arg )/radians ] ;
}

- (NCValue*)sqrt:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:sqrt( arg ) ] ;
}

- (NCValue*)pow:(NSArray*)args prototype:(NSArray*)prototype
{
	double y = doubleValue( args, 0 ) ;
	double x = doubleValue( args, 1 ) ;
	return [ NCValue valueWithDouble:pow( y, x ) ] ;
}

- (NCValue*)exp:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:exp( arg ) ] ;
}

- (NCValue*)log:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:log( arg ) ] ;
}

- (NCValue*)log10:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:log10( arg ) ] ;
}

- (NCValue*)abs:(NSArray*)args prototype:(NSArray*)prototype
{
	int arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithInt:abs( arg ) ] ;
}

- (NCValue*)fabs:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:fabs( arg ) ] ;
}

- (NCValue*)sinh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:sinh( arg ) ] ;
}

- (NCValue*)cosh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:cosh( arg ) ] ;
}

- (NCValue*)tanh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:tanh( arg ) ] ;
}

- (NCValue*)asinh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:asinh( arg ) ] ;
}

- (NCValue*)acosh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:acosh( arg ) ] ;
}

- (NCValue*)atanh:(NSArray*)args prototype:(NSArray*)prototype
{
	double arg = doubleValue( args, 0 ) ;
	return [ NCValue valueWithDouble:atanh( arg ) ] ;
}

//  create a wire function and return the NCWire.
//	v0.77 change to using ends instead of unit vectors
- (NCWire*)wireElement:(WireCoord*)end1 end2:(WireCoord*)end2 radius:(double)radius segments:(int)segments
{
	NCWire *element ;
	
	element = [ [ NCWire alloc ] initWithRuntime:stack ] ;
	[ element setEnd1:end1 ] ;
	[ element setEnd2:end2 ] ;
	[ element setRadius:radius ] ;
	[ element setSegments:segments ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//	v0.81
//	Create wire with WireCoords and enter into geometryElement list.
- (NCWire*)newWire:(WireCoord*)end1 end2:(WireCoord*)end2 radius:(double)radius segments:(int)segments
{
	NCWire *element ;
	
	element = [ self wireElement:end1 end2:end2 radius:radius segments:segments ] ;
	[ stack->geometryElements addObject:element ] ;
	
	return element ;
}

//	v0.77
//	Create wire with NCGeoetry and enter into geometryElement list.
- (NCWire*)newWire:(NCGeometry*)geometry radius:(double)radius segments:(int)segments
{
	NCWire *element ;
	
	element = [ self wireElement:[ geometry end1 ] end2:[ geometry end2 ] radius:radius segments:segments ] ;
	[ stack->geometryElements addObject:element ] ;
	
	return element ;
}

//  create a wire function and return the NCWire.
- (NCElement*)wire:(NSArray*)args prototype:(NSArray*)prototype
{
	WireCoord end1, end2 ;
	double radius ;
	int segments ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	radius = doubleValue( args, 6 ) ;
	segments = intValue( args, 7 ) ;

	return [ self wireElement:&end1 end2:&end2 radius:radius segments:segments ] ;
}

//  create a tapered wire function and return the NEC-2 tag of the center.
- (NCElement*)taperedWire:(NSArray*)args prototype:(NSArray*)prototype
{
	NCTaperedWire *element ;
	WireCoord end1, end2 ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	
	element = [ [ NCTaperedWire alloc ] initWithRuntime:stack ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setRadius:doubleValue( args, 6 ) ] ;
	[ element setTaper1:doubleValue( args, 7 ) ] ;
	[ element setTaper2:doubleValue( args, 8 ) ] ;
	[ element setStartingTag:++tag ] ;
	tag += 2 ;
	
	return element ;
}

//  create a wire function and return the NEC-2 tag, with immutable number of segments
- (NCElement*)line:(NSArray*)args prototype:(NSArray*)prototype
{
	NCWire *element ;
	WireCoord end1, end2 ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	
	element = [ [ NCLine alloc ] initWithRuntime:stack ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setRadius:doubleValue( args, 6 ) ] ;
	[ element setSegments:intValue( args, 7 ) ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a wire function (with rotate and translate) and return the NEC-2 tag.
- (NCElement*)wireCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCWire *element ;
	WireCoord end1, end2, rotate, translate ;
	
	element = [ [ NCWire alloc ] initWithRuntime:stack ] ;

	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;	
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	
	[ element setRadius:doubleValue( args, 6 ) ] ;
	[ element setSegments:intValue( args, 7 ) ] ;
	
	rotate = coordValue( args, 8 ) ;
	translate = coordValue( args, 11 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a arc function and return the NEC-2 tag.
- (NCElement*)arcCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCArc *element ;
	WireCoord rotate, translate ;
	
	element = [ [ NCArc alloc ] initWithRuntime:stack ] ;
	[ element setArcRadius:doubleValue( args, 0 ) ] ;
	[ element setStartAngle:doubleValue( args, 1 ) ] ;
	[ element setEndAngle:doubleValue( args, 2 ) ] ;
	[ element setRadius:doubleValue( args, 3 ) ] ;
	[ element setSegments:intValue( args, 4 ) ] ;
	
	rotate = coordValue( args, 5 ) ;
	translate = coordValue( args, 8 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a arc function and return the NEC-2 tag.
- (NCElement*)helixCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCHelix *element ;
	WireCoord rotate, translate ;
	
	element = [ [ NCHelix alloc ] initWithRuntime:stack ] ;
	[ element setTurnsSpacing:doubleValue( args, 0 ) ] ;
	[ element setHelixLength:doubleValue( args, 1 ) ] ;
	[ element setStartRadius:doubleValue( args, 2 ) ] ;
	[ element setEndRadius:doubleValue( args, 3 ) ] ;
	[ element setRadius:doubleValue( args, 4 ) ] ;
	[ element setSegments:intValue( args, 5 ) ] ;
	rotate = coordValue( args, 6 ) ;
	translate = coordValue( args, 9 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create an arbotrary shaped patch and return the NEC-2 tag.
- (NCElement*)patchCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCPatch *element ;
	WireCoord end1, end2, rotate, translate ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
		
	element = [ [ NCPatch alloc ] initWithRuntime:stack ] ;
	[ element setSegments:0 ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	
	rotate = coordValue( args, 6 ) ;
	translate = coordValue( args, 9 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a rectangular patch and return the NEC-2 tag.
- (NCElement*)rectangularPatchCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCPatch *element ;
	WireCoord end1, end2, end3, rotate, translate ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	end3 = coordValue( args, 6 ) ;
	
	element = [ [ NCPatch alloc ] initWithRuntime:stack ] ;
	[ element setSegments:1 ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setEnd3:&end3 ] ;
	
	rotate = coordValue( args, 9 ) ;
	translate = coordValue( args, 12 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a triangular patch and return the NEC-2 tag.
- (NCElement*)triangularPatchCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCPatch *element ;
	WireCoord end1, end2, end3, rotate, translate ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	end3 = coordValue( args, 6 ) ;
	
	element = [ [ NCPatch alloc ] initWithRuntime:stack ] ;
	[ element setSegments:2 ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setEnd3:&end3 ] ;
	
	rotate = coordValue( args, 9 ) ;
	translate = coordValue( args, 12 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a quadrilateral patch function and return the NEC-2 tag.
- (NCElement*)quadrilateralPatchCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCPatch *element ;
	WireCoord end1, end2, end3, end4, rotate, translate ;
	
	end1 = coordValue( args, 0 ) ;
	end2 = coordValue( args, 3 ) ;
	end3 = coordValue( args, 6 ) ;
	end4 = coordValue( args, 9 ) ;
	
	element = [ [ NCPatch alloc ] initWithRuntime:stack ] ;
	[ element setSegments:3 ] ;
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setEnd3:&end3 ] ;
	[ element setEnd4:&end4 ] ;
	
	rotate = coordValue( args, 12 ) ;
	translate = coordValue( args, 15 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.55 create a quadrilateral patch function and return the NEC-2 tag.
- (NCElement*)multiplePatchCard:(NSArray*)args prototype:(NSArray*)prototype
{
	NCMultiplePatch *element ;
	WireCoord end1, end2, end3, rotate, translate ;
	
	end1 = coordValue( args, 2 ) ;
	end2 = coordValue( args, 5 ) ;
	end3 = coordValue( args, 8 ) ;
	
	element = [ [ NCMultiplePatch alloc ] initWithRuntime:stack ] ;
	[ element setNX:doubleValue( args, 0 ) ] ;
	[ element setNY:doubleValue( args, 1 ) ] ;	
	[ element setEnd1:&end1 ] ;
	[ element setEnd2:&end2 ] ;
	[ element setEnd3:&end3 ] ;
	
	rotate = coordValue( args, 11 ) ;
	translate = coordValue( args, 14 ) ;	
	[ element setRotate:&rotate ] ;
	[ element setTranslate:&translate ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//	v0.55  -- added segment (0 means center)
- (NCValue*)feed:(NSArray*)args prototype:(NSArray*)prototype type:(int)type callString:(char*)callString segment:(int)segment
{
	NCValue *param ;
	NCWire *element = nil ;
	NCExcitation *feed ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) element = (NCWire*)[ param elementValue ] ;
	if ( param == nil || element == nil ) {
		if ( stack != nil ) [ stack->errors addObject:[ NSString stringWithFormat:@"undefined element parameter (first argument) for '%s'", callString ] ] ;
		return [ NCValue undefinedValue ] ;
	}
	feed = [ [ [ NCExcitation alloc ] initWithType:type real:doubleValue( args, 1 ) imag:doubleValue( args, 2 ) ] autorelease ] ;
	[ element setExcitation:feed segment:segment ] ;
	
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)voltageFeed:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self feed:args prototype:prototype type:VOLTAGEEXCITATION callString:"voltageFeed" segment:0 ] ;
}

- (NCValue*)currentFeed:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self feed:args prototype:prototype type:CURRENTEXCITATION callString:"currentFeed" segment:0 ] ;
}

//	v0.85
- (NCValue*)currentFeedWithPhasor:(NSArray*)args prototype:(NSArray*)prototype
{
	
	return [ self feed:args prototype:prototype type:CURRENTPHASOR callString:"currentFeedWithPhasor" segment:0 ] ;
}

//	v0.85
- (NCValue*)currentFeedWithPhasord:(NSArray*)args prototype:(NSArray*)prototype
{
	
	return [ self feed:args prototype:prototype type:CURRENTPHASORD callString:"currentFeedWithPhasord" segment:0 ] ;
}

- (NCValue*)voltageFeedAtSegment:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self feed:args prototype:prototype type:VOLTAGEEXCITATION callString:"voltageFeedAtSegment" segment:intValue( args, 3 ) ] ;
}

- (NCValue*)currentFeedAtSegment:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self feed:args prototype:prototype type:CURRENTEXCITATION callString:"currentFeedAtSegment" segment:intValue( args, 3 ) ] ;
}

- (NCValue*)planewaveFeed:(NSArray*)args prototype:(NSArray*)prototype type:(int)type callString:(char*)callString
{
	NCValue *param ;
	NCWire *element = nil ;
	NCExcitation *feed ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) element = (NCWire*)[ param elementValue ] ;
	if ( param == nil || element == nil ) {
		if ( stack != nil ) [ stack->errors addObject:[ NSString stringWithFormat:@"undefined element parameter (first argument) for '%s'", callString ] ] ;
		return [ NCValue undefinedValue ] ;
	}
	
	feed = [ [ [ NCExcitation alloc ] initWithType:type theta:doubleValue( args, 1 ) phi:doubleValue( args, 2 ) eta:doubleValue( args, 3 ) ] autorelease ] ;
	[ element setExcitation:feed segment:0 ] ;
	
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)incidentPlaneWave:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self planewaveFeed:args prototype:prototype type:PLANEEXCITATION callString:"incidentPlaneWave" ] ;
}

- (NCValue*)righthandPlaneWave:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self planewaveFeed:args prototype:prototype type:RIGHTEXCITATION callString:"rightHandPolarizedIncidentPlaneWave" ] ;
}

- (NCValue*)lefthandPlaneWave:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self planewaveFeed:args prototype:prototype type:LEFTEXCITATION callString:"leftHandPolarizedIncidentPlaneWave" ] ;
}

- (NCValue*)impedanceLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad impedanceLoad:doubleValue( args, 1 ) imag:doubleValue( args, 2 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)impedanceAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad impedanceAtSegments:doubleValue( args, 1 ) imag:doubleValue( args, 2 ) s0:intValue( args, 3 ) s1:intValue( args, 4 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)conductivity:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad conductivity:doubleValue( args, 1 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)conductivityAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad conductivityAtSegments:doubleValue( args, 1 ) s0:intValue( args, 2 ) s1:intValue( args, 3 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)rlcLoad:(NSArray*)args prototype:(NSArray*)prototype type:(int)type
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad rlc:type r:doubleValue( args, 1 ) l:doubleValue( args, 2 ) c:doubleValue( args, 3 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//  v0.92
//  type 0 = R, 1 = L, 2 = C
- (NCValue*)simpleLoad:(NSArray*)args prototype:(NSArray*)prototype type:(int)type
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
            switch ( type ) {
            case 0:
            default:
                //  resistor
                load = [ NCLoad rlc:PARALLELRLC r:doubleValue( args, 1 ) l:1.0 c:0.0 ] ;
                break ;
            case 1:
                //  inductor
                load = [ NCLoad rlc:PARALLELRLC r:1.0e6 l:doubleValue( args, 1 ) c:0.0 ] ;
                break ;
            case 2:
                //  capacitor
                load = [ NCLoad rlc:SERIESRLC r:0 l:0 c:doubleValue( args, 1 ) ] ;
                break ;
            }
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)rlcLoadAtSegments:(NSArray*)args prototype:(NSArray*)prototype type:(int)type
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCLoad rlcAtSegments:type r:doubleValue( args, 1 ) l:doubleValue( args, 2 ) c:doubleValue( args, 3 ) perLength:intValue( args, 4 ) s0:intValue( args, 5 ) s1:intValue( args, 6 ) ] ;
			[ element addLoad:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.81
- (NCValue*)impedanceTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	NCTermination *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCTermination impedanceTermination:element real:doubleValue( args, 1 ) imag:doubleValue( args, 2 ) system:self ] ;
			[ element addTermination:load ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)rlcTermination:(NSArray*)args prototype:(NSArray*)prototype type:(int)type
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			load = [ NCTerminationF rlcTermination:element type:type r:doubleValue( args, 1 ) l:doubleValue( args, 2 ) c:doubleValue( args, 3 ) system:self ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//  v0.92
//  type 0 = R, 1 = L, 2 = C
- (NCValue*)simpleTermination:(NSArray*)args prototype:(NSArray*)prototype type:(int)type
{
	NCValue *param ;
	NCWire *element ;
	NCLoad *load ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
            switch ( type ) {
            case 0:
            default:
                //  resistor
                load = [ NCTerminationF rlcTermination:element type:NCPARALLELTERMINATOR r:doubleValue( args, 1 ) l:1.0 c:0.0 system:self ] ;
                break ;
            case 1:
                //  inductor
                load = [ NCTerminationF rlcTermination:element type:NCPARALLELTERMINATOR r:1.0e6 l:doubleValue( args, 1 ) c:0.0 system:self ] ;
                break ;
            case 2:
                //  capacitor
                load = [ NCTerminationF rlcTermination:element type:NCSERIESTERMINATOR r:0 l:0 c:doubleValue( args, 1 ) system:self ] ;
                break ;
            }
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)seriesRLCTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcTermination:args prototype:prototype type:NCSERIESTERMINATOR ] ;

}

- (NCValue*)parallelRLCTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcTermination:args prototype:prototype type:NCPARALLELTERMINATOR ] ;

}

//	0.77 separated out so NCCoax can use Yurkov's approximation for both NEC-2 and NEC4
//
//	v0.75b NEC-2
//	Apply insulation sheath to an NCWire using Yurkov's solution, together with Dimitry (UA3AVR)'s simplification.
//	Assume low dielectric conductivity.
//
//	See section headed "Calculation of model of the antenna with wires in dielectric insulation" at http://www.qsl.net/ua3avr/Read_me_Eng.htm 
//	and http://www.qsl.net/ra9mb/nec.pdf (in Russian).
//
//	kabs is (velocityfactor)^2.  cocoaNEC's implementation assumes a velocity factor of 0.92 instead of the 0.95 suggested by UA3AVR.

- (void)yurkovInsulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity velocityFactor:(double)vf
{
	NCLoad *load ;
	double kabs, L, wireRadius ;
	
	kabs = vf*vf ;
	wireRadius = [ element radius ] ;
	if ( wireRadius < .000001 ) wireRadius = .000001 ;
	L = 2.0e-7*( 1.0 - 1.0/( permittivity * kabs ) )*log( radius/wireRadius ) ;
	if ( L < 0 ) L = 0 ;
	load = [ NCLoad rlc:DISTRIBUTEDSERIESRLC r:0.0 l:L c:0.0 ] ;
	[ element addLoad:load ] ;
	//	change wire radius to insulation radius
	[ element modifyRadius:radius ] ;
}

//	v0.77
- (NCValue*)yurkovInsulate:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	double velocityFactor, permittivity, radius ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			permittivity = doubleValue( args, 1 ) ;
			radius = doubleValue( args, 2 ) ;
			velocityFactor = doubleValue( args, 3 ) ;
			[ self yurkovInsulate:element insulationRadius:radius permittivity:permittivity velocityFactor:velocityFactor ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//	Same as yurkovInsulate (above) but with
//	W4RNL approximation: L = 2.0e-7*pow( radius/wireRadius*permittivity, 1/12.0 )*( 1.0 - 1.0/permittivity )*log( radius/wireRadius )
- (void)cebikInsulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity
{
	NCLoad *load ;
	double L, wireRadius ;
	
	wireRadius = [ element radius ] ;
	if ( wireRadius < .000001 ) wireRadius = .000001 ;
	L = 2.0e-7*pow( radius/wireRadius*permittivity, 1/12.0 )*( 1.0 - 1.0/permittivity )*log( radius/wireRadius ) ;
	load = [ NCLoad rlc:DISTRIBUTEDSERIESRLC r:0.0 l:L c:0.0 ] ;
	[ element addLoad:load ] ;
	//	change wire radius to insulation radius
	[ element modifyRadius:radius ] ;
}

//	v0.77
- (NCValue*)cebikInsulate:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	double permittivity, radius ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element != nil ) {
			permittivity = doubleValue( args, 1 ) ;
			radius = doubleValue( args, 2 ) ;
			[ self cebikInsulate:element insulationRadius:radius permittivity:permittivity ] ;
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.77
- (void)nec4Insulate:(NCWire*)element insulationRadius:(double)radius permittivity:(double)permittivity conductivity:(double)conductive
{
	NCLoad *load ;
	int engine ;

	engine = [ [ NSApp delegate ] engine ] ;
	if ( engine == knec2cEngine ) {
		[ AlertExtension modalAlert:@"Adding insulation sheath to wire?" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe IS (insulation sheath) card only works with NEC-4.\n\nThe card will not be generated." ] ;
		return ;
	}
	
	load = [ NCLoad insulateWithPermittivity:permittivity conductivity:conductive radius:radius ] ;
	[ element addLoad:load ] ;
}

//	v0.73
- (NCValue*)insulate:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element ;
	double permittivity, conductive, radius ;
	int engine ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element = (NCWire*)[ param elementValue ] ;
		if ( element == nil ) {
			[ AlertExtension modalAlert:@"Argument error in insulate function." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument of the insulate function should be a wire element." ] ;
		}
		else {
			permittivity = doubleValue( args, 1 ) ;
			conductive = doubleValue( args, 2 ) ;
			radius = doubleValue( args, 3 ) ;
			//  v0.78
			engine = [ [ NSApp delegate ] engine ] ;
			if ( engine == kNEC41Engine || engine == kNEC42Engine ) {
				//  NEC-4.  Use IS card.
				[ self nec4Insulate:element insulationRadius:radius permittivity:permittivity conductivity:conductive ] ;
			}
			else {
				//	v0.75b NEC-2
				//	Use Yurkov's solution for NEC-2
				[ self yurkovInsulate:element insulationRadius:radius permittivity:permittivity velocityFactor:0.92 ] ;				
			}
			return [ NCValue valueWithInt:1 ] ;
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)lumpedSeriesLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoad:args prototype:prototype type:SERIESRLC ] ;
}

- (NCValue*)seriesLoadAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoadAtSegments:args prototype:prototype type:SERIESRLC ] ;
}

- (NCValue*)parallelLoadAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoadAtSegments:args prototype:prototype type:PARALLELRLC ] ;
}

- (NCValue*)lumpedParallelLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoad:args prototype:prototype type:PARALLELRLC ] ;
}

//  v0.92
- (NCValue*)lumpedRLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:0 ] ;
}

//  v0.92
- (NCValue*)lumpedLLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:1 ] ;
}

//  v0.92
- (NCValue*)lumpedCLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:2 ] ;
}

//  v0.92
- (NCValue*)lumpedRTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:0 ] ;
}

//  v0.92
- (NCValue*)lumpedLTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:1 ] ;
}

//  v0.92
- (NCValue*)lumpedCTermination:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self simpleLoad:args prototype:prototype type:2 ] ;
}


- (NCValue*)distributedSeriesLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoad:args prototype:prototype type:DISTRIBUTEDSERIESRLC ] ;
}

- (NCValue*)distributedParallelLoad:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self rlcLoad:args prototype:prototype type:DISTRIBUTEDPARALLELRLC ] ;
}

- (NCValue*)network:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork networkFrom:element1 segment:0 to:element2 segment:0
									  y11r:doubleValue( args, 2 )
									  y11i:doubleValue( args, 3 )
									  y12r:doubleValue( args, 4 )
									  y12i:doubleValue( args, 5 )
									  y22r:doubleValue( args, 6 )
									  y22i:doubleValue( args, 7 )
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)networkAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:2 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork networkFrom:element1 segment:intValue( args, 1 ) to:element2 segment:intValue( args, 3 )
									  y11r:doubleValue( args, 4 )
									  y11i:doubleValue( args, 5 )
									  y12r:doubleValue( args, 6 )
									  y12i:doubleValue( args, 7 )
									  y22r:doubleValue( args, 8 )
									  y22i:doubleValue( args, 9 )
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.77
- (NCNetwork*)newTransmissionline:(NCWire*)element1 to:(NCWire*)element2 impedance:(double)impedance
{
	return [ NCNetwork transmissionLineFrom:element1 to:element2 z0:impedance
			crossed:NO
			length:0
			y1r:0.0 y1i:0.0 y2r:0.0 y2i:0.0
	] ;
}

- (NCValue*)transmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ self newTransmissionline:element1 to:element2 impedance:doubleValue( args, 2 ) ] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)transmissionLineAtSegments:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;
	
	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:2 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 segment:intValue( args, 1 ) to:element2 segment:intValue( args, 3 )
					z0:doubleValue( args, 4 )
					length:doubleValue( args, 5 )		//  v0.85
					y1r:0.0
					y1i:0.0
					y2r:0.0
					y2i:0.0
					] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)crossedTransmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 to:element2
									  z0:doubleValue( args, 2 )
									  crossed:YES
									  length:0
									  y1r:0.0
									  y1i:0.0
									  y2r:0.0
									  y2i:0.0
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)longTransmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 to:element2
									  z0:doubleValue( args, 2 )
									  crossed:NO
									  length:doubleValue( args, 3 )
									  y1r:0.0
									  y1i:0.0
									  y2r:0.0
									  y2i:0.0
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)crossedLongTransmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 to:element2
									  z0:doubleValue( args, 2 )
									  crossed:YES
									  length:doubleValue( args, 3 )
									  y1r:0.0
									  y1i:0.0
									  y2r:0.0
									  y2i:0.0
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)terminatedTransmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 to:element2
									  z0:doubleValue( args, 2 )
									  crossed:NO
									  length:doubleValue( args, 3 )
									  y1r:doubleValue( args, 4 )
									  y1i:doubleValue( args, 5 )
									  y2r:doubleValue( args, 6 )
									  y2i:doubleValue( args, 7 )
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

- (NCValue*)crossedTerminatedTransmissionLine:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *param ;
	NCWire *element1, *element2 ;
	NCNetwork *network ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			if ( element1 != nil && element2 != nil ) {
				network = [ NCNetwork transmissionLineFrom:element1 to:element2
									  z0:doubleValue( args, 2 )
									  crossed:YES
									  length:doubleValue( args, 3 )
									  y1r:doubleValue( args, 4 )
									  y1i:doubleValue( args, 5 )
									  y2r:doubleValue( args, 6 )
									  y2i:doubleValue( args, 7 )
							] ;
				[ element1 addNetwork:network ] ;
				return [ NCValue valueWithInt:1 ] ;
			}
		}
	}
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.81b
//  added exposeConductor: for including twinlead
- (NCValue*)coax:(NSArray*)args prototype:(NSArray*)prototype y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i crossed:(Boolean)crossed exposeShield:(Boolean)hasShield exposeConductor:(Boolean)exposeConductor
{
	NCWire *element1, *element2 ;
	NCCoax *coax ;
	NCCoaxCable *cable ;
	NCValue *param ;
	CoaxCableParams p ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:1 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			param = [ args objectAtIndex:2 ] ;
			if ( param ) {
				coax = (NCCoax*)[ param coaxValue ] ;
				if ( coax != nil ) {
					//  check is hasShield is used for twinlead
					if ( hasShield && [ coax isCoax ] == NO ) {
						[ stack->errors addObject:@"shield being used for twinlead?\n\nExecution terminated." ] ;
						return [ NCValue valueWithInt:0 ] ;
					}
					p.end1 = p.end2 = 0 ;
                    if ( hasShield ) {
                        p.end1 += CoaxShieldFlag ;
                        p.end2 += CoaxShieldFlag ;
                    }
                    else if ( exposeConductor ) {
                        p.end1 += ExposeCoaxConductor ;
                        p.end2 += ExposeCoaxConductor ;
                    }
                    
					if ( crossed ) p.end2 += CoaxCrossedFlag ;
					p.y1r = y1r ;
					p.y1i = y1i ;
					p.y2r = y2r ;
					p.y2i = y2i ;
					cable = [ [ NCCoaxCable alloc ] initFrom:element1 to:element2 coax:coax params:&p stack:stack ] ;
					if ( cable != nil ) {
						[ stack->coaxLines addObject:coax ] ;
						return [ NCValue valueWithInt:1 ] ;
					}
				}
			}
		}
	}
	[ stack->errors addObject:@"Bad parameter passed into coax function.\n\nExecution terminated." ] ;
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.81b
- (NCValue*)endFedCoax:(NSArray*)args prototype:(NSArray*)prototype y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i
{
	NCWire *element1, *element2 ;
	NCCoax *coax ;
	NCCoaxCable *cable ;
	NCValue *param ;
	CoaxCableParams p ;
	int location1, location2 ;

	param = [ args objectAtIndex:0 ] ;
	if ( param ) {
		element1 = (NCWire*)[ param elementValue ] ;
		param = [ args objectAtIndex:2 ] ;
		if ( param ) {
			element2 = (NCWire*)[ param elementValue ] ;
			param = [ args objectAtIndex:4 ] ;
			if ( param ) {
				coax = (NCCoax*)[ param coaxValue ] ;
				if ( coax != nil ) {
					p.end1 = CoaxUserFlags( intValue( args, 1 ) ) ;
					p.end2 = CoaxUserFlags( intValue( args, 3 ) ) ;
					location1 = CoaxLocationDigit( p.end1 ) ;
					location2 = CoaxLocationDigit( p.end2 ) ;
					//  check shield is used for twinlead, if so, remove it
					if ( [ coax isCoax ] == NO ) {
						if ( CoaxShieldDigit( p.end1 ) == 0 ) p.end1 += CoaxShieldFlag ;
						if ( CoaxShieldDigit( p.end2 ) == 0 ) p.end2 += CoaxShieldFlag ;
					}
					if ( location1 != 0 && location1 == location2 ) p.end2 += CoaxCrossedFlag ;
					//  always connect shield to wire ends
					p.end1 += CoaxEndType ;
					p.end2 += CoaxEndType ;

					p.y1r = y1r ;
					p.y1i = y1i ;
					p.y2r = y2r ;
					p.y2i = y2i ;
					cable = [ [ NCCoaxCable alloc ] initFrom:element1 to:element2 coax:coax params:&p stack:stack ] ;
					if ( cable != nil ) {
						[ stack->coaxLines addObject:coax ] ;
						return [ NCValue valueWithInt:1 ] ;
					}
				}
			}
		}
	}
	[ stack->errors addObject:@"Bad parameter passed into endFedCoax function.\n\nExecution terminated." ] ;
	return [ NCValue valueWithInt:0 ] ;
}

//	v0.81
- (NCValue*)coaxModel:(NSArray*)args prototype:(NSArray*)prototype
{
	NCCoax *coax ;
	int i ;
	double Ro, velocityFactor, k0, k1, k2, radius, jacketRadius, jacketPermittivity ;
	
	i = 0 ;
	Ro = doubleValue( args, i++ ) ;
	velocityFactor = doubleValue( args, i++ ) ;
	k0 = doubleValue( args, i++ ) ;
	k1 = doubleValue( args, i++ ) ;
	k2 = doubleValue( args, i++ ) ;
	radius = doubleValue( args, i++ )*0.5 ;
	jacketRadius = doubleValue( args, i++ )*0.5 ;
	jacketPermittivity = doubleValue( args, i++ )*0.5 ;
	coax = [ [ NCCoax alloc ] initWithRo:Ro shieldRadius:radius velocityFactor:velocityFactor jacketRadius:jacketRadius jacketPermittivity:jacketPermittivity k0:k0 k1:k1 k2:k2  ] ;

	return [ NCValue valueWithCoax:coax ] ;
}

//	v0.78, v0.81
- (NCValue*)coax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 crossed:NO exposeShield:NO exposeConductor:NO ] ;
}

//	v0.78, v0.81
- (NCValue*)crossedCoax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 crossed:YES exposeShield:NO  exposeConductor:NO ] ;
}

//	v0.78, v0.81
- (NCValue*)terminatedCoax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:doubleValue( args, 3 ) y1i:doubleValue( args, 4 ) y2r:doubleValue( args, 5 ) y2i:doubleValue( args, 6 ) crossed:NO exposeShield:NO  exposeConductor:NO ] ;
}

//	v0.78, v0.81
- (NCValue*)crossedTerminatedCoax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:doubleValue( args, 3 ) y1i:doubleValue( args, 4 ) y2r:doubleValue( args, 5 ) y2i:doubleValue( args, 6 ) crossed:YES exposeShield:NO exposeConductor:NO ] ;
}

//	v0.81
- (NCValue*)coaxWithShield:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 crossed:NO exposeShield:YES exposeConductor:NO ] ;
}

//	v0.81
- (NCValue*)crossedCoaxWithShield:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 crossed:YES exposeShield:YES exposeConductor:NO ] ;
}

//	v0.81
- (NCValue*)terminatedCoaxWithShield:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:doubleValue( args, 3 ) y1i:doubleValue( args, 4 ) y2r:doubleValue( args, 5 ) y2i:doubleValue( args, 6 ) crossed:NO exposeShield:YES exposeConductor:NO ] ;
}

//	v0.81
- (NCValue*)crossedTerminatedCoaxWithShield:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:doubleValue( args, 3 ) y1i:doubleValue( args, 4 ) y2r:doubleValue( args, 5 ) y2i:doubleValue( args, 6 ) crossed:YES exposeShield:YES exposeConductor:NO ] ;
}

//	v0.81
- (NCValue*)endFedCoax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self endFedCoax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 ] ;
}

//	v0.81
- (NCValue*)endFedTerminatedCoax:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self endFedCoax:args prototype:prototype y1r:doubleValue( args, 5 ) y1i:doubleValue( args, 6 ) y2r:doubleValue( args, 7 ) y2i:doubleValue( args, 8 ) ] ;
}

//	v0.81
- (NCValue*)twinleadModel:(NSArray*)args prototype:(NSArray*)prototype
{
	NCCoax *coax ;
	int i ;
	double Ro, velocityFactor, k0, k1, k2, separation, jacketRadius, jacketPermittivity ;
	
	i = 0 ;
	Ro = doubleValue( args, i++ ) ;
	velocityFactor = doubleValue( args, i++ ) ;
	k0 = doubleValue( args, i++ ) ;
	k1 = doubleValue( args, i++ ) ;
	k2 = doubleValue( args, i++ ) ;
	separation = doubleValue( args, i++ ) ; ;
	jacketRadius = doubleValue( args, i++ )*0.5 ;
	jacketPermittivity = doubleValue( args, i++ )*0.5 ;
	coax = [ [ NCCoax alloc ] initWithRo:Ro separation:separation velocityFactor:velocityFactor jacketRadius:jacketRadius jacketPermittivity:jacketPermittivity k0:k0 k1:k1 k2:k2 ] ;

	return [ NCValue valueWithCoax:coax ] ;
}

//	v0.92
- (NCValue*)twinlead:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:0 y1i:0 y2r:0 y2i:0 crossed:NO exposeShield:NO exposeConductor:YES ] ;
}

//	v0.92
- (NCValue*)terminatedTwinlead:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self coax:args prototype:prototype y1r:doubleValue( args, 3 ) y1i:doubleValue( args, 4 ) y2r:doubleValue( args, 5 ) y2i:doubleValue( args, 6 ) crossed:NO exposeShield:NO exposeConductor:YES ] ;
}


//  v0.46 -- prevent control() from accumulating radials and plots
- (void)clearRadialsAndPlots
{
	tag = 0 ;									//  tags were changing in multiple runModel()
	[ azimuthPlots removeAllObjects ] ;
	[ elevationPlots removeAllObjects ] ;
	[ radials removeAllObjects ] ;
}

- (NCValue*)radials:(NSArray*)args prototype:(NSArray*)prototype
{
	int elements = intValue( args, 5 ) ;
	double x = doubleValue( args, 0 ) ;
	double y = doubleValue( args, 1 ) ;
	double z = doubleValue( args, 2 ) ;
	double length = doubleValue( args, 3 ) ;
	double radius = doubleValue( args, 4 ) ;
	
	[ radials addObject:[ NCRadials radialsWithElements:elements x:x y:y z:z length:length radius:radius ] ] ;
	return [ NCValue valueWithInt:elements ] ;
}

- (NCValue*)setFrequency:(NSArray*)args prototype:(NSArray*)prototype
{
	double frequency ;
	
	frequency = doubleValue( args, 0 ) ;
	if ( frequency < 0.01 ) frequency = 0.01 ;
	
	[ frequencyArray removeAllObjects ] ;
	[ frequencyArray addObject:[ NSNumber numberWithDouble:frequency ] ] ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)addFrequency:(NSArray*)args prototype:(NSArray*)prototype
{
	double frequency ;
	
	frequency = doubleValue( args, 0 ) ;
	if ( frequency < 0.01 ) frequency = 0.01 ;
	[ frequencyArray addObject:[ NSNumber numberWithDouble:frequency ] ] ;
	return [ NCValue valueWithInt:1 ] ;
}

//  v0.70
- (NCValue*)frequencySweep:(NSArray*)args prototype:(NSArray*)prototype
{
	double frequency, freqEnd, delta ;
	int i, n ;
	
	frequency = doubleValue( args, 0 ) ;
	if ( frequency < 0.01 ) frequency = 0.01 ;

	freqEnd = doubleValue( args, 1 ) ;
	n = intValue( args, 2 ) ;
	
	if ( n <= 0 ) return [ NCValue valueWithInt:1 ] ;

	if ( freqEnd < ( frequency+0.001 ) || n == 1 ) {
		[ frequencyArray addObject:[ NSNumber numberWithDouble:frequency ] ] ;		//  too narrow or n=1, generate only one frequency
		return [ NCValue valueWithInt:1 ] ;
	}
	delta = ( freqEnd - frequency )/ ( n-1 ) ;
	for ( i = 0; i < n; i++ ) {
		[ frequencyArray addObject:[ NSNumber numberWithDouble:frequency ] ] ;
		frequency += delta ;
	}
	return [ NCValue valueWithInt:1 ] ;
}


- (NCValue*)azimuthPlotForElevationAngle:(NSArray*)args prototype:(NSArray*)prototype
{
	[ azimuthPlots addObject:[ args objectAtIndex:0 ] ] ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)setAzimuthPlotDistance:(NSArray*)args prototype:(NSArray*)prototype
{
	double distance ;
	
	distance = doubleValue( args, 0 ) ;
	if ( distance < 0.01 ) distance = 0.01 ;
	azimuthPlotDistance = distance ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)elevationPlotForAzimuthAngle:(NSArray*)args prototype:(NSArray*)prototype
{
	[ elevationPlots addObject:[ args objectAtIndex:0 ] ] ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)setElevationPlotDistance:(NSArray*)args prototype:(NSArray*)prototype
{
	double distance ;
	
	distance = doubleValue( args, 0 ) ;
	if ( distance < 0.01 ) distance = 0.01 ;
	elevationPlotDistance = distance ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NCValue*)runModel:(NSArray*)args prototype:(NSArray*)prototype
{
	Boolean success ;
	NC *nc = [ [ NSApp delegate ] currentNC ] ;
	
	if ( runLoops <= 0 ) return [ NCValue valueWithInt:0 ] ;
	
	success = [ nc runModel ] ;
	if ( !success ) runLoops = 0 ;
	
	runLoops-- ;
	if ( runLoops < 0 ) runLoops = 0 ;
	
	return [ NCValue valueWithInt:( success)? 1 : 0 ] ;
}

- (NCValue*)useQuadPrecision:(NSArray*)args prototype:(NSArray*)prototype
{
	useQuadPrecision = ( intValue( args, 0 ) != 0 ) ;
	return [ NCValue valueWithInt:1 ] ;
}

//	v0.81d
- (NCValue*)keepDataBetweenModelRuns:(NSArray*)args prototype:(NSArray*)prototype
{
	keepDataBetweenModelRuns = ( intValue( args, 0 ) != 0 ) ;
	return [ NCValue valueWithInt:1 ] ;
}

- (FeedpointInfo*)currentFeedpointInfo:(int)index
{
	NC *nc = [ [ NSApp delegate ] currentNC ] ;
	NECInfo *necResults = [ nc necResults ] ;
	NSArray *feedpoints = necResults->feedpointArray ;
	intType count = [ feedpoints count ] ;
	
	if ( index < 0 || index >= count ) return nil ;
	
	feedpointInfo = *[ (Feedpoint*)[ feedpoints objectAtIndex:index ] info ] ;	
	return &feedpointInfo ;
}

- (NCValue*)vswr:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	double vswr, r ;
	complex double num, denom, rho ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:99.0 ] ;
	
	num = denom = ( info->zr + info->zi*(0.0+1.0fj) ) ;
	num -= 50.0, denom += 50.0 ;
	rho = num/denom ;
	r = cabs( rho ) ;
	vswr = ( r > 0.99 ) ? 99.0 : ( 1+r )/( 1-r ) ;
	
	return [ NCValue valueWithDouble:vswr ] ;
}

- (NCValue*)feedpointImpedanceReal:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->zr ] ;
}

- (NCValue*)feedpointImpedanceImaginary:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->zi ] ;
}

- (NCValue*)feedpointVoltageReal:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->vr ] ;
}

- (NCValue*)feedpointVoltageImaginary:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->vi ] ;
}

- (NCValue*)feedpointCurrentReal:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->cr ] ;
}

- (NCValue*)feedpointCurrentImaginary:(NSArray*)args prototype:(NSArray*)prototype
{
	FeedpointInfo *info ;
	int index ;
	
	index = intValue( args, 0 ) - 1 ;
	info = [ self currentFeedpointInfo:index ] ;
		
	if ( info == nil ) return [ NCValue valueWithDouble:0.0 ] ;
	return [ NCValue valueWithDouble:info->ci ] ;
}

- (NCValue*)pause:(NSArray*)args prototype:(NSArray*)prototype
{
	double time ;
	
	time = doubleValue( args, 0 ) ;
	[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:time ] ] ;
	return [ NCValue valueWithInt:1 ] ;
}

- (NSArray*)frequencyArray
{
	return frequencyArray ;
}

- (char*)modelName
{
	return modelName ;
}

- (void)setModelName:(char*)name
{
	if ( name == nil ) name = "cocoaNEC 2.0" ;
	strcpy( modelName, name ) ;
}

- (NSArray*)azimuthPlots 
{
	return azimuthPlots ;
}

- (NSArray*)elevationPlots 
{
	return elevationPlots ;
}

- (NSArray*)radials
{
	return radials ;
}

- (double)conductivity
{
	return conductivity ;
}

- (double)dielectric
{
	return dielectric ;
}

- (Boolean)isFreeSpace
{
	return isFreeSpace ;
}

- (Boolean)isPerfectGround
{
	return isPerfectGround ;
}

- (Boolean)isSommerfeld
{
	return isSommerfeld ;
}

- (Boolean)useExtendedKernel
{
	return isUseExtendedKernel ;
}

//  convert escape characters in a format string
- (NSString*)formatString:(char*)input 
{
	char *output, *start ;
	
	start = output = input ;
	while ( *input ) {
		if ( *input != '\\' ) {
			*output++ = *input++ ;
		}
		else {
			input++ ;
			switch ( *input ) {
			case 'n':
				*output++ = '\n' ;
				input++ ;
				break ;
			case 't':
				*output++ = '\t' ;
				input++ ;
				break ;
			default:
				*output = '\\' ;
				break ;
			}
		}
	}
	*output = 0 ;
	return [ NSString stringWithUTF8String:start ] ;
}

static char *makeSimpleFormat( char *outs, char *ins )
{
	int i, j, c ;
	
	*outs = 0 ;

	//  sanity check -- limit format string to 256 characters
	for ( i = 0; i < 512; i++ ) {
		*outs++ = *ins ;
		if ( *ins && *ins != '%' ) ins++ ; 
		else {
			//  saw a percent
			ins++ ;
			if ( *ins == '%' ) {
				//  saw %%
				*outs++ = *ins++ ;
			}
			else {
				//  keep copying until a %d or %f
				for ( j = 0; j < 16; j++ ) {
					*outs++ = c = *ins ;
					if ( c != 0 ) ins++ ;		// v0.67 bug fix (was inside the next if statment)
					if ( c == 0 || c == 'd' || c == 'f' || c == 'e' || c == 'E' || c == 'g' || c == 'G' ) {
						*outs = 0 ;
						return ins ;
					} 
				}
			}
		}
	}
	return ins ;
}

//	v0.66	replaced vsprintf (no longer works with 10.6) with our own format parser
//  each argument is an NCValue
- (NCValue*)print:(NSArray*)args prototype:(NSArray*)prototype
{
	//return [ NCValue valueWithInt:1 ] ;

	NCValue *arg ;
	NSString *format, *resultString ;
	intType i, type, count, intval ;
	double floatval ;
	char fmt[1024], currentfmt[1024], *remainingfmt, output[1024] ;
	NC *nc = [ [ NSApp delegate ] currentNC ] ;
	
	count = [ args count ] ;
	if ( count == 0 ) return [ NCValue valueWithInt:0 ] ;
	
	arg = [ args objectAtIndex:0 ] ;
	type = [ arg type ] ;
	//  first location needs to be a format string
	if ( type != STRINGTYPE ) {
		printf( "bad 'print' function call -- the first argument needs to be a format string\n" ) ;
		return [ NCValue valueWithInt:0 ] ;
	}
	format = [ self formatString:[ arg stringValue ] ] ;
	strcpy( fmt, [ format cStringUsingEncoding:NSASCIIStringEncoding ] ) ;
	
	if ( count == 1 ) {
		resultString = format ;
	}
	else {
		resultString = @"" ;
		remainingfmt = fmt ;
	
		//  pack values into array
		if ( count > 10 ) count = 10 ;
		currentfmt[0] = 0 ;

		for ( i = 1; i < count; i++ ) {
		
			//  gather the next format string that contains a single argument of type f or type d
			remainingfmt = makeSimpleFormat( currentfmt, remainingfmt ) ;
			if ( currentfmt[0] == 0 ) break ;
			arg = [ args objectAtIndex:i ] ;
			type = [ arg type ] ;
		
			switch ( type ) {
			case INTTYPE:
				intval = [ arg intValue ] ;
				sprintf( output, currentfmt, intval ) ;
				resultString = [ resultString stringByAppendingString:[ NSString stringWithCString:output encoding:NSASCIIStringEncoding ] ] ;
				currentfmt[0] = 0 ;
				break ;
			case REALTYPE:
				floatval = [ arg doubleValue ] ;
				sprintf( output, currentfmt, floatval ) ;
				resultString = [ resultString stringByAppendingString:[ NSString stringWithCString:output encoding:NSASCIIStringEncoding ] ] ;
				currentfmt[0] = 0 ;
				break ;
			default:
				return [ NCValue valueWithInt:0 ] ;
			}
		}
		if ( *currentfmt != 0 ) {
			sprintf( output, currentfmt, 0 ) ;
			resultString = [ resultString stringByAppendingString:[ NSString stringWithCString:output encoding:NSASCIIStringEncoding ] ] ;
		}
		if ( *remainingfmt != 0 ) {
			sprintf( output, remainingfmt, 0 ) ;
			resultString = [ resultString stringByAppendingString:[ NSString stringWithCString:output encoding:NSASCIIStringEncoding ] ] ; 
		}
	}
	[ nc appendToOutputView:resultString ] ;
	return [ NCValue valueWithInt:1 ] ;
}

#ifdef VSPRINTF_VERSION
//  each argument is an NCValue
- (NCValue*)print:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *arg ;
	NC *nc = [ [ NSApp delegate ] currentNC ] ;
	NSString *format, *resultString ;
	int i, type, count ;
	char fmt[1024] ;
	char local[2048] ;		//  v0.66 changed from 256 to 2048
	union {
		va_list varargs ;
		void *packed ;
	} ulist ;
	
	count = [ args count ] ;
	if ( count == 0 ) return [ NCValue valueWithInt:0 ] ;
	
	arg = [ args objectAtIndex:0 ] ;
	type = [ arg type ] ;
	//  first location needs to be a format string
	if ( type != STRINGTYPE ) {
		printf( "bad 'print' function call -- the first argument needs to be a format string\n" ) ;
		return [ NCValue valueWithInt:0 ] ;
	}
	format = [ self formatString:[ arg stringValue ] ] ;
	
	if ( count == 1 ) {
		resultString = format ;
	}
	else {
		void *ptr = ulist.packed = alloca(192) ;
		
		strcpy( fmt, [ format cStringUsingEncoding:NSASCIIStringEncoding ] ) ;	//  v0.66 use ASCII instead of UTF8, just in case

		//  pack values into array
		if ( count > 10 ) count = 10 ;
		for ( i = 1; i < count; i++ ) {
		
			arg = [ args objectAtIndex:i ] ;
			type = [ arg type ] ;
		
			switch ( type ) {
			case INTTYPE:
				*(int*)ptr = [ arg intValue ]  ;
				ptr += sizeof( int ) ;
				break ;
			case REALTYPE:
				*(double*)ptr = [ arg doubleValue ] ;
				ptr += sizeof( double ) ;
				break ;
			default:
				return [ NCValue valueWithInt:0 ] ;
			}
		}
		vsprintf( local, fmt, ulist.varargs ) ;
		resultString = [ NSString stringWithUTF8String:local ] ;
	}
	[ nc appendToOutputView:resultString ] ;
	return [ NCValue valueWithInt:1 ] ;
}
#endif

//	(Private API)
- (NCCard*)gwCommon:(char*)type args:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGWCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:type ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	[ card setF1:doubleValue( args, 2 ) ] ;
	[ card setF2:doubleValue( args, 3 ) ] ;
	[ card setF3:doubleValue( args, 4 ) ] ;
	[ card setF4:doubleValue( args, 5 ) ] ;
	[ card setF5:doubleValue( args, 6 ) ] ;
	[ card setF6:doubleValue( args, 7 ) ] ;
	[ card setF7:doubleValue( args, 8 ) ] ;
	return card ;
}

//	(Private API)
- (NCCard*)gw:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self gwCommon:"GW" args:args prototype:prototype ] ;
}

//	(Private API)
- (NCCard*)ga:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGACard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"GA" ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	[ card setF1:doubleValue( args, 2 ) ] ;
	[ card setF2:doubleValue( args, 3 ) ] ;
	[ card setF3:doubleValue( args, 4 ) ] ;
	[ card setF4:doubleValue( args, 5 ) ] ;
	
	return card ;
}

//	(Private API)
- (NCCard*)gc:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGCCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"GC" ] ;
	[ card setF1:doubleValue( args, 0 ) ] ;
	[ card setF2:doubleValue( args, 1 ) ] ;
	[ card setF3:doubleValue( args, 2 ) ] ;
	
	return card ;
}

//	(Private API)
- (NCCard*)gh:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self gwCommon:"GH" args:args prototype:prototype ] ;
}

//	(Private API)
- (NCCard*)gm:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self gwCommon:"GM" args:args prototype:prototype ] ;
}

//	(Private API)
- (NCCard*)gr:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGRCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"GR" ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	
	return card ;
}

//	(Private API)
- (NCCard*)gs:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGSCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"GS" ] ;
	[ card setF1:doubleValue( args, 0 ) ] ;
	
	return card ;
}

//	(Private API)
- (NCCard*)gx:(NSArray*)args prototype:(NSArray*)prototype
{
	NCGWCard *card ;
	
	card = [ [ NCGRCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"GX" ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	
	return card ;
}

- (NCCard*)spCommon:(char*)type args:(NSArray*)args prototype:(NSArray*)prototype
{
	NCSPCard *card ;
	
	card = [ [ NCSPCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:type ] ;
	[ card setI2:intValue( args, 0 ) ] ;
	[ card setF1:doubleValue( args, 1 ) ] ;
	[ card setF2:doubleValue( args, 2 ) ] ;
	[ card setF3:doubleValue( args, 3 ) ] ;
	[ card setF4:doubleValue( args, 4 ) ] ;
	[ card setF5:doubleValue( args, 5 ) ] ;
	[ card setF6:doubleValue( args, 6 ) ] ;
	return card ;
}

//	(Private API)
- (NCCard*)sp:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self spCommon:"SP" args:args prototype:prototype ] ;
}

//	(Private API)
- (NCCard*)sc:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self spCommon:"SC" args:args prototype:prototype ] ;
}

- (NCCard*)sm:(NSArray*)args prototype:(NSArray*)prototype
{
	NCSPCard *card ;
	
	card = [ [ NCSPCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:"SM" ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	[ card setF1:doubleValue( args, 2 ) ] ;
	[ card setF2:doubleValue( args, 3 ) ] ;
	[ card setF3:doubleValue( args, 4 ) ] ;
	[ card setF4:doubleValue( args, 5 ) ] ;
	[ card setF5:doubleValue( args, 6 ) ] ;
	[ card setF6:doubleValue( args, 7 ) ] ;
	return card ;
}

//	(Private API)
- (NCCard*)exCommon:(char*)type args:(NSArray*)args prototype:(NSArray*)prototype generate:(int)generate
{
	NCEXCard *card ;
	
	card = [ [ NCEXCard alloc ] initWithRuntime:stack ] ;
	
	[ card setCardType:type ] ;
	[ card setGenerate:generate ] ;
	[ card setI1:intValue( args, 0 ) ] ;
	[ card setI2:intValue( args, 1 ) ] ;
	[ card setI3:intValue( args, 2 ) ] ;
	[ card setI4:intValue( args, 3 ) ] ;
	[ card setF1:doubleValue( args, 4 ) ] ;
	[ card setF2:doubleValue( args, 5 ) ] ;
	[ card setF3:doubleValue( args, 6 ) ] ;
	if ( !LOADCARD ) {
		[ card setF4:doubleValue( args, 7 ) ] ;
		[ card setF5:doubleValue( args, 8 ) ] ;
		[ card setF6:doubleValue( args, 9 ) ] ;
	}
	return card ;
}

//	(Private API)
- (NCCard*)ex:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self exCommon:"EX" args:args prototype:prototype generate:EXCITATIONCARD ] ;
}

//	(Private API)
- (NCCard*)ld:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self exCommon:"LD" args:args prototype:prototype generate:LOADCARD ] ;
}

//	(Private API)
- (NCCard*)nt:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self exCommon:"NT" args:args prototype:prototype generate:NETWORKCARD ] ;
}

//	(Private API)
- (NCCard*)tl:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ self exCommon:"TL" args:args prototype:prototype generate:NETWORKCARD ] ;
}

//	(Private API)
- (NCValue*)vect:(NSArray*)args prototype:(NSArray*)prototype
{
	float x, y, z ;
	
	x = doubleValue( args, 0 ) ;
	y = doubleValue( args, 1 ) ;
	z = doubleValue( args, 2 ) ;
	
	return [ NCValue vectorWithX:x y:y z:z ] ;
}

//  v0.53
//  create a wire function for vectors and return the NEC-2 tag (vectors)
- (NCElement*)wirev:(NSArray*)args prototype:(NSArray*)prototype
{
	NCWire *element ;
	NCVector *vector ;
	NCValue *value ;
	NCTransform *transform ;
	
	element = [ [ NCWire alloc ] initWithRuntime:stack ] ;
	
	value = [ args objectAtIndex:0 ] ;
	if ( [ value type ] != TRANSFORMTYPE ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument should be a transform variable.  No transform is executed.\n" ] ;
		transform = nil ;
	}
	else {
		transform = [ value transformValue ] ;
	}	
	vector = [ [ args objectAtIndex:1 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd1FromVector:vector ] ;
	vector = [ [ args objectAtIndex:2 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd2FromVector:vector ] ;
	[ element setRadius:doubleValue( args, 3 ) ] ;
	[ element setSegments:intValue( args, 4 ) ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

- (NCElement*)linev:(NSArray*)args prototype:(NSArray*)prototype
{
	NCWire *element ;
	NCVector *vector ;
	NCValue *value ;
	NCTransform *transform ;
	
	element = [ [ NCLine alloc ] initWithRuntime:stack ] ;
	
	value = [ args objectAtIndex:0 ] ;
	if ( [ value type ] != TRANSFORMTYPE ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument should be a transform variable.  No transform is executed.\n" ] ;
		transform = nil ;
	}
	else {
		transform = [ value transformValue ] ;
	}	
	vector = [ [ args objectAtIndex:1 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd1FromVector:vector ] ;
	vector = [ [ args objectAtIndex:2 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd2FromVector:vector ] ;
	[ element setRadius:doubleValue( args, 3 ) ] ;
	[ element setSegments:intValue( args, 4 ) ] ;
	[ element setTag:++tag ] ;
	
	return element ;
}

//  v0.53
//  create a tapered wire function for vectors and return the NEC-2 tag (vectors)
- (NCElement*)taperedWirev:(NSArray*)args prototype:(NSArray*)prototype
{
	NCTaperedWire *element ;
	NCVector *vector ;
	NCValue *value ;
	NCTransform *transform ;
	
	element = [ [ NCTaperedWire alloc ] initWithRuntime:stack ] ;
	value = [ args objectAtIndex:0 ] ;
	if ( [ value type ] != TRANSFORMTYPE ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument should be a transform variable.  No transform is executed.\n" ] ;
		transform = nil ;
	}
	else {
		transform = [ value transformValue ] ;
	}	
	vector = [ [ args objectAtIndex:1 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd1FromVector:vector ] ;
	vector = [ [ args objectAtIndex:2 ] vectorValue ] ;	
	if ( transform != nil ) vector = [ transform applyTransform:vector ] ;
	[ element setEnd2FromVector:vector ] ;
	[ element setRadius:doubleValue( args, 3 ) ] ;
	[ element setTaper1:doubleValue( args, 4 ) ] ;
	[ element setTaper2:doubleValue( args, 5 ) ] ;
	[ element setStartingTag:++tag ] ;
	tag += 2 ;
	
	return element ;
}

//  v0.53
- (NCValue*)identityTransform:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ NCValue valueWithTransform:[ NCTransform transformWithIdentity ] ] ;
}

//  v0.53
- (NCValue*)translateTransform:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ NCValue valueWithTransform:[ NCTransform transformWithTranslation:[ [ args objectAtIndex:0 ] vectorValue ] ] ] ;
}

//  v0.53
- (NCValue*)rotateX:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ NCValue valueWithTransform:[ NCTransform transformWithRotateX:doubleValue( args, 0 ) ] ] ;
}

//  v0.53
- (NCValue*)rotateY:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ NCValue valueWithTransform:[ NCTransform transformWithRotateY:doubleValue( args, 0 ) ] ] ;
}

//  v0.53
- (NCValue*)rotateZ:(NSArray*)args prototype:(NSArray*)prototype
{
	return [ NCValue valueWithTransform:[ NCTransform transformWithRotateZ:doubleValue( args, 0 ) ] ] ;
}

//  v0.53
- (NCValue*)matrixElement:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *value ;
	NCTransform *transform ;
	int i, j ;
	float v ;
	
	value = [ args objectAtIndex:0 ] ;
	if ( [ value type ] != TRANSFORMTYPE ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument should be a transform variable.  No transform is executed.\n" ] ;
		return [ NCValue valueWithDouble:0 ] ;
	}
	
	i = intValue( args, 1 ) ;
	j = intValue( args, 2 ) ;
	
	if ( i < 0 || i > 2 || j < 0 || j > 2 ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Index for matrix element must be 0, 1 or 2.\n" ] ;
		return [ NCValue valueWithDouble:0 ] ;
	}
	transform = [ value transformValue ] ;
	v = [ transform rotationMatrixElement:i j:j ] ;
	return [ NCValue valueWithDouble:v ] ;
}

//  v0.53
- (NCValue*)translationElement:(NSArray*)args prototype:(NSArray*)prototype
{
	NCValue *value ;
	NCTransform *transform ;
	int i ;
	float v ;
	
	value = [ args objectAtIndex:0 ] ;
	if ( [ value type ] != TRANSFORMTYPE ) {
		[ AlertExtension modalAlert:@"Bad argument in function call." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe first argument should be a transform variable.  No transform is executed.\n" ] ;
		return [ NCValue valueWithDouble:0 ] ;
	}
	
	i = intValue( args, 1 ) ;

	transform = [ value transformValue ] ;
	v = [ transform translationElement:i ] ;
	return [ NCValue valueWithDouble:v ] ;
}

//  v0.53
- (NCValue*)transformWithMatrix:(NSArray*)args prototype:(NSArray*)prototype
{
	int i ;
	float a[16] ;
	
	//  create augmented matrix
	for ( i = 0; i < 16; i++ ) a[i] = 0 ;
	for ( i = 0; i < 3; i++ ) {
		a[i] = doubleValue( args, i ) ;
		a[i+4] = doubleValue( args, i+3 ) ;
		a[i+8] = doubleValue( args, i+6 ) ;
	}
	a[15] = 1.0 ;
	return [ NCValue valueWithTransform:[ NCTransform transformWithMatrix:a ] ] ;
}

- (Boolean)useQuadPrecision
{
	return useQuadPrecision ;
}

- (void)setUseQuadPrecision:(Boolean)state
{
	useQuadPrecision = state ;
}

//	v0.81d
- (Boolean)keepDataBetweenModelRuns
{
	return keepDataBetweenModelRuns ;
}

//	v0.81d
- (void)setKeepDataBetweenModelRuns:(Boolean)state
{
	keepDataBetweenModelRuns = state ;
}

- (void)setRunLoops:(int)count
{
	runLoops = count ;
}

- (Boolean)abort
{
	return abort ;
}

- (void)clearAbort
{
	abort = NO ;
}

- (void)setAbort
{
	abort = YES ;
}

@end
