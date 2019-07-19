//
//  NCWire.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/20/07.
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

#import "NCWire.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "Exception.h"
#import "NCNode.h"
#import "NECEngines.h"
#import <complex.h>

@implementation NCWire

- (id)initWithRuntime:(RuntimeStack*)rt
{
	self = [ super init ] ;
	if ( self ) {
		end1.x = end2.x = 0.0 ;
		end1.y = -( end2.y = 5.0 ) ;
		end1.z = end2.z = 12.0 ;
		segments = 21 ;
		feedSegment = 11 ;
		radius = originalRadius = 0.01 ;
		runtime = rt ;
		tag = 0 ;
		feed = nil ;
		arrayOfLoads = nil ;
		translate.x = translate.y = translate.x = 0 ;
		rotate = translate ;
		arrayOfNetworks = nil ;					//  v0.48
		tagForCurrentSource = 0 ;
	}
	return self ;
}

// v0.48
- (void)dealloc
{
	if ( arrayOfNetworks ) [ arrayOfNetworks release ] ;
	if ( arrayOfLoads != nil ) [ arrayOfLoads release ] ;
	[ super dealloc ] ;
}

- (double)x1 
{
	return end1.x ;
}

- (double)y1 
{
	return end1.y ;
}

- (double)z1
{
	return end1.z ;
}

- (double)x2 
{
	return end2.x ;
}

- (double)y2 
{
	return end2.y ;
}

- (double)z2 
{
	return end2.z ;
}

//  v0.77  return center(w2) - center(w1)
+ (NCGeometry*)vector:(NCWire*)w1 to:(NCWire*)w2 
{
	WireCoord c1, c2 ;
	
	c1 = [ w1 midpoint ] ;
	c2 = [ w2 midpoint ] ;
	
	return [ NCGeometry geometryWithEnd1:&c1 end2:&c2 ] ;
}

//	v0.75b
- (void)setRadius:(double)value 
{
	radius = originalRadius = value ;
}

//	v0.75b
- (void)modifyRadius:(double)value 
{
	radius = value ;
}

//	v0.75b
- (double)radius 
{
	return originalRadius ;
}

//  make into odd segments, with at least 3 segments
- (void)setSegments:(int)value
{
	if ( ( value & 1 ) == 0 ) value++ ;
	segments = value ;
	feedSegment = ( segments+1 )/2 ;					//  v0.55
}

//  v0.55
- (void)setTranslate:(WireCoord*)coord
{
	translate = *coord ;
}

//	v0.55
- (void)setRotate:(WireCoord*)coord
{
	rotate = *coord ;
}

//	v0.55	return nil if there is no need to generate a GM card
- (NSString*)gmCard
{
	double p ;
	
	p = fabs( translate.x ) + fabs( translate.y ) + fabs( translate.z ) + fabs( rotate.x ) + fabs( rotate.y ) + fabs( rotate.z ) ;
	
	if ( p < .0000001 ) return nil ;

	//  v0.86
    //  v0.88
    return [ NSString stringWithFormat:[ Config format:"GM%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
            0, 0, dtos(rotate.x), dtos(rotate.y), dtos(rotate.z), dtos(translate.x), dtos(translate.y), dtos(translate.z), dtos( tag ) ] ;
}

//  v0.55
- (void)setFeedSegment:(int)value 
{
	if ( value > segments ) value = segments ; 
	feedSegment = value ;
}

//  v0.92
- (int)feedSegment
{
    return feedSegment ;
}

- (int)segments 
{
	return segments ;
}

- (void)setTag:(int)value
{
	tag = value ;       //  v0.89 removed + 998 that was used during testing
}

- (int)tag
{
	return tag ;
}

//	v0.55  added segment
- (void)setExcitation:(NCExcitation*)excitation segment:(int)seg
{
	if ( feed != nil ) {
		[ AlertExtension modalAlert:@"Feedpoints overlap." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nTwo feeds (voltage or current feed) are placed on the same wire!  Please remove one of them.\n\nOnly one of the feedpoints is used to run the model.\n" ] ;
	}
	feed = excitation ;
	if ( seg != 0 ) [ self setFeedSegment:seg ] ;
}

- (NCExcitation*)excitation
{
	return feed ;
}

//	v0.75a (was setLoad for a single load/wire).
- (void)addLoad:(NCLoad*)inLoad
{
	if ( arrayOfLoads == nil ) arrayOfLoads = [ [ NSMutableArray alloc ] init ] ;		
	[ arrayOfLoads addObject:inLoad ] ;
}

//	v0.75a
- (NSArray*)loads
{
	return arrayOfLoads ;
}

//	v0.81
- (void)addTermination:(NCTermination*)inLoad
{
	Exception *exception ;
	int terminationTag ;
	
	if ( inLoad == nil ) return ;

	[ self addLoad:(NCLoad*)inLoad ] ;
	
	terminationTag = [ [ inLoad terminationWire ] tag ] ;
	
	//	Add short wire in far field of termination to exception list for Geometry view (don't draw)
	exception = [ Exception exceptionForTermination:terminationTag targetTag:tag targetSegment:0 ] ;  
	[ runtime->exceptions addObject:exception ] ;
}

- (void)addNetwork:(NCNetwork*)network
{
	//  v0.48
	if ( arrayOfNetworks == nil ) {
		arrayOfNetworks = [ [ NSMutableArray alloc ] initWithCapacity:1 ] ;
	}
	[ arrayOfNetworks addObject:network ] ;
}

//  v0.48
- (NCNetwork*)networkAtIndex:(int)i
{
	if ( arrayOfNetworks == nil ) return nil ;
	
	return [ arrayOfNetworks objectAtIndex:i ] ;
}

//  v0.41 warn instead of forcing number of segments to 3
- (void)tooFewSegments
{
}

//	v0.81
- (double)segmentLength
{
	if ( tag <= 0 || segments < 1 ) return 1e6 ;
	return [ self length ]/segments ;
}

//	v0.81
//	Allow segment to be 0 (equals to end1)
- (WireCoord)coordAtSegment:(int)segment
{
	
	if ( segment < 0 ) segment = 0 ; 
    else if ( segment > segments ) segment = segments ;
	
	return [ self coordAtFraction:segment*1.0/segments ] ;
}

- (NSArray*)geometryCards
{
	NSString *card, *gm ;
	
	if ( tag <= 0 ) return [ NSArray array ] ;
	
	//	v0.75a changed to check multiple loads
	//	v0.78 incorporated nec2c v0.4 bug fix for single segment wires.	
	//  v0.64
    //  v0.86
    //  v0.88
    card = [ NSString stringWithFormat:[ Config format:"GW%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
            tag, segments, dtos(end1.x), dtos(end1.y), dtos(end1.z), dtos(end2.x), dtos(end2.y), dtos(end2.z), dtos(radius) ] ;

	//  v0.55
	gm = [ self gmCard ] ;
	if ( gm == nil ) {
		return [ NSArray arrayWithObjects:card, nil ] ;			//  v0.64
	}
	return [ NSArray arrayWithObjects:card, gm, nil ] ;
}

- (NSArray*)currentGeometryCards:(int)tags
{
	NSString *card ;
	double xc, yc, zc, dx, dy, dz, limit ;
	
	if ( tag <= 0 ) return [ NSArray array ] ;
	
	if ( feed && [ feed excitationType ] == CURRENTEXCITATION ) {
		//  don't create a card on the first pass through the list
		xc = ( end1.x + end2.x )*0.5 ;
		dx = ( end2.x - end1.x )*0.01 ;
		yc = ( end1.y + end2.y )*0.5 ;
		dy = ( end2.y - end1.y )*0.01 ;
		zc = ( end1.z + end2.z )*0.5 + [ runtime->system farFieldDisplacement ] ;
		dz = ( end2.z - end1.z )*0.01 ;
		
		//  make element length or the order of 10xradius to 18*radius
		limit = radius*10 ;
		if ( fabs( dx ) > 0.00001 ) dx = dx/fabs(dx)*limit ;
		if ( fabs( dy ) > 0.00001 ) dy = dy/fabs(dy)*limit ;
		if ( fabs( dz ) > 0.00001 ) dz = dz/fabs(dz)*limit ;
		//  generate 3 element
		tagForCurrentSource = tags+1 ;
		//  v0.64
		//  v0.86
        //  v0.88
        card = [ NSString stringWithFormat:[ Config format:"GW%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
                tagForCurrentSource, 3, dtos(xc-dx), dtos(yc-dy), dtos(zc-dz), dtos(xc+dx), dtos(yc+dy), dtos(zc+dz), dtos(radius) ] ;

        return [ NSArray arrayWithObjects:card, nil ] ; ;
	}
	return [ NSArray array ] ;
}

- (NSArray*)networkCardsForCurrentExcitation
{
	NSString *card ;
	Exception *exception ;
	int segment ;
	
	if ( tag <= 0 ) return [ NSArray array ] ;

	if ( feed ) {
		//  v0.55 -- no longer center segment
		segment = feedSegment ;
		if ( [ feed excitationType ] == CURRENTEXCITATION ) {
		
			exception = [ Exception exceptionForCurrentSource:tagForCurrentSource targetTag:tag targetSegment:segment ] ;  
			[ runtime->exceptions addObject:exception ] ;
			
			//  v0.86
            //  v0.88
            card = [ [ NSString alloc ] initWithFormat:[ Config format:"NT%3d%5d%5d%5d %9f %9f %9f %9f %9f %9f" ],
                    tagForCurrentSource, 2, tag, segment, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0 ] ;

            return [ NSArray arrayWithObjects:card, nil ] ;
		}
	}
	return [ NSArray array ] ;
}

- (NSArray*)excitationCards
{
	NSString *card ;
	Exception *exception ;
	
	int segment, type, i1 ;
	
	if ( tag <= 0 ) return [ NSArray array ] ;

	if ( feed ) {
		//  v0.55 -- no longer center segment
		segment = feedSegment ;
		
		//  v0.51 -- implement incident plane waves
		
		type = [ feed excitationType ] ;
		switch ( type ) {
		case CURRENTEXCITATION:
			//  current source
			exception = [ Exception exceptionForCurrentSource:tagForCurrentSource targetTag:tag targetSegment:segment ] ;  
			[ runtime->exceptions addObject:exception ] ;
			//  NOTE: apply 90 degree phase shift to compensate for y12
			//	v0.86
            //  v0.88 removed format change since tag is in second field
            card = [ [ NSString alloc ] initWithFormat:@"EX%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s",
                    0, tagForCurrentSource, 2, 1, dtos( -[ feed imag ] ), dtos( [ feed real ] ), "", "", "", "" ]  ;
			return [ NSArray arrayWithObjects:card, nil ] ;
                
		case VOLTAGEEXCITATION:
			//  v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"EX%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s",
                    0, tag, segment, 1, dtos( [ feed real ] ), dtos( [ feed imag ] ), "", "", "", "" ] ;
			return [ NSArray arrayWithObjects:card, nil ] ;
                
		case PLANEEXCITATION:
		case RIGHTEXCITATION:
		case LEFTEXCITATION:
			if ( type == PLANEEXCITATION ) i1 = 1 ; else if ( type == RIGHTEXCITATION ) i1 = 2 ; else i1 = 3 ;
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"EX%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", i1, tag, segment, 0, dtos( [ feed theta ] ), dtos( [ feed phi ] ),  dtos( [ feed eta ] ), "", "", "" ] ;
			return [ NSArray arrayWithObjects:card, nil ] ;
		}
	}
	return [ NSArray array ] ;
}

//	v0.75a -- changed loadCards to handle multiple loads, one ant a time
- (void)addLoad:(NCLoad*)load toCardDeck:(NSMutableArray*)array
{
	NSString *card ;
	NCTermination *termination ;
	NCWire *terminationWire ;
	int loadType, segment0, segment1, tag1, seg1, tag2, seg2 ;
	complex double c ;
	
	if ( load ) {
		loadType = [ load loadType ] ;
		segment0 = [ load segment0 ] ;
		segment1 = [ load segment1 ] ;
		if ( loadType != INSULATEDWIRE ) {
			if ( segment0 == 0 ) {
				//  center segment
				segment0 = segment1 = ( segments+1 )/2 ;
			}
			else {
				if ( segment0 < 1 ) segment0 = 1 ;
				if ( segment1 > segments ) segment1 = segments ;
			}
		}
		switch ( loadType ) {
		case IMPEDANCELOAD:
			//  v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"LD%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", 4, tag, segment0, segment1, dtosExtended( [ load real ] ), dtosExtended( [ load imag ] ), "", "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
                
		case CONDUCTIVELOADALLSEGMENTS:
			//  conductive card, all segments
			//  v0.75a use ITAGF = ITAGT = 0 for all segments
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"LD%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", 5, tag, 0, 0, dtosExtended( [ load conductivity ] ), "", "", "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
		case CONDUCTIVELOAD:
			//  conductve card, all segments
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"LD%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", 5, tag, segment0, segment1, dtosExtended( [ load conductivity ] ), "", "", "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
		case SERIESRLC:
		case PARALLELRLC:
			//  RLC card, single load at range of segments
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"LD%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", loadType, tag, segment0, segment1, dtosExtended( [ load r ] ), dtosExtended( [ load l ] ), dtosExtended( [ load c ] ), "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
		case DISTRIBUTEDSERIESRLC:
		case DISTRIBUTEDPARALLELRLC:
			//  RLC card, loads at all segments
			//  v0.75a use ITAGF = ITAGT = 0 for all segments
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"LD%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", loadType, tag, 0, 0, dtosExtended( [ load r ] ), dtosExtended( [ load l ] ), dtosExtended( [ load c ] ), "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
		case INSULATEDWIRE:
			//  v0.73
			//	v0.86
            //  v0.88 removed format change since tag is in second field
			card = [ [ NSString alloc ] initWithFormat:@"IS%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s", 0, tag, segment0, segment1, dtosExtended( [ load real ] ), dtosExtended( [ load imag ] ), dtosExtended( [ load c ] ), "", "", "" ] ;
			[ array addObject:card ] ;
			return ;
		case IMPEDANCETERMINATION:
			//  v0.81
			tag1 = [ self tag ] ;
			seg1 = ( [ self segments ]+1 )/2 ;
			termination = (NCTermination*)load ;
			terminationWire = [ termination terminationWire ] ;
			tag2 = [ terminationWire tag ] ;
			seg2 = ( [ terminationWire segments ]+1 )/2 ;
			c = ( [ load real ] + I*[ load imag ] ) ;
			if ( cabs( c ) < 0.01 ) c = 5e7 ; else c = 1/c ;
			//	v0.86
            //  v0.88
            card = [ NSString stringWithFormat:[ Config format:"TL%3d%5d%5d%5d%10.2f%10.3f%10s%10s%10s%10s" ],
                        tag1, seg1, tag2, seg2, 50.0, 0.002, dtosExtended( creal( c ) ), dtosExtended( cimag( c )), dtos(0), dtos(0) ] ;
			[ array addObject:card ] ;
			return ;
		}
	}
}

//	v0.75a -- allow multiple load cards, not including IS cards
- (NSArray*)loadCards
{
	NSMutableArray *array ;
	NCLoad *load ;
	intType count, i ;
	
	count = ( arrayOfLoads == nil ) ? 0 : [ arrayOfLoads count ] ;
	if ( tag <= 0 || count <= 0 ) return [ NSArray array ] ;
	
	array = [ NSMutableArray arrayWithCapacity:1 ] ;
	for ( i = 0; i < count; i++ ) {
		load = [ arrayOfLoads objectAtIndex: i ] ;
		if ( [ load loadType ] != INSULATEDWIRE ) [ self addLoad:load toCardDeck:array ] ;
	}
	return array ;
}

//	v0.75a -- allow multiple load cards, grouping IS cards together
//	IS cards need to appear in the card deck after all the geometry cards, but before any load card.
- (NSArray*)loadCardsForInsulatedWire
{
	NSMutableArray *array ;
	NCLoad *load ;
	intType count, i ;
	
	count = ( arrayOfLoads == nil ) ? 0 : [ arrayOfLoads count ] ;
	if ( tag <= 0 || count <= 0 ) return [ NSArray array ] ;
	
	array = [ NSMutableArray arrayWithCapacity:1 ] ;
	for ( i = 0; i < count; i++ ) {
		load = [ arrayOfLoads objectAtIndex: i ] ;
		if ( [ load loadType ] == INSULATEDWIRE ) [ self addLoad:load toCardDeck:array ] ;
	}
	return array ;
}

//	v0.81 -- added frequency dependency (for NT card y parameters)
- (NSArray*)networkCardsForFrequency:(double)frequency
{
	NCWire *p1, *p2 ;
	NSString *card ;
	NCAdmittanceMatrix *m ;
	NCTransmissionLine *t ;
	NCNetwork *network ;
	NSMutableArray *arrayOfCards ;
	int segment1, segment2, tag1, tag2, networkType, i ;
    intType count ;
	float z0 ;
	
	//  v0.48
	//	NCWire used to take only a single variable "network"
	//  This is now changed to "arrayOfNetworks"
	
	if ( arrayOfNetworks == nil || ( count = [ arrayOfNetworks count ] ) == 0 ) return [ NSArray array ] ;
	
	arrayOfCards = [ NSMutableArray arrayWithCapacity:0  ] ;
	
	for ( i = 0; i < count; i++ ) {
		network = [ arrayOfNetworks objectAtIndex:i ] ;
	
		p1 = [ network port1 ] ;
		p2 = [ network port2 ] ;
		if ( p1 == nil || p2 == nil ) continue ;
		
		tag1 = [ p1 tag ] ;
		tag2 = [ p2 tag ] ;
		if ( tag1 <= 0 || tag2 <= 0 ) continue ;

		//  center segments
		segment1 = [ network segment1 ] ;
		if ( segment1 == 0 ) segment1 = ( [ p1 segments ]+1 )/2 ;
		
		segment2 = [ network segment2 ] ;
		if ( segment2 == 0 ) segment2 = ( [ p2 segments ]+1 )/2 ;
		
		//  decide if NT or TL card
		networkType = [ network networkType ] ;
			
		switch ( networkType ) {
		case NCCOAX:
		case NCNETWORK:
		case NCSERIESTERMINATOR:
		case NCPARALLELTERMINATOR:
			m = [ network networkMatrix:runtime frequency:frequency ] ;
			//  v0.86
            //  v0.88
                card = [ [ NSString alloc ] initWithFormat:[ Config format:"NT%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
                        tag1, segment1, tag2, segment2, dtos( m->y11r ), dtos( m->y11i ), dtos( m->y12r ), dtos( m->y12i ), dtos( m->y22r ), dtos( m->y22i ) ] ;

            [ arrayOfCards addObject:card ] ;
			break ;
		case NCLINE:
			t = [ network transmissionLine ] ;
			z0 = t->z0 ;		//  got rid of tabs
			//	v0.86
            //  v0.88
            card = [ [ NSString alloc ] initWithFormat:[ Config format:"TL%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
                tag1, segment1, tag2, segment2, dtos( z0 ), dtos( t->length ), dtos( t->y1r ), dtos( t->y1i ), dtos( t->y2r ), dtos( t->y2i ) ] ;
			[ arrayOfCards addObject:card ] ;
			break ;
		default:
			printf( "bad network object\n" ) ;
			break ;
		}
	}
	return arrayOfCards ;
}

@end
