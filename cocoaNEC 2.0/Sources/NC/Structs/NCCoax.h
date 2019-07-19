//
//  NCCoax.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/11/12.
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

#import <Cocoa/Cocoa.h>
#import "NCStructs.h"

@interface NCCoax : NSObject {
	char *name ;

	Boolean isCoax ;            //  false for twinlead
	double shieldRadius ;		//  coax
	double overallRadius ;
	double jacketPermittivity ;
	double separation ;			//  twinlead
    double wireDiameter ;       //  coax center conductor and twinlead wire size (diam in meters)
	
	//	electrical properties of transmission line
	double Ro ;
	double velocityFactor ;
	double k0 ;					//  DC resistance of conductors (constant)
	double k1 ;					//	high frequency (skin effect) resistance of conductors (varies as sqrt(f))
	double k2 ;					//	dielectric loss (varies as f).
	//  type constant (see table in NCCoax.h)
	int type ;	
	
	//	constants in nepers
	double c0 ;		//  k0
	double c1 ;		//  k1
	double c2 ;		//  k2
}

- (id)initWithType:(int)inType ;    //  0.88  missing declaration in h file

- (id)initWithRo:(double)inRo shieldRadius:(double)radius velocityFactor:(double)vf jacketRadius:(double)jacketRadius jacketPermittivity:(double)jacketPermittivity k0:(double)inK0 k1:(double)inK1 k2:(double)inK2 ;
- (id)initWithRo:(double)inRo separation:(double)sep velocityFactor:(double)vf jacketRadius:(double)jacketRadius jacketPermittivity:(double)jacketPermittivity k0:(double)inK0 k1:(double)inK1 k2:(double)inK2 ;

- (NCAdmittanceMatrix)admittanceMatrixForLength:(float)length frequency:(double)frequency ;
- (double)shieldRadius ;
- (double)jacketRadius ;
- (double)jacketPermittivity ;
- (double)separation ;
- (double)conductorRadius ;     //  v0.92
- (Boolean)isCoax ;

//	Coax type constants
#define	Belden( type )			( type )
#define	RG6Coax					Belden( 8215 )
#define	RG6HDTVCoax				Belden( 7915 )
#define	RG6CATVCoax				Belden( 9116 ) 
#define	RG8Coax					Belden( 8237 )
#define	RG8FoamCoax				Belden( 9914 )
#define	RG8xCoax				Belden( 9258 )
#define	RG11Coax				Belden( 9212 )
#define	RG11FoamCoax			Belden( 8213 )
#define	RG58Coax				Belden( 8240 )
#define	RG58FoamCoax			Belden( 8219 )
#define	RG59Coax				Belden( 9241 )
#define	RG59FoamCoax			Belden( 8212 )
#define	RG62Coax				Belden( 9269 )
#define	RG174Coax				Belden( 8216 )
#define	RG213Coax				Belden( 8267 )

#define	LMR( type )				( type )
#define	LMR100Coax				LMR( 100 )
#define	LMR200Coax				LMR( 200 )
#define	LMR240Coax				LMR( 240 )
#define	LMR300Coax				LMR( 300 )
#define	LMR400Coax				LMR( 400 )
#define	LMR600Coax				LMR( 600 )
#define	LMR900Coax				LMR( 900 )

#define	OtherCoax( type )		( 2000 + type )
#define	BURYFLEXCoax			OtherCoax( 1 )

#define Heliax( type )			( 3000 + type )
#define	LDF4Coax				Heliax( 4 )
#define	LDF5Coax				Heliax( 5 )
#define	LDF6Coax				Heliax( 6 )

#define	TwinLead( type )		( 4000+type )
#define	Window450Type			TwinLead( 450 )
#define	Ladder600Type			TwinLead( 600 )

#define	Wireman( type )			( 1000 + type )
#define	Wireman551				Wireman( 551 )
#define	Wireman552				Wireman( 552 )
#define	Wireman553				Wireman( 553 )
#define	Wireman554				Wireman( 554 )

#define	WiremanIce( type )		( 2000 + type )
#define	Wireman551Ice			WiremanIce( 551 )
#define	Wireman552Ice			WiremanIce( 552 )
#define	Wireman553Ice			WiremanIce( 553 )
#define	Wireman554Ice			WiremanIce( 554 )

#define JSC( type )             ( 10000 + type )
#define JSC1318                 JSC( 1318 )


@end
