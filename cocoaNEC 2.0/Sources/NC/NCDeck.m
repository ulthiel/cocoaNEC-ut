//
//  NCDeck.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/22/07.
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

#import "NCDeck.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "DateFormat.h"
#import "Exception.h"
#import "NC.h"
#import "NCRadials.h"
#import "NCSystem.h"
#import "NCWire.h"


@implementation NCDeck

- (id)initForPath:(NSString*)path
{
	self = [ super init ] ;
	if ( self ) {
		pathForDeck = path ;
		hollerithArray = [ [ NSMutableArray alloc ] initWithCapacity:60 ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ hollerithArray release ] ;
	[ super dealloc ] ;
}

- (void)outputCard:(NSString*)string
{
	[ hollerithArray addObject:string ] ;
	fprintf( file, "%s\n", [ string UTF8String ] ) ;
}

//	v0.77
- (void)generateCoaxLines:(NSArray*)lines
{
	//  coax uses NSWire function; nothing to do here.
}

- (void)generateGeometryCards:(NSArray*)elements stack:(RuntimeStack*)stack
{
	intType i, j, count, cardsCount ;
	NCElement *element ;
	NSArray *cards ;
	
	count = [ elements count ] ;
	
	//  first pass
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element (most only have one card)
			cards = [ element geometryCards ] ;
			cardsCount = [ cards count ] ;
			for ( j = 0; j < cardsCount; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
		}
	}
	//  second pass -- generate elements for current source
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element (most only have one card)
			cards = [ element currentGeometryCards:tagsAfterAddingCurrentSources ] ;
			cardsCount = [ cards count ] ;
			for ( j = 0; j < cardsCount; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
			tagsAfterAddingCurrentSources += cardsCount ;
		}
	}	
}

- (void)generateRadialCards:(NSArray*)arrayOfRadials stack:(RuntimeStack*)stack
{
	intType i, count, cardsCount ;
    int j ;
	NCRadials *radials ;
	NSArray *cards ;
	Exception *exception ;

	count = [ arrayOfRadials count ] ;
	for ( i = 0; i < count; i++ ) {
		radials = [ arrayOfRadials objectAtIndex:i ] ;
		if ( radials != nil ) {
			//  output cards for each set of radials
			cards = [ radials geometryCards:tagsAfterAddingRadials ] ;
			cardsCount = [ cards count ] ;
			for ( j = 0; j < cardsCount; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
				//  mark as a radial for output geometry exceptions
				exception = [ Exception exceptionForRadial:tagsAfterAddingRadials+j+1 ] ;  
				[ stack->exceptions addObject:exception ] ;
			}
			tagsAfterAddingRadials += cardsCount ;
		}
	}
}

//  create cards for loads
- (void)generateLoads:(NSArray*)elements
{
	intType i, j, count ;
	NCWire *element ;
	NSArray *cards ;

	count = [ elements count ] ;
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element's load (most elements have no load card)
			cards = [ element loadCardsForInsulatedWire ] ;
			for ( j = 0; j < [ cards count ]; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
		}
	}
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element's load (most elements have no load card)
			cards = [ element loadCards ] ;
			for ( j = 0; j < [ cards count ]; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
		}
	}
}

//  create cards for excitations
- (void)generateExcitations:(NSArray*)elements
{
	intType i, j, count ;
	NCWire *element ;
	NSArray *cards ;

	count = [ elements count ] ;
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element's excitation (most elements have no excitation card)
			cards = [ element excitationCards ] ;
			for ( j = 0; j < [ cards count ]; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
				excitations++ ;											// v0.41
			}
		}
	}
}

//	(Private API)
//  create cards for networks and transmission lines
- (void)generateNetworks:(NSArray*)elements frequency:(double)frequency
{
	intType i, j, count ;
	NCWire *element ;
	NSArray *cards ;

	count = [ elements count ] ;
	for ( i = 0; i < count; i++ ) {
		element = [ elements objectAtIndex:i ] ;
		if ( element != nil ) {
			//  output cards for each geometry element's network (most elements have no network card)
			cards = [ element networkCardsForFrequency:frequency ] ;
			for ( j = 0; j < [ cards count ]; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
			//  output network cards for each geometry element's current excitation
			cards = [ element networkCardsForCurrentExcitation ] ;
			for ( j = 0; j < [ cards count ]; j++ ) {
				[ self outputCard:[ cards objectAtIndex:j ] ] ;
			}
		}
	}
}

- (void)generateGroundCards:(NCSystem*)system
{
	int sommerfeld, nRadials ;
	NC *nc ;
	NECRadials *necRadials ;
	
	if ( [ system isFreeSpace ] ) return ;
	
	nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
	necRadials = [ nc necRadials ] ;

	nRadials = 0 ;
	if ( necRadials->useNECRadials ) nRadials = necRadials->n ;

	//  ground parameters
	if ( [ system isPerfectGround ] ) {
		[ self outputCard:[ NSString stringWithFormat:@"GN  1%5d    0                 ", nRadials ] ] ;
	}
	else {
		//  v0.78 Use GN3 for Sommerfeld ground in NEC-4.2
		sommerfeld = 0 ;
		if ( [ system isSommerfeld ] ) {
			sommerfeld = ( [ (ApplicationDelegate*)[ NSApp delegate ] engine ] == kNEC42Engine ) ? 3 : 2 ;
		}
		if ( nRadials == 0 ) {
			[ self outputCard:[ NSString stringWithFormat:@"GN  %d%5d    0    0%10s%10s", sommerfeld, nRadials, dtos( [ system dielectric ]), dtos( [ system conductivity ] ) ] ] ;
		}
		else {
			[ self outputCard:[ NSString stringWithFormat:@"GN  %d%5d    0    0%10s%10s%10s%10s", sommerfeld, nRadials, dtos( [ system dielectric ]), dtos( [ system conductivity ] ), dtos( necRadials->length ), dtos( necRadials->wireRadius ) ] ] ;
		}
	}
}

- (void)generateSystemControlCards:(RuntimeStack*)stack system:(NCSystem*)system frequency:(double)frequency generate3d:(Boolean)generate3d
{
	intType i, count ;
	NSArray *angles ;
	double distance ;
	
	[ self outputCard:[ NSString stringWithFormat:@"FR  0    1    0    0%10s%10s", dtos( frequency ), dtos( 0.0 ) ] ] ;		//  FR
	[ self generateGroundCards:system ] ;																					//  GN
	[ self generateExcitations:stack->geometryElements ] ;																	//  EX

	[ self outputCard:[ NSString stringWithFormat:@"XQ" ] ] ;		//  v0.61
	
	angles = [ system azimuthPlots ] ; 
	distance = [ system azimuthPlotDistance ] ;
	count = [ angles count ] ;
	int linear = 1 ;
	if ( count == 0 ) {
		[ self outputCard:[ NSString stringWithFormat:@"RP  0    1  360 %1d000    70.000     0.000     0.000     1.000 %9.3E", linear, distance ] ] ;
	}
	else {
		for ( i = 0; i < count; i++ ) {
			[ self outputCard:[ NSString stringWithFormat:@"RP  0    1  360 %1d000%10s     0.000     0.000     1.000 %9.3E", linear, dtos( 90-[ [ angles objectAtIndex:i ] doubleValue ] ), distance ] ] ;
		}
	}
	angles = [ system elevationPlots ] ; 
	distance = [ system elevationPlotDistance ] ;
	count = [ angles count ] ;
	if ( count == 0 ) {
		[ self outputCard:[ NSString stringWithFormat:@"RP  0  360    1 %1d000   -90.000     0.000     1.000     0.000 %9.3E", linear, distance ] ] ;
	}
	else {
		for ( i = 0; i < count; i++ ) {
			[ self outputCard:[ NSString stringWithFormat:@"RP  0  360    1 %1d000   -90.000%10s     1.000     0.000 %9.3E", linear, dtos( [ [ angles objectAtIndex:i ] doubleValue ] ), distance ] ] ;
		}
	}
	if ( generate3d && [(ApplicationDelegate*)[ NSApp delegate ] enabled3d ] )		//  v0.61r
		[ self outputCard:[ NSString stringWithFormat:@"RP  0   91  120 %1d001     0.000     0.000     2.000     3.000 5.000E+03", linear ] ] ;				// v 0.30, v0.62
}

- (Boolean)generateDeck:(RuntimeStack*)stack
{
	intType i, count ;
	double frequency ;
	NSArray *frequencyArray ;
	NCSystem *system = stack->system ;
	Boolean generateNetworks ;
	
	excitations = 0 ;
	[ hollerithArray removeAllObjects ] ;
	
	file = fopen( [ pathForDeck UTF8String ], "w" ) ;
	if ( file ) {	
		// [ [ NSDate date ] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M" timeZone:nil locale:nil ] ; deprecated
        
        NSString *dateString = [ DateFormat descriptionWithCalendarFormat:@"Y-M-d HH:mm" timeZone:nil locale:nil ] ;
        
		[ self outputCard:[ NSString stringWithFormat:@"CM %s %s", [ system modelName ], [ dateString UTF8String ] ] ] ;
		[ self outputCard:@"CE ----------"  ] ;
		originalTags = tagsAfterAddingCurrentSources = [ system tags ] ;
		[ self generateGeometryCards:stack->geometryElements stack:stack ] ;
		tagsAfterAddingRadials = tagsAfterAddingCurrentSources ;	
		[ self generateRadialCards:[ system radials ] stack:stack ] ;
		[ self generateCoaxLines:stack->coaxLines ] ;
		
		//  end geometry, CE card
		if ( [ system isFreeSpace ] ) [ self outputCard:@"GE  0" ] ; else [ self outputCard:@"GE  1" ] ;
		
		//  extended thin-wire kernel
		if ( [ system useExtendedKernel ] ) [ self outputCard:@"EK  0" ] ;

		//  control cards
		[ self generateLoads:stack->geometryElements ] ;
		
		frequencyArray = [ system frequencyArray ] ;
		if ( !frequencyArray || [ frequencyArray count ] == 0 ) {
			//  v0.61r
			[ self generateNetworks:stack->geometryElements frequency:DefaultFrequency ] ;
			[ self generateSystemControlCards:stack system:system frequency:DefaultFrequency generate3d:YES ] ;		//  FR GN RP
			[ self outputCard:@"XQ" ] ;
		}
		else {
			generateNetworks = [ system hasFrequencyDependentNetwork ] ;
			count = [ frequencyArray count ] ;
			for ( i = 0; i < count; i++ ) {
				frequency = [ [ frequencyArray objectAtIndex:i ] doubleValue ] ;
				if ( i == 0 || generateNetworks ) [ self generateNetworks:stack->geometryElements frequency:frequency ] ;
				//  v0.61r only generate one 3D RP card
				[ self generateSystemControlCards:stack system:system frequency:frequency generate3d:( i == 0 ) ] ;
				[ self outputCard:@"XQ" ] ;
			}
		}
		[ self outputCard:@"EN" ] ;
		fclose( file ) ;
	}
	if ( excitations < 1 ) {
        
        //  v0.88
		[ AlertExtension modalAlert:@"No excitation defined." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nYou have not defined any excitation.  The model will not be submitted to NEC-2.\n" ] ;
       
		return NO ;
	}
	return YES ;
}

- (NSArray*)hollerithArray
{
	return hollerithArray ;
}

@end
