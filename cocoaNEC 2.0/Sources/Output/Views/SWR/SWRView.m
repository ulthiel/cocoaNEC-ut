//
//  SWRView.m
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

#import "SWRView.h"
#import "ApplicationDelegate.h"
#import "CubicUV.h"
#import "Feedpoint.h"
#import "NECOutput.h"
#include <complex.h>

@implementation SWRView

@synthesize colorWindow ;

//  Adapted from Marshall Jose's Postscript code.
//  ---------------------------------------------

static float ZRegions[]  = { 0,     0.2,   0.5,   1,     2,     5,    10,    20,    50 } ;
static float ZMinordiv[] = { 0.01,  0.02,  0.05,  0.1,   0.2,   1,     2,    10 } ;
static int   ZMajordiv[] = { 5,     5,     2,     2,     5,     5,     5,    5 } ;

#define	Unitradius ( 2.5*80 )
#define	Rad	   ( 180.0/3.1415926 )

#define THIN			( 0.18 )
#define THICK			( 0.65 )
#define	CIRCUMFERENCE	( 0.35 )

#define	pi2	( 3.1415926535*2.0 )

static float minorinc ;
static int majorinc ;

- (id)initWithFrame:(NSRect)rect
{
	self = [ super initWithFrame:rect ] ;
	if ( self ) {
		currentLinewidth = THICK ;
		swrCircle = 2.0 ;
		center = NSMakePoint( 0, 0 ) ;
		//  v0.64 -- moved outside loop, was assigning 16 times!
		refColor = [ [ NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1 ] retain ] ;
		refCenterColor = [ [ NSColor colorWithDeviceRed:0.25 green:0.25 blue:0.25 alpha:1 ] retain ] ;
	}
	return self ;
}

//	v0.64
- (void)dealloc
{
	[ refColor release ] ;
	[ refCenterColor release ] ;
	[ super dealloc ] ;
}

static float AngR( float ra, float xa )
{
    float u, v ;
    
    RXtoUV( ra, xa, &u, &v ) ;
    return atan2( v, ( u-ra/( ra+1 ) ) ) ;
}

static float AngX( float ra, float xa )
{
    float u, v ;
    
    RXtoUV( ra, xa, &u, &v ) ;
    return atan2( ( v-1/xa ), ( u-1 ) ) ; 
}

static void DrawArc( PDFConsumer *p, float u0, float v0, float radius, float theta1, float theta2 )
{    
    [ p arc:u0*Unitradius y:v0*Unitradius r:radius*Unitradius t0:theta1 t1:theta2 ] ;
    [ p stroke ] ;
}

static void DrawRarc( PDFConsumer *p, float rr, float xx1, float xx2 )
{
    float u0, v0, radius, theta1, theta2 ;
    
    u0 = rr/( rr+1.0 ) ;
    v0 = 0.0 ;
    radius = 1.0/( rr+1.0 ) ;
    theta1 = AngR( rr, xx1 ) ;
    theta2 = AngR( rr, xx2 ) ;
    DrawArc( p, u0, v0, radius, theta1, theta2 ) ;
}

static void DrawXarc( PDFConsumer *p, float xx, float rr1, float rr2 )
{
    float u0, v0, radius, theta1, theta2 ;

    u0 = 1.0 ;
    v0 = 1/xx ;
    radius = fabs( v0 ) ;

    theta1 = AngX( rr1, xx ) ;
    theta2 = AngX( rr2, xx ) ;
    DrawArc( p, u0, v0, radius, theta1, theta2 ) ;
}

static void RLabel( PDFConsumer *p, float r, char *str )
{
	float u, v ;
	
	[ p save ] ;
    RXtoUV( r, 0, &u, &v ) ;
    [ p show:str x:0 y:-Unitradius*u ] ;
	[ p restore ] ;
}

static void XLabel( PDFConsumer *p, float x, char *str )
{
	float u, v, rad ;
	
	rad = Unitradius*0.93 ;
	[ p save ] ;
		RXtoUV( 0, x, &u, &v ) ;
		[ p translate:(u)*rad y:(v)*rad ] ;
		[ p rotate: atan2( v, u ) ] ;
		[ p show:str x:0 y:0 ] ;
	[ p restore ] ;
}

static void MinusXLabel( PDFConsumer *p, float x, char *str )
{
	float u, v, rad ;
	
	rad = Unitradius*0.985 ;
	[ p save ] ;
		RXtoUV( 0, x, &u, &v ) ;
		[ p translate:(u)*rad y:(v)*rad ] ;
		[ p rotate: atan2( v, u )+3.1415926 ] ;
		[ p show:str x:0 y:0 ] ;
	[ p restore ] ;
}

//	v0.70 adjust alpha to compensate for printing line width
- (float)adjustedAlpha
{
	float a ;
	
	a = 1 ;
	if ( isScreen == NO ) {
		a = pow( currentLinewidth, 0.9 )*1.2 ;	//  only adjust alpha of thin lines
		if ( a < 0 ) a = 0 ; else if ( a > 1.0 ) a = 1.0 ;
	}
	return a ;
}

//	v0.70 adjust linewidth for printing case
- (void)setlinewidth:(float)width context:(PDFConsumer*)p 
{
	currentLinewidth = width ;
	[ p setlinewidth:width ] ;
	if ( isScreen == NO ) {
		[ p setRGBColor:currentRed g:currentGreen b:currentBlue alpha:[ self adjustedAlpha ] ] ;
	}
}

//	v0.70 adjust color for printer
- (void)setRGBColor:(float)r g:(float)g b:(float)b context:(PDFConsumer*)p
{
 	currentRed = r ;
	currentGreen = g ;
	currentBlue = b ;
	if ( isScreen == NO ) {
		[ p setRGBColor:currentRed g:currentGreen b:currentBlue alpha:[ self adjustedAlpha ] ] ;
		return ;
	}
	[ p setRGBColor:currentRed g:currentGreen b:currentBlue ] ;
}

- (void)setRGB:(NSColor*)rgb context:(PDFConsumer*)p
{
	[ self setRGBColor:[ rgb redComponent ] g:[ rgb greenComponent ] b:[ rgb blueComponent ] context:p ] ;
}


//  v0.70
- (void)setSWRCircle:(float)circle
{
	swrCircle = circle ;
}

- (void)drawCaptions:(PDFConsumer*)p
{
	float r ;
	
	[ p save ] ;
		//  draw SWR circle
 		if ( swrCircle > 1.05 ) {
			r = ( swrCircle-1 )/( swrCircle+1 );
			[ self setlinewidth:THICK*0.55 context:p ] ;
            [ self setRGBColor:0.5 g:0.3 b:0.1 context:p ] ;
			[ p arc:0 y:0 r:Unitradius*r t0:0 t1:pi2 ] ;
			[ p stroke ] ;
		}
    
        [ p setfont:"Helvetica" size:8.0 color:[ NSColor colorWithDeviceRed:0.5 green:0 blue:0 alpha:1.0 ] ] ;
    
        [ p save ] ;
        [ p rotate:3.1415926/2 ] ;		// rotate text of real axis captions
        RLabel( p, 9.97, "10" ) ;
        RLabel( p, 4.98, "5.0" ) ;
        RLabel( p, 1.98, "2.0" ) ;
        RLabel( p, 0.98, "1.0" ) ;
        RLabel( p, 0.49, " 0.5" ) ;
        RLabel( p, 0.19, " 0.2" ) ;
        [ p restore ] ;
 
		XLabel( p, 0.025, "   0" ) ;
		XLabel( p, 0.195, "0.2" ) ;
		XLabel( p, 0.495, "0.5" ) ;
		XLabel( p, 0.99, " 1.0" ) ;
		XLabel( p, 1.99, " 2.0" ) ;
		XLabel( p, 4.98, " 5.0" ) ;

		MinusXLabel( p, -0.195, "-0.2" ) ;
		MinusXLabel( p, -0.495, "-0.5" ) ;
		MinusXLabel( p, -0.995, "-1.0" ) ;
		MinusXLabel( p, -1.995, "-2.0" ) ;
		MinusXLabel( p, -4.995, "-5.0" ) ;
	[ p restore ] ;
}

- (void)drawBlock:(PDFConsumer*)p r1:(float)r1 r2:(float)r2 x1:(float)x1 x2:(float)x2
{
    float r, x, rtics, xtics ;
    
    rtics = 0.0 ;
    for ( r = r1+minorinc; r <= r2+minorinc/2 ; r += minorinc ) {
        rtics += 1.0 ;
        if ( ( (int)( rtics+.001 ) )%majorinc == 0 ) [ self setlinewidth:THICK context:p ] ; else [ self setlinewidth:THIN context:p ] ;
        DrawRarc( p, r, x2, x1 ) ;
        DrawRarc( p, r, -x1, -x2 ) ;
    }
    xtics = 0.0 ;
    for ( x = x1+minorinc; x <= x2+minorinc/2 ; x += minorinc ) {
		xtics++ ;
		if ( ( (int)( xtics+.001 ) )%majorinc == 0 ) [ self setlinewidth:THICK context:p ] ; else [ self setlinewidth:THIN context:p ] ;
		DrawXarc( p, x, r1, r2  ) ;
		DrawXarc( p, -x, r2, r1 ) ;
    }
}

- (void)drawImmittance:(PDFConsumer*)p regions:(float*)regions minorDiv:(float*)minorDiv majorDiv:(int*)majorDiv n:(int)n
{
    int index ; 
    float r1, r2, x1, x2 ;

    for ( index = 0; index < n; index++ ) {
        minorinc = minorDiv[index] ;
        majorinc = majorDiv[index] ;
        
        r1 = 0.0 ;
        r2 = regions[index+1] ;
        x1 = regions[index] ;
        x2 = regions[index+1] ;
        [ self drawBlock:p r1:r1 r2:r2 x1:x1 x2:x2 ] ;

        r1 = regions[index] ;
        r2 = regions[index+1] ;
    	x1 = 0.0 ;
        x2 = regions[index] ;
        if ( index == 7 ) majorinc = 3 ;
       [ self drawBlock:p r1:r1 r2:r2 x1:x1 x2:x2 ] ;
    }
	//  real axis
    [ self setlinewidth:THICK context:p ] ;
    [ p moveto:-Unitradius y:0 ] ;
    [ p lineto:Unitradius y:0 ] ;
    [ p stroke ] ;

	//  outer cicumference
	[ self setlinewidth:CIRCUMFERENCE context:p ] ;
    [ p arc:0 y:0 r:Unitradius t0:0 t1:pi2 ] ;
    [ p stroke ] ;
    
    DrawRarc( p, 50, 10000, 0 ) ;
    DrawRarc( p, 50, 0, -10000 ) ;
    DrawXarc( p, 50, 0, 10000 ) ; 
    DrawXarc( p, -50, 10000, 0 ) ;
}

- (void)drawRX:(PDFConsumer*)p
{
    [ self drawImmittance:p regions:ZRegions minorDiv:ZMinordiv majorDiv:ZMajordiv n:sizeof( ZMinordiv )/sizeof( float ) ] ;
}

//	v0.70
- (void)drawFeedpointCaptions
{
	intType index ;
	FeedpointCache *current ;
	complex double z ;
	
	current = [ outputContext selectedFeedpointCache ] ;
	index = [ self selectedFeedpointFromMenu ] ;
	if ( current == nil || current->frequency < .001 || index < 0 ) {
		//  nothing selected, leave the feedPoint caption area clear
		z = 0 ;
		[ auxSWRView show:nil index:-1 z:z colors:nil feedpoints:0 ] ;
		return ;
	}
	z = feedpointList[current->frequencyIndex].zr[current->feedpointNumber]*z0 + I*feedpointList[current->frequencyIndex].zx[current->feedpointNumber]*z0 ;
	[ auxSWRView show:current index:index z:z colors:colorWell feedpoints:numberOfFeedpoints ] ;
}

- (void)drawSmithChart:(PDFConsumer*)p
{
	float u, v, r, f ;
	int j, samples, frequencyIndex ;
    intType i, k, k0, kn ;
	char s[64] ;
	NSPoint q, drawn ;
	RXF *rxf ;
	CubicUV *interpolate ;
	float frequencyGap, deltaf ;
	Boolean gapped ;
				
	[ self updateFeedpointFromOutputContext ] ;
    [ p save ] ;
        [ p save ] ;
		//  draw Smitch Chart template
		[ self setRGBColor:1.0 g:0.0 b:0.0 context:p ] ; 
		[ self drawRX:p ] ;
		[ self drawCaptions:p ] ;
        [ p restore ] ;
		
		//	now draw data
		[ self setlinewidth:1.0 context:p ] ;
		//  draw references, if any, first
		for ( i = 0; i < refFeedpoint.feedpoints; i++ ) {
			RXtoUV(refFeedpoint.zr[i], refFeedpoint.zx[i], &u, &v ) ;
			[ self setRGB:refColor context:p ] ; 
			[ p arc:u*Unitradius y:v*Unitradius r:6.5 t0:0 t1:3.1415926*2 ] ;
			[ p fill ] ;
			[ self setRGB:refCenterColor context:p ] ; 
			[ p arc:u*Unitradius y:v*Unitradius r:1.5 t0:0 t1:3.1415926*2 ] ;
			[ p fill ] ;
		}
		if ( numberOfFrequencies > 0 ) {
			k = [ self selectedFeedpointFromMenu ] ;
			//  check the GUI version of SWRView (in case we are not) for show all checkbox
			if ( [ [ outputObject swrView ] showAllFeedpoints ] == YES ) {
				k0 = 0 ;
				kn = numberOfFeedpoints ;
			}
			else {
				k0 = k ;
				kn = k+1 ;
			}
			for ( i = k0; i < kn; i++ ) {
				if ( i >= 0 && i < MAXFEEDPOINTS ) {
					rxf = rxfArray[i] ;
					[ self setRGB:[ colorWell[i%16] color ] context:p ] ; 
					//  setup data array for interpolation
					samples = 0 ;
					for ( j = 0; j < numberOfFrequencies; j++ ) {
						RXtoUV( feedpointList[j].zr[i], feedpointList[j].zx[i], &u, &v ) ;
						if ( samples < MAXSWEEP ) {
							rxf[samples].uv = NSMakePoint( u, v ) ;
							rxf[samples].rx = NSMakePoint( feedpointList[j].zr[i], feedpointList[j].zx[i] ) ;
							rxf[samples].frequency = feedpointList[j].frequency ;
							rxf[samples].index = samples ;
							rxf[samples].frequencyIndex = j ;
							samples++ ;
						}
					}
					[ self sort:&rxf[0] samples:samples ] ;
					
					//check interpolate in the GUI SWRView (this code will work if we are ourself a GUI SWRView of printing SWRView)
					if ( samples > 3 && [ [ outputObject swrView ] doInterpolate ] ) {
						interpolate = [ [ CubicUV alloc ] initWithNumberOfPoints:samples z0:z0 ] ;
						//	v0.73 find frequency gap for smart interpolation
						frequencyGap = ( [ smartInterpolationCheckbox state ] == NSOnState ) ? [ interpolate frequencyGap:rxf ] : 1e12 ;
						[ interpolate createInterpolants:rxf ] ;
						q = [ interpolate evaluate:0 ] ;
						q.x *= Unitradius ;
						q.y *= Unitradius ;
						drawn = q ;
						[ p moveto:q.x y:q.y ] ;
						gapped = NO ;
						for ( j = 0; j < samples-1; j++ ) {
							deltaf = rxf[j+1].frequency - rxf[j].frequency ;		//  v0.73 smart interpolation skip
							if ( ( deltaf < frequencyGap ) ) {
								for ( f = 0.025; f < 1.01; f += 0.025 ) {
									q = [ interpolate evaluate:j+f ] ;
									q.x *= Unitradius ;
									q.y *= Unitradius ;
									if ( pointDist( q, drawn ) > 4.0 ) {
										drawn = q ;
										if ( gapped ) [ p moveto:q.x y:q.y ] ; else [ p lineto:q.x y:q.y ] ;	//  v0.73 use moveto after a gap
										gapped = NO ;
									}
								}
							}
							else gapped = YES ;
						}
						if ( pointDist( q, drawn ) > 0.5 ) [ p lineto:q.x y:q.y ] ;
						[ p stroke ] ;
						[ interpolate release ] ;
					}
					//  place dots
					if ( outputContext != 0 ) {
						FeedpointCache *current = [ outputContext selectedFeedpointCache ] ;
						for ( j = 0; j < samples; j++ ) {
							r = 3.0 ;
							u = rxf[j].uv.x ;
							v = rxf[j].uv.y ;
							frequencyIndex = rxf[j].index ;
							//  viewLocation of RXF element is the UV location adjusted by UnitRadius
							rxf[j].viewLocation = NSMakePoint( u*Unitradius, v*Unitradius ) ;
							if ( current->frequency < 0.001 || frequencyIndex != current->frequencyIndex || i != current->feedpointNumber || i != k ) {
								[ self drawPoint:p x:u*Unitradius y:v*Unitradius radius:r ] ;
							}
							else {
								//  draw donut for selected feedpoint's selected frequency
								[ self drawSelectedPoint:p x:u*Unitradius y:v*Unitradius radius:r ] ;
							}
						}
					}
				}
			}
		}
		// impedance captions
        float fontSize = ( isScreen ) ? 11.0*adjustedScale : 9.2 ;
        [  p setfont:"Helvetica" size:fontSize  color:[ NSColor blackColor ] ] ;
		[ self setRGBColor:0.0 g:0.0 b:0.0 context:p ] ;
		sprintf( s, "Zo = %.1f ohms", z0 ) ;
		[ p show:s x:-0.88*Unitradius y:0.92*Unitradius ] ;
	[ p restore ] ;
}


//	v0.70
//	select clicked location
- (Boolean)mouseDownInner:(NSEvent*)event
{
	NSPoint uv, clickedLocationInWindow ; 
	float r, duv, d ;
    intType index ;
    int j, frequencyIndex ;
	FeedpointCache target ;
	RXF *rxf ;
	
	if ( outputContext == nil ) return YES ; //  outputContext not yet defined
	target = *[ outputContext selectedFeedpointCache ] ;
	index = [ self selectedFeedpointFromMenu ] ;
	
	target.frequency = 0 ;
	target.frequencyIndex = 0 ;
	
    clickedLocationInWindow = [ event locationInWindow ] ;
    
	//	convert cursor location in window to UV location in Smith Chart.
	uv = [ self convertPoint:clickedLocationInWindow fromView:nil ] ;	
	
    // NSPoint viewOffsetInWindow
    // viewOffsetInWindow = [ self convertPoint:NSMakePoint( 0,0 ) fromView:nil ] ;
	// uv.x = ( uv.x-viewOffsetInWindow.x-center.x )/geometricScale ;
	// uv.y = ( uv.y-viewOffsetInWindow.y-center.y )/geometricScale ;
    
    //  v0.92   bug fix ; removed view offset; already handled by convertPoint
	uv.x = ( uv.x-center.x )/geometricScale ;
	uv.y = ( uv.y-center.y )/geometricScale ;	
	r = sqrt( uv.x*uv.x + uv.y*uv.y )/( Unitradius ) ;
	if ( r > 1.02 ) return YES ; //  outside Smith Chart
	if ( r > 0.999 ) {
		uv.x = uv.x*0.999/r ;
		uv.y = uv.y*0.999/r ;
	}
	duv = 1e6 ;
	rxf = rxfArray[index] ;
	frequencyIndex = 0 ;
	for ( j = 0; j < numberOfFrequencies; j++ ) {
		d = pointDist( rxf[j].viewLocation, uv ) ;
		if ( d < duv ) {
			duv = d ;
			frequencyIndex = rxf[j].frequencyIndex ;
		}
	}
	if ( duv > 10.0 ) {
		//  more than 10 pixels from a real point, don't beep if we are really far away
		return ( duv > 30 ) ;
	}
	target.frequency = feedpointList[frequencyIndex].frequency ;
	target.frequencyIndex = frequencyIndex ;
	[ outputContext setFeedpointCache:&target feedpointNumber:index ] ;
	[ self setNeedsDisplay:YES ] ;
    [ auxSWRView setNeedsDisplay:YES ] ;        //  v0.92 added to get more consistent updates
	return YES ;
}

- (void)drawRect:(NSRect)rect 
{
	NSGraphicsContext *graphicsContext ;
	NSBezierPath *backgroundPath ;
    PDFConsumer *canvas ;
	NSRect bounds ;
	NSPoint origin ;
	float r, gain, width, height, captionHeight ;
	
	[ self setupFeedpointMenu ] ;												//  v0.70
	bounds = [ self bounds ] ;													//  v0.70
    
	//  create new optical scale to make the caption height an integer value
	captionHeight = 40*[ self makeOpticalScale:bounds ] ;
	opticalScale = captionHeight/40.0 ;
	donutHoleColor = white ;
    
    origin = NSMakePoint( rect.origin.x, rect.origin.y ) ;
    width = rect.size.width ;
    height = rect.size.height ;
    center = NSMakePoint( width*0.5 + origin.x, height*0.5 + origin.y ) ;
    
    isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
    
    graphicsContext = [ NSGraphicsContext currentContext ] ;
	context = (CGContextRef)[ graphicsContext graphicsPort ] ;
	CGContextRetain( context ) ;
	
	//	Note: canvas is relative to NSWindow's coordinate.
	canvas = [ [ PDFConsumer alloc ] initWithContext:context width:1200 height:1200 ] ;
   
	// global values
	if ( isScreen ) {
		//  clear background and frame (note: BezierPath is relative to NSView's coordinate)
		backgroundPath = [ NSBezierPath bezierPathWithRect:[ self bounds ] ] ;
		[ [ NSColor whiteColor ] set ] ;
		[ backgroundPath fill ] ;
		[ [ NSColor blackColor ] set ] ;
		[ backgroundPath stroke ] ;

		[ canvas beginpage ] ;		
		//  set display coordinates, v0.70 resized to view
		r = width ;
		if ( height < r ) r = height ;
		[ canvas save ] ;
		//  create clip region
		[ canvas newpath ] ;
		[ canvas rect:0 y:origin.y width:width height:height ] ;
		[ canvas closepath ] ;
		[ canvas clip ] ;
		[ canvas translate:center.x y:center.y ] ;	//  use view center as canvas origin
		
		geometricScale = r*90.0/72.0/600.0 ;
		adjustedScale = opticalScale/geometricScale ;
		[ canvas scale:geometricScale ] ;
		[ self drawSmithChart:canvas ] ;
		[ canvas restore ] ;
		[ self drawFeedpointCaptions ] ;
		[ canvas endpage ] ;
	}
	else {
		//  printing coordinates
		backgroundPath = [ NSBezierPath bezierPathWithRect:rect ] ;
		[ [ NSColor whiteColor ] set ] ;
		[ backgroundPath fill ] ;
		if ( [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBorders ] ) {
			[ [ NSColor blackColor ] set ] ;
			[ backgroundPath stroke ] ;
		}
		[ canvas save ] ;
		[ canvas translate:center.x y:center.y ] ;	//  use view center as canvas origin
		r = width ;
		if ( height < r ) r = height ;
		gain = r/460.0 ;
		[ canvas scale:gain ] ;
		[ self drawSmithChart:canvas ] ;
		[ canvas restore ] ;
		[ self drawFeedpointCaptions ] ;
	}
	[ canvas release ] ;
	CGContextRelease( context ) ;
}

- (void)recompute:(id)control
{
	[ self setNeedsDisplay:YES ] ;
}

//  this is called when the color in the well changes
- (void)colorChanged:(NSColorWell*)well
{
	[ self setNeedsDisplay:YES ] ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

static int scramble[16] = { 2, 1, 4, 5, 0, 6, 3, 2, 1, 3, 6, 0, 5, 4, 2, 1 } ;

- (void)awakeFromNib
{
	int i, s ;
	float r, g, b ;
	
	//  NSColorWell are not cells and cannot be placed into an NSMatrix, for our own array here
	colorWell[0] = colorWell0 ;
	colorWell[1] = colorWell1 ;
	colorWell[2] = colorWell2 ;
	colorWell[3] = colorWell3 ;
	colorWell[4] = colorWell4 ;
	colorWell[5] = colorWell5 ;
	colorWell[6] = colorWell6 ;
	colorWell[7] = colorWell7 ;
	colorWell[8] = colorWell8 ;
	colorWell[9] = colorWell9 ;
	colorWell[10] = colorWell10 ;
	colorWell[11] = colorWell11 ;
	colorWell[12] = colorWell12 ;
	colorWell[13] = colorWell13 ;
	colorWell[14] = colorWell14 ;
	colorWell[15] = colorWell15 ;
	for ( i = 0; i < 16; i++ ) {
		[ self setInterface:colorWell[i] to:@selector(colorChanged:) ] ;
		s = scramble[i] ;
		r = ( s & 4 ) ? 0.75 : 0.0 ;
		g = ( s & 2 ) ? 0.53 : 0.0 ;
		b = ( s & 1 ) ? 1.0 : 0.0 ;
		[ colorWell[i] setColor:[ NSColor colorWithCalibratedRed:r green:g blue:b alpha:1 ] ] ;
	}	
	[ self setInterface:feedPoint to:@selector(recompute:) ] ;
	[ self setInterface:interpolateCheckbox to:@selector(recompute:) ] ;	
	[ self setInterface:showAllCheckbox to:@selector(recompute:) ] ;
	[ self setInterface:smartInterpolationCheckbox to:@selector(recompute:) ] ;	//  v0.73
}

- (AuxSWRView*)auxView
{
	return auxSWRView ;
}

- (Boolean)showAllFeedpoints
{
	return ( [ showAllCheckbox state ] == NSOnState ) ;
}

- (NSColor*)wellColor:(int)index
{
	if ( index < 0 || index > 15 ) index = 0 ;
	return [ colorWell[index] color ] ;
}

- (void)setWellColor:(int)index color:(NSColor*)color
{
	if ( index < 0 || index > 15 ) index = 0 ;
	[ colorWell[index] setColor:color ] ;
}

- (NSColorWell*)colorWell:(int)index
{
	return colorWell[index] ;
}

- (void)setColorWell:(int)index fromColorWell:(NSColorWell*)well
{
	colorWell[index] = well ;
}

- (void)openColorManager
{
	[ colorWindow orderFront:self ] ;
}

//	v0.73
- (Boolean)doSmartInterpolate
{
	return ( [ smartInterpolationCheckbox state ] == NSOnState ) ;
}

//	v0.73
- (void)setSmartInterpolate:(Boolean)state
{
	[ smartInterpolationCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
}


@end
