//
//  NCNetwork.m
//  cocoaNEC
//
//  Created by Kok Chen on 10/3/07.
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

#import "NCNetwork.h"
#import "ApplicationDelegate.h"
#import "NCCoax.h"
#import "NCSystem.h"
#import "NCWire.h"
#import <complex.h>

@implementation NCNetwork


- (id)initWithNetworkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 y11r:(double)y11r y11i:(double)y11i y12r:(double)y12r y12i:(double)y12i y22r:(double)y22r y22i:(double)y22i 
{
	self = [ super init ] ;
	if ( self ) {
		type = NCNETWORK ;
		matrix.y11r = y11r ;
		matrix.y11i = y11i ;
		matrix.y12r = y12r ;
		matrix.y12i = y12i ;
		matrix.y22r = y22r ;
		matrix.y22i = y22i ;
		from = element1 ;
		fromSegment = seg1 ;		// segment 0 denotes center
		to = element2 ;
		toSegment = seg2 ;
	}
	return self ;
}

//	0.78 
//	Generate y parameters during card deck generation phase since we need frequency.
- (id)initWithNetworkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 coax:(NCCoax*)inCoax params:(CoaxCableParams*)p
{
	self = [ super init ] ;
	if ( self ) {
		type = NCCOAX ;
		matrix.y11r = matrix.y11i = matrix.y12r = matrix.y12i = matrix.y22r = matrix.y22i = 0 ;
		coax = inCoax ;
		coaxCableParams = *p ;
		from = element1 ;
		fromSegment = seg1 ;		// segment 0 denotes center
		to = element2 ;
		toSegment = seg2 ;
		[ [ (ApplicationDelegate*)[ NSApp delegate ] currentNCSystem ] setHasFrequencyDependentNetwork:YES ] ;
	}
	return self ;
}

//	0.83 
//	Generate y parameters during card deck generation phase since we need frequency.
- (id)initWithTerminatorFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 type:(int)inType r:(float)inR l:(float)inL c:(float)inC
{
	self = [ super init ] ;
	if ( self ) {
		type = inType ;
		matrix.y11r = matrix.y11i = matrix.y12r = matrix.y12i = matrix.y22r = matrix.y22i = 0 ;
		terminatorR = inR ;
		terminatorL = inL ;
		terminatorC = inC ;
		from = element1 ;
		fromSegment = seg1 ;		// segment 0 denotes center
		to = element2 ;
		toSegment = seg2 ;
		[ [ (ApplicationDelegate*)[ NSApp delegate ] currentNCSystem ] setHasFrequencyDependentNetwork:YES ] ;
	}
	return self ;
}

- (id)initWithTransmissionLineFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 z0:(double)z0 length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i
{
	self = [ super init ] ;
	if ( self ) {
		type = NCLINE ;
		tl.z0 = z0 ;
		tl.length = length ;
		tl.y1r = y1r ;
		tl.y1i = y1i ;
		tl.y2r = y2r ;
		tl.y2i = y2i ;
		from = element1 ;
		fromSegment = seg1 ;		// segmenet 0 denotes center
		to = element2 ;
		toSegment = seg2 ;
	}
	return self ;
}

+ (id)networkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 y11r:(double)y11r y11i:(double)y11i y12r:(double)y12r y12i:(double)y12i y22r:(double)y22r y22i:(double)y22i
{
	NCNetwork *network ;
	
	network = [ [ NCNetwork alloc ] initWithNetworkFrom:element1 segment:seg1 to:element2 segment:seg2 y11r:y11r y11i:y11i y12r:y12r y12i:y12i y22r:y22r y22i:y22i ] ;
	[ network autorelease ] ;
	return network ;
}

+ (id)networkFrom:(NCWire*)element1 to:(NCWire*)element2 y11r:(double)y11r y11i:(double)y11i y12r:(double)y12r y12i:(double)y12i y22r:(double)y22r y22i:(double)y22i 
{
	NCNetwork *network ;
	
	network = [ [ NCNetwork alloc ] initWithNetworkFrom:element1 segment:0 to:element2 segment:0 y11r:y11r y11i:y11i y12r:y12r y12i:y12i y22r:y22r y22i:y22i ] ;
	[ network autorelease ] ;
	return network ;
}

//	v0.78, v0.81
+ (id)networkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 coax:(NCCoax*)inCoax params:(CoaxCableParams*)p
{
	NCNetwork *network ;
	
	network = [ [ NCNetwork alloc ] initWithNetworkFrom:element1 segment:seg1 to:element2 segment:seg2 coax:inCoax params:p ] ;
	[ network autorelease ] ;
	return network ;
}

//	v0.83
+ (id)terminatorFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 type:(int)inType r:(float)inR l:(float)inL c:(float)inC
{
	NCNetwork *network ;
	
	network = [ [ NCNetwork alloc ] initWithTerminatorFrom:element1 segment:seg1 to:element2 segment:seg2  type:inType r:inR l:inL c:inC ] ;
	[ network autorelease ] ;
	return network ;
}

+ (id)transmissionLineFrom:(NCWire*)element1 to:(NCWire*)element2 z0:(double)z0 crossed:(Boolean)crossed length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i
{
	NCNetwork *network ;
	
	if ( crossed ) z0 = -z0 ;
	network = [ [ NCNetwork alloc ] initWithTransmissionLineFrom:element1 segment:0 to:element2 segment:0 z0:z0 length:length y1r:y1r y1i:y1i y2r:y2r y2i:y2i ] ;
	[ network autorelease ] ;
	return network ;
}

+ (id)transmissionLineFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 z0:(double)z0 length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i ;
{
	NCNetwork *network ;

	network = [ [ NCNetwork alloc ] initWithTransmissionLineFrom:element1 segment:seg1 to:element2 segment:seg2  z0:z0 length:length y1r:y1r y1i:y1i y2r:y2r y2i:y2i ] ;
	[ network autorelease ] ;
	return network ;
}

- (int)networkType
{
	return type ;
}

- (int)segment1
{
	return fromSegment ;
}

- (int)segment2
{
	return toSegment ;
}

- (NCAdmittanceMatrix*)networkMatrix:(RuntimeStack*)stack frequency:(double)frequency
{
	complex double zrlc, yrlc ;
	double w, g, l, c, r ;
	
	//  generate frequency dependent y matric elements
	switch ( type ) {
	case NCCOAX:
		matrix = [ coax admittanceMatrixForLength:coaxCableParams.length frequency:frequency ] ;
		//	negate y12 (and y21) when there is a phase reversal (one and only one of the ends is crossed)
		if ( CoaxCrossedDigit( coaxCableParams.end1 ) != CoaxCrossedDigit( coaxCableParams.end2 ) ) {
			matrix.y12r = -matrix.y12r ;
			matrix.y12i = -matrix.y12i ;
		}
		//  include input and output admittances
		matrix.y11r += coaxCableParams.y1r ; 
		matrix.y11i += coaxCableParams.y1i ; 
		matrix.y22r += coaxCableParams.y2r ; 
		matrix.y22i += coaxCableParams.y2i ; 
		break ;
	case NCSERIESTERMINATOR:											//  v0.83
		w = 2.0*3.141592653589*frequency*1.0e6 ;
		c = ( terminatorC < 1e-14 ) ? 1e14 : 1.0/terminatorC ;
		r = terminatorR ;												//  v0.84
		if ( r < 1e-8 ) r = 1e-8 ;										//  v0.84
		zrlc = r + I*( w*terminatorL - c/w ) ;							//  v0.84
		yrlc = ( 1.0/zrlc ) ;											//  v0.84	
		matrix.y11r = creal( yrlc ) ;
		matrix.y11i = cimag( yrlc ) ;
		break ;
	case NCPARALLELTERMINATOR:											//  v0.83
		w = 2.0*3.141592653589*frequency*1.0e6 ;
		g = ( terminatorR < 1e-8 ) ? 1e8 : 1.0/terminatorR ;
		l = ( terminatorL < 1e-12 ) ? 1e12 : 1.0/terminatorL ;
		yrlc = g + I*( w*terminatorC - l/w ) ;
		matrix.y11r = creal( yrlc ) ;
		matrix.y11i = cimag( yrlc ) ;
		break ;
	}
	return &matrix ;
}

- (NCTransmissionLine*)transmissionLine
{
	return &tl ;
}

- (NCWire*)port1
{
	return from ;
}

- (NCWire*)port2
{
	return to ;
}


@end
