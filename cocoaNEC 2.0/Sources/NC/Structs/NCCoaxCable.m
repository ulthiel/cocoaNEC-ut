//
//  NCCoaxCable.m
//  cocoaNEC
//
//  Created by Kok Chen on 4/23/12.
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

#import "NCCoaxCable.h"
#import "ApplicationDelegate.h"
#import "NCLoad.h"
#import "NCSystem.h"
#import "NECEngines.h"

//	v0.78
//	Models practical transmission lines (NT card with wire representing shield.

@implementation NCCoaxCable

#define	metersPerFeet	0.0328084

//  v 0.92 -- added ExposeCoaxConductor for ladderline
//	coaxParam contains crossed, y1r, y1i, y2r and y2i.
//	this routine adds Ro, velocityFactor, k1, k2
- (id)initFrom:(NCWire*)element1 to:(NCWire*)element2 coax:(NCCoax*)inCoax params:(CoaxCableParams*)params stack:(RuntimeStack*)inStack
{
	WireCoord point1, point2, point1b, point2b, point1a, point2a, pointt, pointd, wire1a, wire1b, wire2a, wire2b, midpoint ;
	NCWire *shield ;
	NCGeometry *shieldGeometry, *wireAGeometry, *wireBGeometry ;
	NCNetwork *network ;
	int n, segment1, segment2, end1, end2, shield1, shield2, cross1, cross2, expose1, expose2 ;
	double gap, gap1, gap2, radius, shieldRadius, jacketRadius, scale ;

	self = [ super init ] ;
	if ( self ) {
		coax = inCoax ;
		stack = inStack ;
		params->length = [ [ NCWire vector:element1 to:element2 ] length ] ;
		
		//	least significant digit of params->endN: 0 (center), 1 (end1 of wire) or 2 (end2 of wire)
		//	10s digit: do not connect shield (if both ends of coax are disconnected, don't generate shield)
		//	100s digit, reverse connection (crossed)
		end1 = CoaxLocationDigit( params->end1 ) ;
		shield1 = CoaxShieldDigit( params->end1 ) ;
		cross1 = CoaxCrossedDigit( params->end1 ) ;
		expose1 = CoaxExposedWire( params->end1 )  ;
		end2 = CoaxLocationDigit( params->end2 ) ;
		shield2 = CoaxShieldDigit( params->end2 ) ;
		cross2 = CoaxCrossedDigit( params->end2 ) ;
		expose2 = CoaxExposedWire( params->end2 )  ;
        
        //  v0.92  expose twinlead wires
		
		segment1 = segment2 = 0 ;
		if (  shield1 != 0 || shield2 != 0 || expose1 != 0 || expose2 != 0 ) {
			//  has shield or exposed wire (at least one end of shield or twinlead is connected)
            
            if ( shield1 || shield2 ) {
                switch ( end1 ) {
                default:
                case 0:
                    segment1 = ( [ element1 segments ]+1 )/2 ;
                    n = ( cross1 == 0 ) ? 0 : 1 ;
                    point1 = [ element1 coordAtSegment:( segment1 - n ) ] ;
                    break ;
                case 1:
                    segment1 = 1 ;
                    point1 = [ element1 coordAtSegment:0 ] ;
                    break ;
                case 2:
                    segment1 = [ element1 segments ] ;
                    point1 = [ element1 coordAtSegment:segment1 ] ;
                    break ;
                }
                switch ( end2 ) {
                default:
                case 0:
                    segment2 = ( [ element2 segments ]+1 )/2 ;
                    n = ( cross2 == 0 ) ? 0 : 1 ;
                    point2 = [ element2 coordAtSegment:( segment2 - n ) ] ;
                    break ;
                case 1:
                    segment2 = 1 ;
                    point2 = [ element2 coordAtSegment:0 ] ;
                    break ;
                case 2:
                    segment2 = [ element2 segments ] ;
                    point2 = [ element2 coordAtSegment:segment2 ] ;
                    break ;
                }
            
                //  coax shield
                radius = [ coax shieldRadius ] ;
                gap = radius*2 ;
 
                shieldGeometry = [ NCGeometry geometryWithEnd1:&point1 end2:&point2 ] ;
                //	"physical" coax shield
                [ shieldGeometry shortenEndsBy:gap ] ;
			
                //  generate shield (with two short tapered segments for connection) ;
                if ( shield1 != 0 ) [ stack->system newWire:&point1 end2:[ shieldGeometry end1 ] radius:sqrt( radius*[ element1 radius ] ) segments:7 ] ;
                shieldRadius = [ coax shieldRadius ] ;
                shield = [ stack->system newWire:shieldGeometry radius:shieldRadius segments:33 ] ;
                jacketRadius = [ coax jacketRadius ] ;
                if ( jacketRadius > shieldRadius ) [ stack->system yurkovInsulate:shield insulationRadius:jacketRadius permittivity:[ coax jacketPermittivity ] velocityFactor:0.92 ] ;
                if ( shield2 != 0 ) [ stack->system newWire:[ shieldGeometry end2 ] end2:&point2 radius:sqrt( radius*[ element2 radius ] ) segments:7 ] ;
            }
            else {
                //  exposed twinlead wires

                //  connect between middle of wires
                //  note: segment number is 1, 2, 3, ..., segments
                segment1 = [ element1 feedSegment ] ;
                point1a = [ element1 coordAtSegment:( segment1 - 1 ) ] ;
                point1b = [ element1 coordAtSegment:( segment1 ) ] ;                
                if ( cross1 != 0 ) {
                    pointt = point1a ;
                    point1a = point1b ;
                    point1b = pointt ;
                }
                midpoint = [ NCGeometry midpointBetweenCoord:&point1a andCoord:&point1b ] ;                
                scale = [ NCGeometry distanceBetweenCoord:&point1a andCoord:&point1b ] ;
                pointd = [ NCGeometry subtractCoord:&point1a fromCoord:&point1b ] ;
                pointd = [ NCGeometry scaleCoord:&pointd factor:[ coax separation ]*0.5/scale ] ;
                wire1a = [ NCGeometry subtractCoord:&pointd fromCoord:&midpoint ] ;
                wire1b = [ NCGeometry addCoord:&pointd toCoord:&midpoint ] ;
                gap1 = scale*0.5 ;
               
                segment2 = [ element2 feedSegment ] ;
                point2a = [ element2 coordAtSegment:( segment2 - 1 ) ] ;
                point2b = [ element2 coordAtSegment:( segment2 ) ] ;                
                if ( cross1 != 0 ) {
                    pointt = point2a ;
                    point2a = point2b ;
                    point2b = pointt ;
                }
                midpoint = [ NCGeometry midpointBetweenCoord:&point2a andCoord:&point2b ] ;                
                scale = [ NCGeometry distanceBetweenCoord:&point2a andCoord:&point2b ] ;
                pointd = [ NCGeometry subtractCoord:&point2a fromCoord:&point2b ] ;
                pointd = [ NCGeometry scaleCoord:&pointd factor:[ coax separation ]*0.5/scale ] ;
                wire2a = [ NCGeometry subtractCoord:&pointd fromCoord:&midpoint ] ;
                wire2b = [ NCGeometry addCoord:&pointd toCoord:&midpoint ] ;
                gap2 = scale*0.5 ;


                radius = [ coax conductorRadius ] ;
                
                wireAGeometry = [ NCGeometry geometryWithEnd1:&wire1a end2:&wire2a ] ;
                [ wireAGeometry shortenEndsBy:gap1 ] ;
                [ stack->system newWire:wireAGeometry radius:radius segments:33 ] ;
                
                if ( expose1 != 0 ) [ stack->system newWire:&point1a end2:[ wireAGeometry end1 ] radius:sqrt( radius*[ element1 radius ] ) segments:3 ] ;
                if ( expose2 != 0 ) [ stack->system newWire:&point2a end2:[ wireAGeometry end2 ] radius:sqrt( radius*[ element2 radius ] ) segments:3 ] ;
                
                wireBGeometry = [ NCGeometry geometryWithEnd1:&wire1b end2:&wire2b ] ;
                [ wireBGeometry shortenEndsBy:gap2 ] ;
                [ stack->system newWire:wireBGeometry radius:radius segments:33 ] ;
 
                if ( expose1 != 0 ) [ stack->system newWire:&point1b end2:[ wireBGeometry end1 ] radius:sqrt( radius*[ element1 radius ] ) segments:3 ] ;
                if ( expose2 != 0 ) [ stack->system newWire:&point2b end2:[ wireBGeometry end2 ] radius:sqrt( radius*[ element2 radius ] ) segments:3 ] ;
           }

		}
		//  Create NCNetwork for the transmission line properties.
		//	The NCNetwork is of type NCCOAX, whose admittance matrix is evaluated only when the frequency is known.
		network = [ NCNetwork networkFrom:element1 segment:segment1 to:element2 segment:segment2 coax:coax params:params ] ;
        [ element1 addNetwork:network ] ;

		return self ;
	}
	return nil ;
}

@end
