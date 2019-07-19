//
//  Feedpoint.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/22/07.
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

#import "Feedpoint.h"
#import "Exception.h"
#import "CurrentSource.h"


@implementation Feedpoint

//  return false if it is a current source
- (Boolean)isVoltageSource:(int)tag exceptions:(NSArray*)exceptions
{
	intType i, n ;
	Exception *exception ;
	
	n = [ exceptions count ] ;
	if ( n == 0 ) return YES ;
	
	for ( i = 0; i < n; i++ ) {
		exception = [ exceptions objectAtIndex:i ] ;
		if ( [ exception wireType ] == CURRENTEXCEPTION && [ exception tag ] == tag ) return NO ;
	}
	return YES ;
}

- (void)actualLocation:(int)tag exceptions:(NSArray*)exceptions
{
	intType i, n ;
	Exception *exception ;
	
	w.tagOfDestination = w.segmentOfDestination = 0 ;

	n = [ exceptions count ] ;
	if ( n == 0 ) return ;
	
	for ( i = 0; i < n; i++ ) {
		exception = [ exceptions objectAtIndex:i ] ;
		if ( [ exception tag ] == tag ) {
			w.tagOfDestination = [ exception tagOfTarget ] ;
			w.segmentOfDestination = [ exception segmentOfTarget ] ;
			return ;
		}
	}
}

- (Boolean)parseFeedpoint:(char*)string frequency:(double)frequency exceptions:(NSArray*)exceptions
{
	int tag, seg ;
	double tr, ti ;
	
	if ( strlen( string ) < 16 ) return NO ;
	
	tag = seg = -1 ;
	w.power = 1.1e12 ;
	sscanf( string, "%d %d %le %le %le %le %le %le %le %le %le", &tag, &seg, &w.vr, &w.vi, &w.cr, &w.ci, &w.zr, &w.zi, &w.gr, &w.gi, &w.power ) ;
	
	if ( tag < 0 || seg < 0 || w.power > 1e12 ) return NO ;
	
	w.tag = tag ;
	w.segment = seg ;
	w.frequency = frequency ;
	
	w.currentSource = ( [ self isVoltageSource:tag exceptions:exceptions ] == NO ) ;
	
	if ( w.currentSource == YES ) {
		tr = w.zr ;
		ti = w.zi ;
		w.zr = w.gr ;
		w.zi = w.gi ;
		w.gr = tr ;
		w.gi = ti ;
		//  convert between voltage and currents (multiply by -i, and swap)
		tr = w.vr ;
		ti = w.vi ;
		w.vr = w.ci;
		w.vi = -w.cr ;
		w.cr = ti ;
		w.ci = -tr ;
		//  find target of current source		
		[ self actualLocation:tag exceptions:exceptions ] ; 
	}
	else {
		//  if voltage source, target is ourselve
		w.tagOfDestination = tag ;
		w.segmentOfDestination = seg ;
	}	
	
	return YES ;
}

- (id)initWithLine:(char*)string frequency:(double)frequency exceptions:(NSArray*)exceptions
{
	self = [ super init ] ;
	if ( self ) {
		if ( ![ self parseFeedpoint:string frequency:frequency exceptions:exceptions ] ) {
			[ self autorelease ] ;
			return nil ;
		}
	}
	return self ;
}

- (FeedpointInfo*)info
{
	return &w ;
}

@end
