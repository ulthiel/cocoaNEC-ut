//
//  NCNetwork.h
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

#import <Cocoa/Cocoa.h>
#import "NCStructs.h"
#import "RuntimeStack.h"

@class NCWire ;

#define NCNETWORK				1
#define	NCLINE					2
#define	NCCOAX					3		//  v0.78
#define	NCSERIESTERMINATOR		4		//  v0.83	frequency dependent terminator
#define	NCPARALLELTERMINATOR	5		//  v0.83	frequency dependent terminator


@class NCCoax ;

@interface NCNetwork : NSObject {
	int type ;
	NCWire *from ;
	int fromSegment ;
	NCWire *to ;
	int toSegment ;
	NCAdmittanceMatrix matrix ;
	NCTransmissionLine tl ;
	//	v0.81b
	NCCoax *coax ;
	CoaxCableParams coaxCableParams ;
	//	v0.83
	float terminatorR ;
	float terminatorL ;
	float terminatorC ;
}

- (id)initWithNetworkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 y11r:(double)y11r y11i:(double)y11i y12r:(double)y12r y12i:(double)y12i y22r:(double)y22r y22i:(double)y22i ;
- (id)initWithNetworkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 coax:(NCCoax*)inCoax params:(CoaxCableParams*)p ;
- (id)initWithTransmissionLineFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 z0:(double)z0 length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i ;

+ (id)networkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 y11r:(double)iy11r y11i:(double)iy11i y12r:(double)iy12r y12i:(double)iy12i y22r:(double)iy22r y22i:(double)iy22i ;
+ (id)networkFrom:(NCWire*)element1 to:(NCWire*)element2 y11r:(double)y11r y11i:(double)y11i y12r:(double)y12r y12i:(double)y12i y22r:(double)y22r y22i:(double)y22i ; 

+ (id)networkFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 coax:(NCCoax*)inCoax params:(CoaxCableParams*)p ;

+ (id)terminatorFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 type:(int)inType r:(float)inR l:(float)inL c:(float)inC ;

+ (id)transmissionLineFrom:(NCWire*)element1 segment:(int)seg1 to:(NCWire*)element2 segment:(int)seg2 z0:(double)z0 length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i ;
+ (id)transmissionLineFrom:(NCWire*)element1 to:(NCWire*)element2 z0:(double)z0 crossed:(Boolean)x length:(double)length y1r:(double)y1r y1i:(double)y1i y2r:(double)y2r y2i:(double)y2i ;

- (int)networkType ;
- (NCAdmittanceMatrix*)networkMatrix:(RuntimeStack*)stack frequency:(double)frequency ;
- (NCTransmissionLine*)transmissionLine ;
- (NCWire*)port1 ;
- (NCWire*)port2 ;

- (int)segment1 ;
- (int)segment2 ;

@end
