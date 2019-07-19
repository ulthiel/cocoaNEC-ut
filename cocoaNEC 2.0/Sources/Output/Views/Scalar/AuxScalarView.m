//
//  AuxScalarView.m
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

#import "AuxScalarView.h"
#import "ApplicationDelegate.h"
#import "NECOutput.h"
#import <complex.h>

@implementation AuxScalarView

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *background, *frame, *line ;
	NSString *label, *typeString ;
	NSRect bounds, freqStrip ;
	Boolean isScreen ;
	float i, limit, f, x, y, hscale, zr, zx, vswr, rho, rl, fontSize, line1, line2, dx ;
	const floatType dash[2] = { 4, 2 } ;
	complex double z, num, denom, gamma ;
	NSDictionary *captionAttributes, *rxAttributes ;
	
	isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
	if ( !isScreen && drawInfoForOffScreen == NO ) return ;
	
	if ( isScreen ) {
		hasBackground = YES ;
		fontAttributes = fontAttributesWithBackground ;
	}
	else {
		hasBackground = [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBackgrounds ] ;
		fontAttributes = ( hasBackground ) ? fontAttributesWithBackground : fontAttributesNoBackground ;
	}
	
	bounds = [ self bounds ] ;
	freqStrip = bounds = [ self bounds ] ;
	freqStrip.size.height = 16 ;
	freqStrip.origin.y = bounds.size.height-freqStrip.size.height ;
	
	background = [ NSBezierPath bezierPathWithRect:freqStrip ] ;
	if ( isScreen || [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBackgrounds ] ) {
		//  fill background
		[ backgroundColor set ] ;
		[ background fill ] ; 
	}
	else {
		//  draw border around frequency string
		[ [ NSColor blackColor ] set ] ;
		[ background stroke ] ;
	}
	if ( isScreen || [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBorders ] ) {
        float by = (int)( bounds.origin.y ) + 0.5 ;
		//  frame the caption rectangle (ignore top horizontal line (made up by frequency strip)
		frame = [ NSBezierPath bezierPath ] ;
		[ frame moveToPoint:NSMakePoint( freqStrip.origin.x, freqStrip.origin.y ) ] ;
		[ frame lineToPoint:NSMakePoint( freqStrip.origin.x, by ) ] ;
		[ frame lineToPoint:NSMakePoint( bounds.size.width, by ) ] ;
		[ frame lineToPoint:NSMakePoint( bounds.size.width, freqStrip.origin.y ) ] ;
		[ [ NSColor blackColor ] set ] ;
		[ frame stroke ] ;
	}
	if ( plotInfo != nil ) {
		y = freqStrip.origin.y+1 ;
		limit = freqStrip.size.width - 50 ;
		[ @"MHz" drawAtPoint:NSMakePoint( limit+15, y ) withAttributes:fontAttributes ] ;
		hscale = plotInfo->width/( plotInfo->maxFreq - plotInfo->minFreq ) ;
		f = plotInfo->firstFrequencyLabel ;
		for ( i = 0; i < 12; i++ ) {
			label = [ NSString stringWithFormat:plotInfo->labelFormat, f ] ;
			x = ( f - plotInfo->minFreq )*hscale - [ label length ]*3.1 ;	//  moderately center the string
			if ( x > limit-28 ) break ;
			if ( x > 12 ) [ label drawAtPoint:NSMakePoint( x, y ) withAttributes:fontAttributes ] ;
			f += plotInfo->frequencyLabelGrid ;
		}
	}
	if ( rxf != nil ) {	
		f =  bounds.size.height/68.0 ;
		fontSize = 10.2*pow(f, 0.2 ) ;
		captionAttributes = [ NSDictionary dictionaryWithObject:[ NSFont systemFontOfSize:fontSize ] forKey:NSFontAttributeName ] ;

		line1 = 33*f - 4 ;
		line2 = 22*f - 11 ;
		
		label = [ NSString stringWithFormat:@"Frequency: %.3f MHz", rxf->frequency ] ;
		[ label drawAtPoint:NSMakePoint( 15, line1 ) withAttributes:captionAttributes ] ;
		
		zr = rxf->rx.x ;
		zx = rxf->rx.y ;
		z = ( zr + zx*(0.0+1.0fj) ) ;
		num = denom = z ;
        num -= 1;
        denom += 1 ;
		gamma = num/denom ;
		rho = cabs( gamma ) ;
		vswr = ( rho > 0.99 ) ? 99.0 : ( 1+rho )/( 1-rho ) ;
		
		if ( drawInfoForOffScreen ) {
			if ( plotType == kRXPlotType && mainColor && altColor ) {
				if ( hasBackground ) {
					[ backgroundColor set ] ;
					background = [ NSBezierPath bezierPathWithRect:NSMakeRect( 15, line2-3, 110, 17 ) ] ;
					[ background fill ] ;
					dx = 8 ;
					rxAttributes = fontAttributesWithBackground ;
				}
				else {
					dx = 0 ;
					rxAttributes = captionAttributes ;
				}
				[ @"R" drawAtPoint:NSMakePoint( 15+dx, line2 ) withAttributes:rxAttributes ] ;
				[ @"X" drawAtPoint:NSMakePoint( 70+dx, line2 ) withAttributes:rxAttributes ] ;
	
				line = [ NSBezierPath bezierPath ] ;
				[ line setLineWidth:1.4 ] ;
				[ mainColor set ] ;
				[ line moveToPoint:NSMakePoint( 30+dx, line2+5 ) ] ;
				[ line lineToPoint:NSMakePoint( 53+dx, line2+5 ) ] ;
				[ line stroke ] ;
				line = [ NSBezierPath bezierPath ] ;
				[ line setLineWidth:1.4 ] ;
				[ altColor set ] ;
				[ line moveToPoint:NSMakePoint( 85+dx, line2+5 ) ] ;
				[ line lineToPoint:NSMakePoint( 108+dx, line2+5 ) ] ;
				[ line setLineDash:dash count:2 phase:0 ] ;
				[ line stroke ] ;
			}
			else {
				switch ( plotType ) {
				default:
					typeString = @"" ;
					break ;
				case kImpedancePlotType:
					typeString = @"|Z| Plot" ;
					break ;
				case kSWRPlotType:
					typeString = @"VSWR Plot" ;
					break ;
				case kReturnLossPlotType:
					typeString = @"Return Loss Plot" ;
					break ;
				}
				[ typeString drawAtPoint:NSMakePoint( 15, line2 ) withAttributes:captionAttributes ] ;
			}
		}
		label = ( zx >= 0 ) ? [ NSString stringWithFormat:@"Z = %.1f + i %.1f Ω", zr*z0, zx*z0 ] : [ NSString stringWithFormat:@"Z = %.1f - i %.1f Ω", zr*z0, -zx*z0 ] ; 
		[ label drawAtPoint:NSMakePoint( 200, line1 ) withAttributes:captionAttributes ] ;

		label = [ NSString stringWithFormat:@"VSWR %.2f : 1", vswr ] ;
		[ label drawAtPoint:NSMakePoint( 390, line1 ) withAttributes:captionAttributes ] ;
	
		label = [ NSString stringWithFormat:@"|Z| = %.1f Ω", cabs( z )*z0 ] ;
		[ label drawAtPoint:NSMakePoint( 200, line2 ) withAttributes:captionAttributes ] ;
	
		if ( rho < 1e-40 ) rho = 1e-40 ;
		rl = 20.0*log10( rho ) ;
		label = [ NSString stringWithFormat:@"Return loss = %.1f dB", -rl ] ;
		[ label drawAtPoint:NSMakePoint( 390, line2 ) withAttributes:captionAttributes ] ;		
	}
}

- (void)label:(PlotInfo*)scale
{
	plotInfo = ( scale != nil && scale->hasData == YES ) ? scale : nil ;
}

- (void)setCaptionWithRXF:(RXF*)rp z0:(float)z plotType:(intType)n mainColor:(NSColor*)mainc altColor:(NSColor*)altc
{
	rxf = rp ;
	z0 = z ;
	plotType = n ;
	mainColor = mainc ;
	altColor = altc ;
}

- (id)initWithFrame:(NSRect)frame 
{
	NSFont *font ;
	
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		z0 = 50 ;
		plotType = 0 ;
		rxf = nil ;
		plotInfo = nil ;
		backgroundColor = [ [ NSColor colorWithCalibratedRed:0 green:0.1 blue:0 alpha:1 ] retain ] ;
		textColor = [ [ NSColor colorWithCalibratedRed:0 green:1 blue:0.5 alpha:0.8 ] retain ] ;
		//  font with color
		font = [ NSFont systemFontOfSize: 10.8 ] ;
		fontAttributes = fontAttributesWithBackground = [ [ NSMutableDictionary alloc ] init ] ;
		[ fontAttributesWithBackground setObject:font forKey:NSFontAttributeName ] ;
		[ fontAttributesWithBackground setObject:textColor forKey:NSForegroundColorAttributeName ] ;
		//  black font
		fontAttributesNoBackground = [ [ NSMutableDictionary alloc ] init ] ;
		[ fontAttributesWithBackground setObject:font forKey:NSFontAttributeName ] ;
		//  plot colors (updated by setCaptionWithRXF)
		mainColor = altColor = nil ;
	}
	return self ;
}

- (void)dealloc
{
	[ backgroundColor release ] ;
	[ textColor release ] ;
	[ fontAttributesWithBackground release ] ;
	[ fontAttributesNoBackground release ] ;
	[ super dealloc ] ;
}

@end
