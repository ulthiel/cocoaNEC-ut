//
//  AuxSWRView.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/20/11.
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

#import "AuxSWRView.h"
#import "ApplicationDelegate.h"
#import "NECOutput.h"
#import "SWRView.h"
#import <complex.h>

@implementation AuxSWRView

//  This does not use CGContext
- (void)drawPointAtX:(float)x y:(float)y radius:(float)r color:(NSColor*)color
{
    NSBezierPath *path ;
    
    [ color set ] ;
    path = [ NSBezierPath bezierPath ] ;
    [ path moveToPoint:NSMakePoint( x-r*1.6, y ) ] ;
    [ path lineToPoint:NSMakePoint( x+r*1.6, y ) ] ;
    [ path stroke ] ;
    path = [ NSBezierPath bezierPathWithOvalInRect:NSMakeRect( x-r*0.8, y-r*0.8, 1.6*r, 1.6*r ) ] ;
    [ path fill ] ;
    [ [ NSColor blackColor ] set ] ;
}

//  draw donut
//  This does not use CGContext
- (void)drawSelectedPointAtX:(float)x y:(float)y radius:(float)r color:(NSColor*)color
{
    NSBezierPath *path ;
    
    [ color set ] ;
    path = [ NSBezierPath bezierPath ] ;
    [ path moveToPoint:NSMakePoint( x-r*2.5, y ) ] ;
    [ path lineToPoint:NSMakePoint( x+r*2.5, y ) ] ;
    [ path stroke ] ;
    path = [ NSBezierPath bezierPathWithOvalInRect:NSMakeRect( x-r*1.2, y-r*1.2, 2.4*r, 2.4*r ) ] ;
    [ path fill ] ;
    [ [ NSColor whiteColor ] set ] ;
    path = [ NSBezierPath bezierPathWithOvalInRect:NSMakeRect( x-r*0.55, y-r*0.55, 1.1*r, 1.1*r ) ] ;
    [ path fill ] ;
    [ [ NSColor blackColor ] set ] ;
}


- (void)drawFeedpointCaptions
{
	float fontSize, height ;
	NSString *string ;
	NSDictionary *fontAttribute ;
	NSPoint point ;
	float zr, zx, z0, vswr, r, x, y, line[2], offset, textOffset ;
	complex double num, denom, rho ;
    int i, j, k ;
    intType show ;
	
	//  check if there is any data
	if ( currentFeedpoint == nil || currentFeedpoint->frequency < .001 || currentIndex < 0 || colorWell == nil ) return ;
	
	fontSize = 10.8*pow( opticalScale, 0.6 ) ;
	fontAttribute = [ NSDictionary dictionaryWithObject:[ NSFont fontWithName: @"Helvetica" size:fontSize ] forKey:NSFontAttributeName ] ;
	textOffset = 5.5*opticalScale ;

	height = [ self bounds ].size.height ;
	line[0] = height*0.68 ;
	line[1] = height*0.30 ;
	
	x = 20 ; 
	y = line[0] ;
	[ self drawSelectedPointAtX:29 y:y radius:3.5*opticalScale color:[ colorWell[currentIndex%16] color ] ] ;
	point = NSMakePoint( x+26, y-textOffset ) ;
	string = [ NSString stringWithFormat:@"Frequency : %.3f MHz", currentFeedpoint->frequency ] ; 
	[ string drawAtPoint:point withAttributes:fontAttribute ] ;
	
	//  Note: zr and zi are not normalized by z0
	zr = creal(z) ;
	zx = cimag(z) ;
	
	z0 = [ [ outputObject swrView ] z0 ] ;
	num = denom = z/z0 ;
	num -= 1, denom += 1 ;
	rho = num/denom ;
	r = cabs( rho ) ;
	vswr = ( r > 0.99 ) ? 99.0 : ( 1+r )/( 1-r ) ;
	
	y = line[1] ;
	point = NSMakePoint( x, y-textOffset ) ;
	string = ( zx >= 0 ) ? [ NSString stringWithFormat:@"Z = %.1f + i %.1f Ω (VSWR %.2f : 1)", zr, zx, vswr ] : [ NSString stringWithFormat:@"Z = %.1f - i %.1f ohms (VSWR %.2f : 1)", zr, -zx, vswr ] ;  //  v0.71 
	[ string drawAtPoint:point withAttributes:fontAttribute ] ;

	show = feedpoints ;
	if ( show > 1 && [ [ outputObject swrView ] showAllFeedpoints ] == YES ) {
		offset = [ self bounds ].size.width - 350 ;
		if ( show < 8 ) offset += ( 8-show )*45 - 10  ;		
		for ( k = 0; k < 2; k++ ) {
			for ( j = 0; j < 8; j++ ) {
				i = j + k*8 ;
				if ( i >= show ) break ;
				x = ( offset + j*36 ) ;
				y = line[k] ;
				[ self drawPointAtX:x+7 y:y radius:3.5*opticalScale color:[ colorWell[i%16] color ] ] ;
				string = [ NSString stringWithFormat:@"%d", i+1 ] ; 
				point = NSMakePoint( x+16, y-textOffset ) ;
				[ string drawAtPoint:point withAttributes:fontAttribute ] ;
			}
		}
	}
}

- (float)makeOpticalScale:(NSRect)bounds
{
	opticalScale = sqrt( bounds.size.height/52.0 ) ;
	if ( opticalScale < 1.0 ) opticalScale = 1.0 ;
	return opticalScale ;
}

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *path ;
	NSRect bounds ;
	
	bounds = [ self bounds ] ;
	
	path = [ NSBezierPath bezierPathWithRect:bounds ] ;
	[ [ NSColor whiteColor ] set ] ;
	[ path fill ] ;
	if ( [ [ [ NSApp delegate ] output ] drawBorders ] ) {
		[ [ NSColor blackColor ] set ] ;
		[ path stroke ] ;
	}
	[ self makeOpticalScale:bounds ] ;
	
	isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
	[ self drawFeedpointCaptions ] ;
}

- (void)show:(FeedpointCache*)current index:(intType)index z:(complex double)zp colors:(NSColorWell**)plotColorWells feedpoints:(intType)n
{
	currentFeedpoint = current ;
	colorWell = plotColorWells ;
	currentIndex = index ;
	feedpoints = n ;
	z = zp ;
	[ self setNeedsDisplay:YES ] ;
}

- (id)initWithFrame:(NSRect)frame 
{
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		currentIndex = -1 ;
		colorWell = nil ;
		opticalScale = 1 ;
	}
	return self ;
}

- (void)dealloc
{
	[ super dealloc ] ;
}

@end
