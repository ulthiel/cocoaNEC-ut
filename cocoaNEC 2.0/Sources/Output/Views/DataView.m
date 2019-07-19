//
//  DataView.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/7/11.
//	-----------------------------------------------------------------------------
//  Copyright 2011-2016 Kok Chen, W7AY. 
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

#import "DataView.h"
#import "Feedpoint.h"


@implementation DataView

- (id)initWithFrame:(NSRect)rect
{
	self = [ super initWithFrame:rect ] ;
	if ( self ) {
        outputContext = nil ;
		selectedFeedpointNumber = 0 ;
		offscreenFeedpointMenuIndex = -1 ;
		numberOfFeedpoints = numberOfFrequencies = 0 ;
		refFeedpoint.feedpoints = 0 ;
		z0 = 50.0 ;
		opticalScale = 1 ;
		white = [ [ NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1.0 ] retain ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ white release ] ;
	[ super dealloc ] ;
}

- (void)setInterpolate:(Boolean)state
{
	[ interpolateCheckbox setState:( ( state ) ? NSOnState : NSOffState ) ] ;
}

- (Boolean)doInterpolate
{
	if ( outputObject == nil ) return NO ;
	return ( [ interpolateCheckbox state ] == NSOnState ) ;
}

- (float)makeOpticalScale:(NSRect)bounds
{
	opticalScale = sqrt( bounds.size.height/591.0 ) ;
	if ( opticalScale < 1.0 ) opticalScale = 1.0 ;
	return opticalScale ;
}
- (float)z0
{
	return z0 ;
}

- (void)drawPoint:(PDFConsumer*)p x:(float)x y:(float)y radius:(float)r
{
    [ p fillDisk:r*0.8 x:x y:y ] ;
}

//  draw donut
- (void)drawSelectedPoint:(PDFConsumer*)p x:(float)x y:(float)y radius:(float)r
{
    [ p fillDisk:r*1.2 x:x y:y ] ;
	//  hole in donut
	[ p save ] ;
	[ p setRGB:donutHoleColor ] ;
    [ p fillDisk:r*0.55 x:x y:y ] ;
	[ p restore ] ;	// restore RGB color
}

//  (Private API)
- (intType)setCacheToClosestFrequency:(intType)feedpointMenuIndex previousCache:(FeedpointCache*)previous
{
	FeedpointCache target ;
	float diff, smallestDiff ;
	int i, index ;

	smallestDiff = 1e9 ;
	index = 0 ;
	for ( i = 0; i < numberOfFrequencies; i++ ) {
		diff = fabs( feedpointList[i].frequency - previous->frequency ) ;
		if ( diff < smallestDiff ) {
			index = i ;
			smallestDiff = diff ;
		}
	}
	target.frequencies = numberOfFrequencies ;
	target.frequencyIndex = index ;
	target.frequency = feedpointList[index].frequency ;
	target.feedpointNumber = feedpointMenuIndex ;
	[ outputContext setFeedpointCache:&target feedpointNumber:feedpointMenuIndex ] ;
	return feedpointMenuIndex ;
}

- (void)updateFeedpointFromOutputContext
{
	FeedpointCache target, *previous ;
	intType i, feedpointMenuIndex ;
	
	//  First check to see if there is an outputContext
	if ( outputContext == nil ) return ;
	
	feedpointMenuIndex = [ self selectedFeedpointFromMenu ] ;
	target = *[ outputContext feedpointCache:feedpointMenuIndex ] ;
	previous = [ outputContext selectedFeedpointCache ] ;
	
	if ( previous->frequency < 0.001 ) {
		//  no previous selection, choose "middle" frequency
		target.feedpointNumber = feedpointMenuIndex ;
		target.frequencies = numberOfFrequencies ;
		//	Use the midpoint of the sweep
		target.frequencyIndex = ( numberOfFrequencies-1 )/2 ;
		if ( target.frequencyIndex < 0 ) target.frequencyIndex = 0 ;
		target.frequency = feedpointList[target.frequencyIndex].frequency ;
		[ outputContext setFeedpointCache:&target feedpointNumber:feedpointMenuIndex ] ;
		return ;
	}
	if ( previous->feedpointNumber != feedpointMenuIndex ) {
		//  feedpoint changed; switch to the point with the same frequency
		target.feedpointNumber = feedpointMenuIndex ;
		target.frequencies = numberOfFrequencies ;
		target.frequencyIndex = previous->frequencyIndex ;
		target.frequency = feedpointList[target.frequencyIndex].frequency ;
		[ outputContext setFeedpointCache:&target feedpointNumber:feedpointMenuIndex ] ;
		return ;
	}
	//  check if previous frequency still exists in list
	for ( i = 0; i < numberOfFrequencies; i++ ) {
		if ( fabs( feedpointList[i].frequency - previous->frequency ) < 0.01 ) break ;
	}
	if ( i >= numberOfFrequencies ) {
		//  previous frequency vanished, find selection closest to previous frequency
		[ self setCacheToClosestFrequency:feedpointMenuIndex previousCache:previous ] ;
		return ;
	}	
	//  feedpoint number remains the same and previous frequency exist, reuse cache if possible
	if ( target.frequency > 0.001 && target.frequencies == numberOfFrequencies && target.frequencyIndex == previous->frequencyIndex && target.feedpointNumber == previous->feedpointNumber ) return ; 
	//  otherwise, find selection closest to previous frequency
	[ self setCacheToClosestFrequency:feedpointMenuIndex previousCache:previous ] ;
}
	
//	index of selected feedpoint in popup
//	return -1 if no feedpoint selected
- (intType)selectedFeedpointFromMenu
{
	intType index ;
	
	if ( feedPoint == nil ) {
		//  no menu for feedpoint, probably an offscreen view
		return offscreenFeedpointMenuIndex ;
	}
	index = [ feedPoint indexOfSelectedItem ] ;
	if ( index < 0 ) return -1 ;
	return index ;
}

- (void)setFeedpointForOffscreenView:(intType)index
{
	offscreenFeedpointMenuIndex = index ;
}

- (intType)setupFeedpointMenu
{
	int i ;
	
	if ( outputContext != nil && numberOfFeedpoints > 0 ) {
		if ( numberOfFeedpoints != [ feedPoint numberOfItems ] ) {
			[ feedPoint removeAllItems ] ;
			for ( i = 0; i < numberOfFeedpoints; i++ ) {
				[ feedPoint addItemWithTitle:[ NSString stringWithFormat:@"%d", i+1 ] ] ;
			}
		}
		[ feedPoint setEnabled:YES ] ;
		return numberOfFeedpoints ;
	}
	[ feedPoint removeAllItems ] ;
	[ feedPoint setEnabled:NO ] ;
	return 0 ;
}

//  array is an array of arrays of feedpoints
- (void)updateWithContext:(OutputContext*)inOutputContext refContext:(OutputContext*)refContext z0:(float)refz
{
    int i, j ;
    intType n ;
	NSArray *array, *arrayOfFeedpoints, *refFeedpoints ;
	Feedpoint *feedpoint ;
	FeedpointInfo *feedpointInfo ;
	
	z0 = refz ;
	outputContext = inOutputContext ;
	if ( outputContext == nil ) return ;
	arrayOfFeedpoints = [ outputContext arrayOfFeedpoints ] ;	//  v0.70 get feedpoints of current OutputContext
	
	numberOfFrequencies = [ arrayOfFeedpoints count ] ;
	if ( numberOfFrequencies > MAXSWEEP ) numberOfFrequencies = MAXSWEEP ;
	
	for ( j = 0; j < numberOfFrequencies; j++ ) {
		array = [ arrayOfFeedpoints objectAtIndex:j ] ;
		numberOfFeedpoints = ( array == nil ) ? 0 : [ array count ] ;
		if ( numberOfFeedpoints > MAXFEEDPOINTS ) numberOfFeedpoints = MAXFEEDPOINTS ;
		feedpointList[j].feedpoints = numberOfFeedpoints ;
		for ( i = 0; i < numberOfFeedpoints; i++ ) {
			feedpoint = [ array objectAtIndex:i ] ;
			feedpointInfo = [ feedpoint info ] ;
			feedpointList[j].zr[i] = feedpointInfo->zr/z0 ;
			feedpointList[j].zx[i] = feedpointInfo->zi/z0 ;
			feedpointList[j].frequency = feedpointInfo->frequency ;
		}
	}
	//	get reference, if asked for
	n = 0 ;
    refFeedpoints = nil ;
	if ( refContext == outputContext ) {
		if ( refContext != nil ) {
			//  use previous feedpoint array of output context
			refFeedpoints = [ outputContext previousFeedpointArray ] ;
			n = [ refFeedpoints count ] ;
		}
	}
	else {
		//  use first feedpoint array from reference context
		refFeedpoints = [ [ refContext arrayOfFeedpoints ] objectAtIndex:0 ] ;
		n = [ refFeedpoints count ] ;
	}
	if ( n > 0 ) {
		if ( n > 16 ) n = 16 ;
		refFeedpoint.feedpoints = n ;
        if ( refFeedpoints != nil ) {
            for ( i = 0; i < n; i++ ) {
                feedpoint = [ refFeedpoints objectAtIndex:i ] ;
                feedpointInfo = [ feedpoint info ] ;
                refFeedpoint.zr[i] = feedpointInfo->zr/z0 ;
                refFeedpoint.zx[i] = feedpointInfo->zi/z0 ;
                refFeedpoint.frequency = feedpointInfo->frequency ;
            }
        }
	}
	[ self setNeedsDisplay:YES ] ;
}

//	bilinear transform of z0-normalized R + jX to normalized U + jV
void RXtoUV( float r, float x, float *u, float *v )
{
    float d ;
    
    d = r*r + x*x + r*2 + 1 ;
    *u = ( r*r+ x*x - 1 )/d ;
    *v = ( x*2 )/d ;
}

//  inverse bilinear transform from z0-normalized U +jV, with result in normalized R + jX
void UVtoRX( float u, float v, float *r, float *x )
{
	float d ;
	
	d = (1-u)*(1-u) + v*v ;
	if ( d < 1e-12 ) d = 1e-12 ;
	*r = ( (1+u)*(1-u)-v*v )/d ;
	*x = v*2/d ;
}

//	simple bubble sort since N is seldom large
- (void)sort:(RXF*)data samples:(int)n
{
	Boolean changed ;
	RXF *sorted ;
	int i, j, p, q, t, map[4096] ;
	
	//  initialize sort mapping
	for ( i = 0; i < n; i++ ) map[i] = i ;
		
	for ( j = 0; j < n; j++ ) {
		changed = NO ;
		for ( i = 0; i < n-1; i++ ) {
			p = map[i] ;
			q = map[i+1] ;
			if ( data[p].frequency > data[q].frequency ) {
				t = p ;
				map[i] = q ;
				map[i+1] = p ;
				changed = YES ;
			}
		}
		if ( changed == NO ) break ;
	}
	//  sort through mapping and then copy back into input
	sorted = (RXF*)malloc( sizeof(RXF)*n ) ;
	for ( i = 0; i < n; i++ ) sorted[i] = data[ map[i] ] ;
	for ( i = 0; i < n; i++ ) data[i] = sorted[i] ;
	free( sorted ) ;
}

//	override in SWRView and ScalarView
- (Boolean)mouseDownInner:(NSEvent*)event
{
	return YES ;
}

- (void)mouseDown:(NSEvent*)event
{
	if ( [ self mouseDownInner:event ] == NO ) NSBeep() ;
	[ super mouseDown:event ] ;
}

//  distance between two NSPoints
float pointDist( NSPoint a, NSPoint b )
{
	float dx, dy ;
	
	dx = a.x - b.x ;
	dy = a.y - b.y ;
	return sqrt( dx*dx + dy*dy ) ;
}

@end
