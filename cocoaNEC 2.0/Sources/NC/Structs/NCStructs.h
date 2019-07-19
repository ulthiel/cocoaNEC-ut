/*
 *  NCStructs.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 5/23/12.
 */
 
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

 
 #define	CoaxShieldFlag				10              //  not for LadderLine
 #define	CoaxCrossedFlag				100				//  internal
 #define	CoaxEndType					1000			//	internal
 #define	CoaxUserFlags( p )			( ( p )%100 )	//  all external bits
 
 #define    ExposeCoaxConductor          10000           //  for LadderLine only
 
 #define	CoaxLocationDigit( p )		( ( p )%10 )
 #define	CoaxShieldDigit( p )		( ( ( p )/CoaxShieldFlag )%10 )
 #define	CoaxCrossedDigit( p )		( ( ( p )/CoaxCrossedFlag )%10 )
 #define	CoaxEndTypeFlag( p )		( ( ( p )/CoaxEndTypeFlag )%10 )
 #define    CoaxExposedWire(p)         ( ( ( p )/ExposeCoaxConductor )%10 )

typedef struct {
	//  location and flag on wires of the two ends of the coax; 10 = shield flag, 100 = crossed flag
	int end1 ;
	int end2 ;
	double length ;
	//	termination
	double y1r ;
	double y1i ;
	double y2r ;
	double y2i ;
} CoaxCableParams ;

typedef struct {
	double x ;
	double y ;
	double z ;
} WireCoord ;

typedef struct {
	WireCoord v ;
	WireCoord g ;
	WireCoord center ;
	double separation ;
} LineEndpoint ;

typedef struct {
	LineEndpoint start ;
	LineEndpoint end ;
	double length ;
	WireCoord d ;	//	center( end-start )
} ParallelLine ;

typedef struct {
	double y11r ;
	double y11i ;
	double y12r ;
	double y12i ;
	double y22r ;
	double y22i ;
} NCAdmittanceMatrix ;

typedef struct {
	double z0 ;
	double length ;
	double y1r, y1i, y2r, y2i ;
} NCTransmissionLine ;

