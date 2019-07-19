//
//  Aux3dView.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/21/11.
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

#import "Aux3dView.h"
#import "ApplicationDelegate.h"
#import "NECOutput.h"
#import "Pattern3dView.h"

@implementation Aux3dView

- (void)drawRect:(NSRect)rect
{
	NSBezierPath *framePath ;
	NSRect bounds ;
	NSString *string ;
	NECOutput *output ;
	Pattern3dView *base ;
	
	if ( [ NSGraphicsContext currentContextDrawingToScreen ] == YES ) return ;
	
	bounds = [ self bounds ] ;
	framePath = [ NSBezierPath bezierPathWithRect:bounds ] ;
	//  clear area and frame it  
	[ [ NSColor whiteColor ] set ] ; 
	[ framePath fill ] ; 
	output = [ [ NSApp delegate ] output ] ;
	if ( output ) {
		if ( [ output drawBorders ] ) {
			[ [ NSColor blackColor ] set ] ; 
			[ framePath stroke ] ;
		}
		base = [ output pattern3dView ] ;
		if ( base ) {
			string = [ NSString stringWithFormat:@"Azimuth angle = %.0f degrees", [ base angle ] ] ;
			[ string drawAtPoint:NSMakePoint( 8, [ self bounds ].size.height - 20 ) withAttributes:[ output mediumFontAttributes ] ] ;
		}
	}
}

@end
