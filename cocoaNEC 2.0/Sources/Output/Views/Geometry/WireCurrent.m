//
//  WireCurrent.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/15/12.
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

#import "WireCurrent.h"

@implementation WireCurrent


- (id)initWithFrame:(NSRect)inFrame
{
    self = [ super initWithFrame:inFrame ] ;
	if ( self ) {
		isActive = NO ;
		geometryArray = nil ;
		currentTypeMenu = nil ;
		backgroundColor = [ [ NSColor colorWithCalibratedRed:0 green:0.1 blue:0 alpha:1 ] retain ] ;
		gridColor = [ [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:0.9 ] retain ] ;
		plotColor = [ [ NSColor colorWithCalibratedRed:0.9 green:0.8 blue:0 alpha:1 ] retain ] ;
		alphaColor = [ [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:0.2 ] retain ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ backgroundColor release ] ;
	[ gridColor release ] ;
	[ plotColor release ] ;
	[ alphaColor release ] ;
	if ( geometryArray != nil ) [ geometryArray release ] ;
	[ super dealloc ] ;
}

- (Boolean)active
{
	return isActive ;
}

- (void)setActive:(Boolean)state
{
	isActive = state ;
}

- (void)typeChanged:(id)sender
{
	[ self setNeedsDisplay:YES ] ;
}

- (void)awakeFromNib
{
	NSWindow *window ;
	
	[ currentTypeMenu setAction:@selector(typeChanged:) ] ;
	[ currentTypeMenu setTarget:self ] ;
	window = [ self window ] ;
	[ window setDelegate:self ] ;
	[ window setHidesOnDeactivate:NO ] ;
	[ window setLevel:NSNormalWindowLevel ] ;
}

- (void)newInfo:(GeometryInfo*)segment array:(NSArray*)inGeometryArray
{
	OutputGeometryElement *element ;
	GeometryInfo *info ;
	NSArray *temp ;
	
	if ( inGeometryArray != nil ) {
		// cache geometry array locally
		temp = geometryArray ;
		geometryArray = [ [ NSArray alloc ] initWithArray:inGeometryArray ] ;
		if ( temp != nil ) [ temp release ] ;

		element = [ geometryArray objectAtIndex:0 ] ;
		info = [ element info ] ;
		segmentOffset = segment->segment - info->segment ;
	}
	if ( isActive ) {
		[ [ self window ] orderFront:nil ] ;
		isActive = YES ;
		[ self setNeedsDisplay:YES ] ;
	}
}

- (void)hideWindow
{
	NSWindow *window ;

	window = [ self window ] ;
	[ window orderOut:nil ] ;
}

//	delegate of NSWindow
- (void)windowWillClose:(NSNotification *)notification
{
	isActive = NO ;
}

- (void)drawMagnitude:(NSRect)bounds
{
	intType i, count ;
	OutputGeometryElement *element ;
	GeometryInfo *info ;
	NSBezierPath *magPath, *phasePath, *gridPath, *pointPath ;
	NSPoint point ;
	CGFloat dash[2] = { 2, 2 }, gridDash[2] = { 1, 2 } ;
	float offset, xScale, yScale, pScale, gScale, x, y ;

	if ( geometryArray == nil ) return ;
	count = [ geometryArray count ] ;
	if ( count <= 0 ) return ;
	
	offset = 3 ;
	xScale = ( bounds.size.width-offset*2 )/( count ) ;
	yScale = ( bounds.size.height-offset*2 ) ;
	pScale = ( bounds.size.height-offset*2 )/360.0 ;
	gScale = ( bounds.size.width-offset*2 ) ;
	
	gridPath = [ NSBezierPath bezierPath ] ;
	[ gridPath setLineWidth:0.4 ] ;
	[ gridPath setLineDash:gridDash count:2 phase:0 ] ;
	x = ( int )( bounds.size.width-offset ) + 0.5 ;
	for ( i = 0; i < 9; i++ ) {
		y = ( int )( yScale*i/8.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( offset, y ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	//  double strike 0 major grids
	for ( i = 0; i < 5; i += 2 ) {
		y = ( int )( yScale*i/4.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( offset, y ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	[ gridColor set ] ;
	[ gridPath stroke ] ;
	gridPath = [ NSBezierPath bezierPath ] ;
	[ gridPath setLineWidth:0.4 ] ;
	[ gridPath setLineDash:gridDash count:2 phase:0 ] ;
	y = ( int )( bounds.size.height - offset ) + 0.5 ;
	for ( i = 0; i < 9; i++ ) {
		x = ( int )( gScale*i/8.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( x, offset ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	[ gridColor set ] ;
	[ gridPath stroke ] ;
	
	magPath = [ NSBezierPath bezierPath ] ;
	[ magPath setLineWidth:1.0 ] ;
	phasePath = [ NSBezierPath bezierPath ] ;
	[ phasePath setLineDash:dash count:2 phase:0 ] ;
	[ phasePath setLineWidth:0.9 ] ;
	for ( i = 0; i < count; i++ ) {
		element = [ geometryArray objectAtIndex:i ] ;
		info = [ element info ] ;
		x = ( i+0.5 )*xScale+offset ;
		point = NSMakePoint( x, info->current*yScale+offset ) ;
		if ( i == 0 ) [ magPath moveToPoint:point ] ; else [ magPath lineToPoint:point ] ;
		point = NSMakePoint( x, ( info->phase + 180.0 )*pScale+offset ) ;
		if ( i == 0 ) [ phasePath moveToPoint:point ] ; else [ phasePath lineToPoint:point ] ;
	}
	[ plotColor set ] ;
	[ magPath stroke ] ;
	[ phasePath stroke ] ;
	
	pointPath = [ NSBezierPath bezierPathWithRect:NSMakeRect( segmentOffset*xScale+offset, offset, gScale/(count), yScale ) ] ;
	[ alphaColor set ] ;
	[ pointPath fill ] ;
}

- (void)drawComplex:(NSRect)bounds
{
	intType i, count ;
	OutputGeometryElement *element ;
	GeometryInfo *info ;
	NSBezierPath *magPath, *phasePath, *gridPath, *pointPath ;
	NSPoint point ;
	CGFloat dash[2] = { 2, 2 }, gridDash[2] = { 1, 2 } ;
	float offset, dcoffset, xScale, yScale, zScale, gScale, x, y ;

	if ( geometryArray == nil ) return ;
	count = [ geometryArray count ] ;
	if ( count <= 0 ) return ;
	
	offset = 3 ;
	xScale = ( bounds.size.width-offset*2 )/( count ) ;
	yScale = ( bounds.size.height-offset*2 ) ;
	gScale = ( bounds.size.width-offset*2 ) ;
	dcoffset = bounds.size.height*0.5 ;
	
	gridPath = [ NSBezierPath bezierPath ] ;
	[ gridPath setLineWidth:0.4 ] ;
	[ gridPath setLineDash:gridDash count:2 phase:0 ] ;
	x = ( int )( bounds.size.width-offset ) + 0.5 ;
	for ( i = 0; i < 9; i++ ) {
		y = ( int )( yScale*i/8.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( offset, y ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	//  double strike 0 major grids
	for ( i = 0; i < 5; i += 2 ) {
		y = ( int )( yScale*i/4.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( offset, y ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	[ gridColor set ] ;
	[ gridPath stroke ] ;
	gridPath = [ NSBezierPath bezierPath ] ;
	[ gridPath setLineWidth:0.4 ] ;
	[ gridPath setLineDash:gridDash count:2 phase:0 ] ;
	y = ( int )( bounds.size.height - offset ) + 0.5 ;
	for ( i = 0; i < 9; i++ ) {
		x = ( int )( gScale*i/8.0 + offset ) + 0.5 ;
		[ gridPath moveToPoint:NSMakePoint( x, offset ) ] ; 
		[ gridPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	[ gridColor set ] ;
	[ gridPath stroke ] ;
	
	magPath = [ NSBezierPath bezierPath ] ;
	[ magPath setLineWidth:1.0 ] ;
	phasePath = [ NSBezierPath bezierPath ] ;
	[ phasePath setLineDash:dash count:2 phase:0 ] ;
	[ phasePath setLineWidth:0.9 ] ;
	
	element = [ geometryArray objectAtIndex:0 ] ;
	info = [ element info ] ;
	zScale = yScale*0.5/info->maxCurrent ;
	
	for ( i = 0; i < count; i++ ) {
		element = [ geometryArray objectAtIndex:i ] ;
		info = [ element info ] ;
		x = ( i+0.5 )*xScale+offset ;
		point = NSMakePoint( x, info->real*zScale+dcoffset ) ;
		if ( i == 0 ) [ magPath moveToPoint:point ] ; else [ magPath lineToPoint:point ] ;
		point = NSMakePoint( x, info->imag*zScale+dcoffset ) ;
		if ( i == 0 ) [ phasePath moveToPoint:point ] ; else [ phasePath lineToPoint:point ] ;
	}
	[ plotColor set ] ;
	[ magPath stroke ] ;
	[ phasePath stroke ] ;
	
	pointPath = [ NSBezierPath bezierPathWithRect:NSMakeRect( segmentOffset*xScale+offset, offset, gScale/(count), yScale ) ] ;
	[ alphaColor set ] ;
	[ pointPath fill ] ;
}

- (void)drawRect:(NSRect)rect
{
	NSBezierPath *background ;
	NSRect bounds ;
	
	bounds = [ self bounds ] ;
	//  draw background
	background = [ NSBezierPath bezierPath ] ;
	[ background appendBezierPathWithRect:bounds ] ;
	[ backgroundColor set ] ;
	[ background fill ] ;
	
	if ( [ currentTypeMenu indexOfSelectedItem ] == 0 ) [ self drawMagnitude:bounds ] ; else [ self drawComplex:bounds ] ;
}

@end
