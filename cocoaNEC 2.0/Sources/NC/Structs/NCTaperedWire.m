//
//  NCTaperedWire.m
//  cocoaNEC
//
//  Created by Kok Chen on 4/27/08.
//	-----------------------------------------------------------------------------
//  Copyright 2008-2016 Kok Chen, W7AY. 
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

#import "NCTaperedWire.h"
#import "AlertExtension.h"
#import "NCSystem.h"

@implementation NCTaperedWire


- (id)initWithRuntime:(RuntimeStack*)rt
{
	self = [ super initWithRuntime:rt ] ;
	if ( self ) {
		//  create center wire
		segments = 21 ;
		taper1 = taper2 = 0.022 ;
	}
	return self ;
}

- (void)setTaper1:(double)value
{
	taper1 = fabs( value ) ;
}

- (double)taper1
{
	return taper1 ;
}

- (void)setTaper2:(double)value
{
	taper2 = fabs( value ) ;
}

- (double)taper2
{
	return taper2 ;
}

- (void)setStartingTag:(int)value
{
	tag = value ;
}

- (int)tag
{
	return tag ;
}

- (NSString*)emitGeometry:(int)tagn segs:(int)segs x1:(double)sx1 y1:(double)sy1 z1:(double)sz1 x2:(double)sx2 y2:(double)sy2 z2:(double)sz2 
{	
	float dx, dy, dz, segmentLength ;
	
	[ self setSegments:segs ] ;		//  v0.56

	//  v0.51 -- warn if segment length s smaller than wire radius
	dx = sx1-sx2 ;
	dy = sy1-sy2 ;
	dz = sz1-sz2 ;
	segmentLength = sqrt( dx*dx + dy*dy + dz*dz ) ;
    if ( segmentLength < radius ) {
        
        //  v0.88
        [ AlertExtension modalAlert:@"TaperedWire warning." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nSegment length is less than the wire radius.  This could lead to inaccurate results.\n" ] ;
    }
	//  v0.86
    //  v0.88
    return [ [ NSString alloc ] initWithFormat:[ Config format:"GW%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
            tagn, segs, dtos(sx1), dtos(sy1), dtos(sz1), dtos(sx2), dtos(sy2), dtos(sz2), dtos(radius) ] ;
}

- (NSArray*)taperedGeometryCards:(Boolean)needCenter tag:(int)tagn x1:(double)tx1 y1:(double)ty1 z1:(double)tz1 x2:(double)tx2 y2:(double)ty2 z2:(double)tz2 
{
	double dx, dy, dz, sx, sy, sz, xo, yo, zo, xp, yp, zp, length, freq, w, averageTaper, averageSegment, s0, s1, excess, arith, factor ;
	NSArray *frequencies ;
	NSMutableArray *array ;
	NSString *card ;
	int i, n ;
	
	//  get current frequency
	freq = DefaultFrequency ;
	frequencies = [ runtime->system frequencyArray ] ;
	if ( frequencies != nil && [ frequencies count ] > 0 ) {
		freq = [ [ frequencies objectAtIndex:0 ] doubleValue ] ;
	}
	w = 299.792458/freq ;
	averageTaper = ( taper1 + taper2 )*0.5 ;
	averageSegment = w*averageTaper ;
	dx = tx2 - tx1 ;
	dy = ty2 - ty1 ;
	dz = tz2 - tz1 ;
	length = sqrt( dx*dx + dy*dy + dz*dz ) ;
	//  estimate the number of segments
	n = length/averageSegment + 0.5 ;

	//  recurvively break into three pieces if the center is needed
	if ( needCenter ) {
		n |= 1 ;		//  make into odd number
		actualSegments = segments ;
		if ( n <= 3 ) {
			segments = 3 ;
			card = [ self emitGeometry:tagn segs:segments x1:tx1 y1:ty1 z1:tz1 x2:tx2 y2:ty2 z2:tz2 ] ;
			return [ NSArray arrayWithObjects:card, nil ] ;
		}
		//  break out center piece with 3 segments
		xo = ( tx1+tx2 )*0.5 ;
		yo = ( ty1+ty2 )*0.5 ;
		zo = ( tz1+tz2 )*0.5 ;
		factor = 1.5/n ;
		sx = factor*dx ;
		sy = factor*dy ;
		sz = factor*dz ;
		segments = 3 ;
		card = [ self emitGeometry:tagn segs:segments x1:xo-sx y1:yo-sy z1:zo-sz x2:xo+sx y2:yo+sy z2:zo+sz ] ;
		array = [ NSMutableArray arrayWithCapacity:3 ] ;
		[ array addObject:card ] ;
		[ array addObjectsFromArray:[ self taperedGeometryCards:NO tag:tagn+1 x1:tx1 y1:ty1 z1:tz1 x2:xo-sx y2:yo-sy z2:zo-sz ] ] ;
		[ array addObjectsFromArray:[ self taperedGeometryCards:NO tag:tagn+2 x1:xo+sx y1:yo+sy z1:zo+sz x2:tx2 y2:ty2 z2:tz2 ] ] ;
		return array ;
	}
	
	if ( n <= 1 ) {
		card = [ self emitGeometry:tagn segs:1 x1:tx1 y1:ty1 z1:tz1 x2:tx2 y2:ty2 z2:tz2 ] ;		// v0.51
		return [ NSArray arrayWithObjects:card, nil ] ;
	}
	//  find arithmetic progression: s0 + (n-1)*arith = s1 
	s0 = w*taper1 ;
	s1 = w*taper2 ;
	arith = ( s1 - s0 )/( n-1 ) ;
	excess = ( s0+s1 )*0.5*n - length ;
	s0 -= excess/n ;
	factor = s0/length ;
	sx = factor*dx ;
	sy = factor*dy ;
	sz = factor*dz ;
	array = [ NSMutableArray arrayWithCapacity:n ] ;
	factor = arith/length ;
	dx *= factor ;
	dy *= factor ;
	dz *= factor ;
	xo = tx1 ;
	yo = ty1 ;
	zo = tz1 ;
	for ( i = 0; i < n-1; i++ ) {
		xp = xo + sx ;
		yp = yo + sy ;
		zp = zo + sz ;
		card = [ self emitGeometry:tagn segs:1 x1:xo y1:yo z1:zo x2:xp y2:yp z2:zp ] ;
		[ array addObject:card ] ;
		xo = xp ;
		yo = yp ;
		zo = zp ;
		sx += dx ;
		sy += dy ;
		sz += dz ;
	}
	card = [ self emitGeometry:tagn segs:1 x1:xo y1:yo z1:zo x2:tx2 y2:ty2 z2:tz2 ] ;
	[ array addObject:card ] ;
	
	return array ;
}

- (NSArray*)geometryCards
{
	if ( tag <= 0 ) return [ NSArray array ] ;
	
	//  v0.48, v0.75a
	return [ self taperedGeometryCards:( feed != nil || [ arrayOfLoads count ] == 0 || arrayOfNetworks == nil ) tag:tag x1:end1.x y1:end1.y z1:end1.z x2:end2.x y2:end2.y z2:end2.z ] ;  // v0.51 changed from load == nil
}

@end
