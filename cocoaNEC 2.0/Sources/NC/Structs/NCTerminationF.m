//
//  NCTerminationF.m
//  cocoaNEC
//
//  Created by Kok Chen on 11/12/12.
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

#import "NCTerminationF.h"
#import "NCNetwork.h"
#import "NCSystem.h"
#import "NCWire.h"


@implementation NCTerminationF

- (id)initAsType:(int)inType r:(double)inR l:(double)inL c:(double)inC atWire:(NCWire*)wire terminationWire:(NCWire*)shortEnd
{
	NCNetwork *network ;
	
	self = [ super init ] ;
	if ( self ) {
		//  create a network between the midpoints
		network = [ NCNetwork terminatorFrom:wire segment:( [ wire segments ]+1 )/2 to:shortEnd segment:1 type:inType r:inR l:inL c:inC ] ;
		[ wire addNetwork:network ] ;
	}
	return self ;
}

//	v0.83
+ (id)rlcTermination:(NCWire*)wire type:(int)inType r:(double)inR l:(double)inL c:(double)inC system:(NCSystem*)system
{
	NCWire *shortEnd ;
	NCTerminationF *load ;
	WireCoord e1, e2 ;
	
	//	create a short wire segment in the far field (large z)
	e1 = e2 = [ wire midpoint ] ;
	e1.z = e2.z = ( e1.z + [ system farFieldDisplacement ] ) ;
	e1.x += 0.005 ;
	//  generate 3 segment wire
	shortEnd = [ system newWire:&e1 end2:&e2 radius:0.001 segments:3 ] ;
	load = [ [ NCTerminationF alloc ] initAsType:inType r:inR l:inL c:inC atWire:wire terminationWire:shortEnd ] ;
	return [ load autorelease ] ;
}

@end
