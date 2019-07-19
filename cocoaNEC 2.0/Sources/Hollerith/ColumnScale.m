//
//  ColumnScale.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/20/07.
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

#import "ColumnScale.h"


@implementation ColumnScale

- (id)initWithFrame:(NSRect)inFrame 
{
	NSSize size ;

    self = [ super initWithFrame:inFrame ] ;
    if ( self ) {
	
		frame = inFrame ;
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;
		
		scale = nil ;
		[ self setGrid:( 7.80127+1.085449 ) ] ;  // advance and leading
	}
	return self ;
}

- (void)setGrid:(float)advance
{
	float x, t, base, longTick, shortTick, mediumTick, tick ;
	int i, n ;
	
	advance *= ( 72.0/80.0 ) ;
	
	x = 4 ;
	base = 0 ;
	shortTick = height*0.25 ;
	mediumTick = height*0.45 ;
	longTick = height*0.7 ;
	
	if ( scale ) [ scale release ] ;		
	scale = [ [ NSBezierPath alloc ] init ] ;
	[ scale setLineWidth: 0.5 ] ;
	for ( i = 0; i < 81; i++ ) {
		tick = shortTick ;
		if ( ( i % 10 ) == 0 ) tick = longTick ; 
		else {
			if ( i < 20 && ( i%5 ) == 0 ) tick = mediumTick ;
		}
		n = x + 0.5 ;
		t = n + 0.5 ;
		[ scale moveToPoint:NSMakePoint( t, base ) ] ;
		[ scale lineToPoint:NSMakePoint( t, tick ) ] ;
		x += advance ;
	}
	[ self setNeedsDisplay:YES ] ;
}

- (void)drawRect:(NSRect)frame
{
	if ( [ self lockFocusIfCanDraw ] ) {
		//  insert scale
		[ [ NSColor blackColor ] set ] ;
		[ scale stroke ] ;
		[ self unlockFocus ] ;
	}
}

@end
