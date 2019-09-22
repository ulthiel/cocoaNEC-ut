//
//  PatternView.m
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

#import "PatternView.h"
#import "ApplicationDelegate.h"
#import "NewArray.h"
#import "NECOutput.h"
#import "PatternElement.h"
#import "RadiationPattern.h"
#import "RunInfo.h"

@implementation PatternView

static int circle0[] = { -1, -2, -3, -4, -5, -6, -8, -10, -13, -20, -30, 0 } ;
static int circle1[] = { -2, -4, -6, -8, -10, -13, -16, -20, -30, -40, 0 } ;
static int circle2[] = { -3, -6, -10, -15, -20, -30, -40, -50, -70, 0 } ;

- (void)createGrids
{
	int i ;
	int c ;
	float radius, theta, x, y ;
	NSBezierPath *p ;
	
	if ( circles ) [ circles release ] ;
	circles = [ [ NSBezierPath bezierPath ] retain ] ;
	if ( minorCircles ) [ minorCircles release ] ;
	minorCircles = [ [ NSBezierPath bezierPath ] retain ] ;
	
	[ circles setLineWidth: 0.45 ] ;
	[ minorCircles setLineWidth: 0.2 ] ;
	for ( i = -1; i < 13; i++ ) {
		if ( i >= 0 ) {
			c = circle[i] ;
			if ( c == 0 ) break ;
			radius = pow( rho, c ) ;
			p = ( ( c % 10 ) == 0 ) ? circles : minorCircles ;
		}
		else {
			radius = 1.0 ;
			p = circles ;
		}
		if ( i >= 0 ) [ p moveToPoint:NSMakePoint( radius, 0.0 ) ] ;
		[ p appendBezierPathWithArcWithCenter:NSMakePoint(0.,0.) radius:radius startAngle:0.0 endAngle:360. ] ;
	}
	radius = pow( rho, -40 ) ;
	for ( i = 0; i < 36; i++ ) {
		// 10 degree steps
		theta = i*3.1415926/18.0 ;
		x = cos( theta ) ;
		y = sin( theta ) ;
		if ( ( i % 3 ) == 0 ) {
			p = circles ;
			radius = pow( rho, majorMin ) ;
		}
		else {
			p = minorCircles ;
			radius = pow( rho, minorMin ) ;
		}
		[ p moveToPoint:NSMakePoint( x*radius, y*radius ) ] ;
		[ p lineToPoint:NSMakePoint( x, y ) ] ;
	}
}

- (void)changeColor:(NSColorWell*)well
{
	intType index ;
	
	index = [ well tag ] ;
	if ( index < 0 || index > 15 ) return ;
	plotColor[index] = [ well color ] ;
	[ self setNeedsDisplay:YES ] ;
}

//	v0.70 use user config color wells
- (void)updateColorsFromColorWells:(ColorWells*)wells
{
	int i, n ;
	
	n = wells->numberOfWells ;
	if ( n > MAXCOLORWELLS ) n = MAXCOLORWELLS ;
	for ( i = 0; i < n; i++ ) {
		[ plotColor[i] autorelease ] ;
		plotColor[i] = [ [ wells->colorWell[i] color ] retain ] ;
	}
	for ( ; i < MAXCOLORWELLS; i++ ) {
		[ plotColor[i] autorelease ] ;
		plotColor[i] = [ plotColor[0] retain ] ;	//  duplicate, in case fewer than MAX wells passed in
	}
}

//  v0.70
- (void)setIsEmbedded:(Boolean)state
{
	isEmbedded = state ;
}

- (id)initWithFrame:(NSRect)inFrame isElevation:(Boolean)elevation
{
	NSFont *verdana8, *verdana9 ;
	int i ;
	
    self = [ super initWithFrame:inFrame ] ;
	if ( self ) {	
		rho = 1.059998 ;					//  default: ARRL scale 0.89 per 2 dB
		gainPolarization = kTotalPolarization ;
		minorMin = -30 ;
		majorMin = -40 ;
		arrayOfRadiationPatterns = newArray() ;
		arrayOfReferencePatterns = newArray() ;
		arrayOfPreviousPatterns = newArray() ;
		frame = inFrame ;
		circle = circle1 ;
		circles = minorCircles = nil ;
		isElevation = elevation ;			//  v0.70  missing earlier
		isEmbedded = NO ;					//  v0.70 -- used to identidy patterns in summary view
		
		refColor = [ [ NSColor colorWithDeviceRed:0.3 green:0.3 blue:0.3 alpha:1.0 ] retain ] ;
		for ( i = 0; i < MAXCOLORWELLS; i++ ) plotColor[i] = [ [ NSColor colorWithDeviceRed:1 green:0.0 blue:0.0 alpha:1.0 ] retain ] ;
		
        //  v0.88 use systemFont
		//  set font attributes		
        verdana8 = nil ; // [ NSFont fontWithName: @"Verdana" size: 8.5 ] ;
		if ( !verdana8 ) verdana8 = [ NSFont systemFontOfSize:8.5 ] ;

        verdana9 = nil ; // [ NSFont fontWithName: @"Verdana" size: 9 ] ;
		if ( !verdana9 ) verdana9 = [ NSFont systemFontOfSize:9 ] ;

		captionAttributes = [ [ NSMutableDictionary alloc ] initWithCapacity:2 ] ;
		[ captionAttributes setObject:verdana9 forKey:NSFontAttributeName ] ;
		[ captionAttributes setObject:[ NSColor blackColor ]  forKey:NSForegroundColorAttributeName ] ;
		
		smallInfoAttributes = [ [ NSMutableDictionary alloc ] initWithCapacity:2 ] ;
		[ smallInfoAttributes setObject:verdana8 forKey:NSFontAttributeName ] ;
		[ smallInfoAttributes setObject:[ NSColor blackColor ]  forKey:NSForegroundColorAttributeName ] ;

		[ self createGrids ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ refColor release ] ;		//  v0.64
	[ defaultColor release ] ;
	[ circles release ] ;
	[ minorCircles release ] ;
	[ textAttributes release ] ;
	[ captionAttributes release ] ;
	[ smallInfoAttributes release ] ;
	[ arrayOfRadiationPatterns release ] ;
	[ arrayOfReferencePatterns release ] ;
	[ arrayOfPreviousPatterns release ] ;
	[ super dealloc ] ;
}

//  -setNeedsDisplay will take data from the new array and update the view
//	array is an array of RadiationPatterns, each RadiationPattern is an array of PatternElements
- (void)updatePatternWithArray:(NSArray*)array refArray:(NSArray*)ref prevArray:(NSArray*)prev
{
	[ arrayOfRadiationPatterns removeAllObjects ] ;
	if ( array ) [ arrayOfRadiationPatterns addObjectsFromArray:array ] ;
	
	[ arrayOfReferencePatterns removeAllObjects ] ;
	if ( ref ) [ arrayOfReferencePatterns addObjectsFromArray:ref ] ;
	
	[ arrayOfPreviousPatterns removeAllObjects ] ;
	if ( prev ) [ arrayOfPreviousPatterns addObjectsFromArray:prev ] ;

	[ self setNeedsDisplay:YES ] ;
}

- (void)clearPatterns
{
	[ self updatePatternWithArray:nil refArray:nil prevArray:nil ] ;
}

- (void)drawPattern:(NSAffineTransform*)scale
{
    int p, plot, combinedPlots, i ;
    intType count, patternCount ;
	float r, q, maxGain, *gain ;
	const floatType dash[4] = { 2, 2, 6, 2 }, comboDash[2] = { 4, 2 }  ;
	NSArray *elementArray, *captionArray ;
	NSMutableArray *combinedPatterns ;
	NSBezierPath *path ;
	RadiationPattern *radiationPattern, *referencePattern, *previousPattern ;
	PatternInfo info ;
	
	patternCount = [ arrayOfRadiationPatterns count ] ;
	if ( patternCount <= 0 ) return ;
	
	referencePattern = previousPattern =  nil ;
	combinedPlots =  0 ;
	combinedPatterns = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
	
	//  if there is a reference object, use it as the first pattern in the combinedPatterns array
	count = [ arrayOfPreviousPatterns count ] ;
	if ( count > 0 ) {
		combinedPlots = 1 ;
		previousPattern = [ arrayOfPreviousPatterns objectAtIndex:0 ] ;
		[ combinedPatterns addObject:previousPattern ] ;
	}
	else {
		count = [ arrayOfReferencePatterns count ] ;
		if ( count > 0 ) {
			combinedPlots = 1 ;
			referencePattern = [ arrayOfReferencePatterns objectAtIndex:0 ] ;
			[ combinedPatterns addObject:referencePattern ] ;
		}
	}
	
	for ( i = 0; i < patternCount; i++ ) [ combinedPatterns addObject:[ arrayOfRadiationPatterns objectAtIndex:i ] ] ;
	combinedPlots += patternCount ;
		
	if ( combinedPlots > MAXCOLORWELLS ) combinedPlots = MAXCOLORWELLS ; else if ( combinedPlots <= 0 ) return ;
	
	//  find max gain over four (inclusive of reference) plots
	maxGain = -1000.0 ;
	for ( plot = 0; plot < combinedPlots; plot++ ) {
		radiationPattern = [ combinedPatterns objectAtIndex:plot ] ;
		switch ( gainPolarization ) {
		case kVerticalPolarization:
			r = [ radiationPattern maxDBv ] ;
			break ;
		case kHorizontalPolarization:
			r = [ radiationPattern maxDBh ] ;
			break ;
		case kLeftCircularPolarization:				//  v0.67
			r = [ radiationPattern maxDBl ] ;
			break ;
		case kRightCircularPolarization:			//  v0.67
			r = [ radiationPattern maxDBr ] ;
			break ;
		case kVandHPolarization:					//  v0.68
			r = [ radiationPattern maxDBv ] ;
			q = [ radiationPattern maxDBh ] ;
			if ( q > r ) r = q ;
			break ;
		case kLandRPolarization:					//  v0.68
			r = [ radiationPattern maxDBl ] ;
			q = [ radiationPattern maxDBr ] ;
			if ( q > r ) r = q ;
			break ;
		default:
		case kTotalPolarization:
			r = [ radiationPattern maxDBt ] ;
			break ;
		}
		if ( r > maxGain ) maxGain = r ;
	}
	
	for ( plot = 0; plot < combinedPlots; plot++ ) {
		radiationPattern = [ combinedPatterns objectAtIndex:plot ] ;
		path = [ NSBezierPath bezierPath ] ;
		[ path setLineWidth: 1.2 ] ;
		if ( radiationPattern == referencePattern || radiationPattern == previousPattern ) {
			//  check if it is reference or previous pattern, if so use dash
			[ path setLineDash:dash count:4 phase:0.0 ] ;
			[ refColor set ] ;
		}
		else {
			p = plot ;
			if ( ( referencePattern != nil || previousPattern != nil ) && p > 0 ) p-- ;
			[ plotColor[p] set ] ;
		}
		count = [ radiationPattern count ] ;
		elementArray = [ radiationPattern array ] ;
		gain = (float*)malloc( sizeof( float )*count ) ;
		
		switch ( gainPolarization ) {
		case kVerticalPolarization:
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBv ;
			}
			break ;
		case kHorizontalPolarization:
		case kVandHPolarization:							//  v0.68
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBh ;
			}
			break ;
		case kLeftCircularPolarization:						//  v0.67
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBl ;
			}
			break ;
		case kRightCircularPolarization:					//  v0.67
		case kLandRPolarization:							//  v0.68
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBr ;
			}
			break ;
		case kTotalPolarization:
		default:
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBt ;
			}
			break ;
		}
		[ self plotGain:path gain:gain maxGain:maxGain elementArray:elementArray count:count ] ;
		[ path closePath ] ;
		[ [ scale transformBezierPath:path ] stroke ] ;
		free( gain ) ;
		
		//  v0.68  second part of V+H and L+R plots
		if ( gainPolarization == kVandHPolarization || gainPolarization == kLandRPolarization ) {
			radiationPattern = [ combinedPatterns objectAtIndex:plot ] ;
			path = [ NSBezierPath bezierPath ] ;
			[ path setLineWidth: 1.2 ] ;			
			if ( radiationPattern == referencePattern || radiationPattern == previousPattern ) {
				//  check if it is reference or previous pattern, if so use dash
				[ refColor set ] ;
			}
			else {
				p = plot ;
				if ( ( referencePattern != nil || previousPattern != nil ) && p > 0 ) p-- ;
				[ plotColor[p] set ] ;
			}
			[ path setLineDash:comboDash count:2 phase:0.0 ] ;
		
			count = [ radiationPattern count ] ;
			elementArray = [ radiationPattern array ] ;
			gain = (float*)malloc( sizeof( float )*count ) ;
			
			switch ( gainPolarization ) {
			case kVandHPolarization:
			for ( i = 0; i < count; i++ ) {
				info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
				gain[i] = info.dBv ;
			}
			break ;
			case kLandRPolarization:
				for ( i = 0; i < count; i++ ) {
					info = [ (PatternElement*)[ elementArray objectAtIndex:i ] info ] ;
					gain[i] = info.dBl ;
				}
				break ;
			}
			[ self plotGain:path gain:gain maxGain:maxGain elementArray:elementArray count:count ] ;
			[ path closePath ] ;
			[ [ scale transformBezierPath:path ] stroke ] ;
			free( gain ) ;
		}
	}
	if ( maxGain > -999 ) {
		if ( frame.size.width > 450 ) {
			[ [ NSString stringWithFormat:@"0 dB = %.2f dBi", maxGain ] drawAtPoint:[ scale transformPoint:NSMakePoint( 1.2, 1.0 ) ] withAttributes:infoAttributes ] ;
		} 
		else {
			[ [ NSString stringWithFormat:@"%.2f dBi", maxGain ] drawAtPoint:[ scale transformPoint:NSMakePoint( 0.8, 1.0 ) ] withAttributes:smallInfoAttributes ] ;
		}
	}
	else {
		[ @"No data." drawAtPoint:[ scale transformPoint:NSMakePoint( -0.905, 0.84 ) ] withAttributes:infoAttributes ] ;
	}
	//  output directivity
	RunInfo *runInfo = [ (ApplicationDelegate*)[ NSApp delegate ] runInfo ] ;
	if ( runInfo->directivity > -0.5 ) {
		if ( frame.size.width > 450 ) {
			[ [ NSString stringWithFormat:@"Directivity = %.2f dB", runInfo->directivity ] drawAtPoint:[ scale transformPoint:NSMakePoint( 1.2, 0.96 ) ] withAttributes:infoAttributes ] ;
		}
		else {
			[ [ NSString stringWithFormat:@"%.2f dB", runInfo->directivity ] drawAtPoint:[ scale transformPoint:NSMakePoint( 0.8, 0.94 ) ] withAttributes:smallInfoAttributes ] ;

            //  0.92 display azimuth and elevation angles in sumary view plots
            RadiationPattern *radiationPattern = [ arrayOfRadiationPatterns objectAtIndex:0 ] ;
            
            if ( radiationPattern != nil ) {            
                if ( isElevation ) {
                    float azi ;
                    azi = [ radiationPattern meanPhi ] ;
                    [ [ NSString stringWithFormat:@"Azimuth %.0f deg", azi ] drawAtPoint:[ scale transformPoint:NSMakePoint( 0.52, -1.05 ) ] withAttributes:smallInfoAttributes ] ;
                }
                else {
                    float elev ;
                    elev = 90 - fabs( [ radiationPattern meanTheta ] ) ;
                    [ [ NSString stringWithFormat:@"Elevation %.0f deg", elev ] drawAtPoint:[ scale transformPoint:NSMakePoint( 0.5, -1.05 ) ] withAttributes:smallInfoAttributes ] ;
                }
            }
		}
	}
	//  draw captions
	if ( frame.size.width > 450 ) {
		//  v0.70 - draw captions in aux view
		captionArray = [ self makeCaptions:patternCount reference:referencePattern previous:previousPattern ] ;
		count = [ captionArray count ] ;
		if ( count > 0 && auxPatternView ) [ auxPatternView show:captionArray colors:&plotColor[0] ] ;
	}
	[ combinedPatterns release ] ;
}

- (NSArray*)makeCaptions:(intType)count reference:(RadiationPattern*)ref previous:(RadiationPattern*)prev
{
	//  override to plot the captions
	return nil ;
}

- (void)plotGain:(NSBezierPath*)path gain:(float*)gain maxGain:(float)maxGain elementArray:(NSArray*)array count:(intType)count
{
	//  override to plot the gain
}

- (void)drawRect:(NSRect)rect
{
    NSAffineTransform *box ;
	NSBezierPath *framePath ;
	NSRect bounds ;
    NSPoint center ;
	NSString *str ;
	Boolean isScreen ;
	int i, c ;
    float r, dx, dy ;
	
	bounds = [ self bounds ] ;
	isScreen = [ NSGraphicsContext currentContextDrawingToScreen ] ;
	framePath = [ NSBezierPath bezierPathWithRect:( isScreen ) ? bounds : rect ] ;	
	
	//  set scales for screen and printing
	box = [ [ NSAffineTransform alloc ] initWithTransform:[ NSAffineTransform transform ] ] ;
	
	if ( isScreen ) {
		//  clear area and frame it  
		[ [ NSColor whiteColor ] set ] ; 
		[ framePath fill ] ;   
		[ [ NSColor blackColor ] set ] ; 
		[ framePath stroke ] ;	
		// size and position for screen
		center.x = bounds.size.width*0.5 ;
		center.y = bounds.size.height*0.5 ;
		r = center.x ;
		if ( center.y < r ) r = center.y ;   
		[ box translateXBy: center.x yBy: center.y ] ;
		[ box scaleBy:r*0.9 ] ;		
		//  draw circles and rays
		[ [ NSColor colorWithDeviceRed: 0.0 green:0.0 blue:0.5 alpha:1 ] set ] ;
		[ [ box transformBezierPath:circles ] stroke ] ;
		[ [ box transformBezierPath:minorCircles ] stroke ] ;
	}
	else {
		//  print job
		if ( isEmbedded == NO ) {
			//  regular sized printing Azimuth and Elevation views
			if ( [ [ (ApplicationDelegate*)[ NSApp delegate ] output ] drawBorders ] ) {
				[ [ NSColor blackColor ] set ] ; 
				[ framePath stroke ] ;
			}
			//  size and position for prints, no background
			r = bounds.size.width ;
			if ( r > bounds.size.height ) r = bounds.size.height ;
			[ box translateXBy:bounds.size.width*0.5 yBy:bounds.size.height*0.5 ] ;
			[ box scaleBy:r*0.5*0.9 ] ;
		}
		else {
			//  Embedded Azimuth and Elevation views that are part of summaryView.
			dx = bounds.size.width*0.5 ;
			dy = bounds.size.height*0.5 ;
			[ box translateXBy:dx yBy:dy ] ; 
			r = dx ;
			if ( dy < r ) r = dy ;
			[ box scaleBy:r*0.92 ] ;
		}
		//  draw circles and rays
		[ [ NSColor colorWithDeviceRed: 0.0 green:0.0 blue:0.5 alpha:0.52 ] set ] ;
		[ [ box transformBezierPath:circles ] stroke ] ;
		[ [ NSColor colorWithDeviceRed: 0.0 green:0.0 blue:0.5 alpha:0.25 ] set ] ;
		[ [ box transformBezierPath:minorCircles ] stroke ] ;
	} 	
	if ( isEmbedded == NO ) {
		//  gain labels
		for ( i = 0; i < 12; i++ ) {
			c = circle[i] ;
			if ( c == 0 ) break ;
			str = [ NSString stringWithFormat:@"%d", c ] ;
			[ str drawAtPoint:[ box transformPoint: NSMakePoint( pow( rho, c )+0.005, 0.004 ) ] withAttributes:textAttributes ] ;
		}
	}
    
    //degree labels
    float rad;
    //float xDir = threeDPlotDistance;
    if (isElevation == true && isEmbedded == NO)
    {
        rad = 0*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 0 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)+0.01, sin(rad)-0.02 ) ] withAttributes:textAttributes ] ;
        rad = 30*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 30 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)+0.01, sin(rad)-0.01 ) ] withAttributes:textAttributes ] ;
        rad = 60*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 60 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad), sin(rad) ) ] withAttributes:textAttributes ] ;
        rad = 90*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 90 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.02, sin(rad) ) ] withAttributes:textAttributes ] ;
        rad = 120*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 60 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.03, sin(rad) ) ] withAttributes:textAttributes ] ;
        rad = 150*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 30 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.055, sin(rad)-0.01 ) ] withAttributes:textAttributes ] ;
        rad = 180*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 0 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.045, sin(rad)-0.02 ) ] withAttributes:textAttributes ] ;
    }
    if (isElevation == false && isEmbedded == NO)
    {
        rad = 0*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 0 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)+0.01, sin(rad)-0.02 ) ] withAttributes:textAttributes ] ;
        rad = 30*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 30 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)+0.01, sin(rad)-0.01 ) ] withAttributes:textAttributes ] ;
        rad = 60*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 60 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad), sin(rad) ) ] withAttributes:textAttributes ] ;
        rad = 90*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 90 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.02, sin(rad) ) ] withAttributes:textAttributes ] ;
        rad = 120*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 120 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.035, sin(rad)+0.01 ) ] withAttributes:textAttributes ] ;
        rad = 150*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 150 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.08, sin(rad)-0.01 ) ] withAttributes:textAttributes ] ;
        rad = 180*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 180 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.09, sin(rad)-0.02 ) ] withAttributes:textAttributes ] ;
        rad = 210*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 210 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.09, sin(rad)-0.025 ) ] withAttributes:textAttributes ] ;
        rad = 240*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 240 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.045, sin(rad)-0.055 ) ] withAttributes:textAttributes ] ;
        rad = 270*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 270 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.04, sin(rad)-0.05 ) ] withAttributes:textAttributes ] ;
        rad = 300*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 300 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad)-0.03, sin(rad)-0.06 ) ] withAttributes:textAttributes ] ;
        rad = 330*( 3.1415926/180.0 );
        [ [ NSString stringWithFormat:@"%d°", 330 ] drawAtPoint:[ box transformPoint: NSMakePoint( cos(rad), sin(rad)-0.04 ) ] withAttributes:textAttributes ] ;
    }
    
	//  now draw actual pattern
	[ self drawPattern:box ] ;

	[ box release ] ;				//  v0.64
}

- (void)setGainScale:(double)s
{
	rho = s ;
	circle = circle1 ;
	minorMin = -30 ;
	majorMin = -40 ;
	if ( rho > 1.08 ) {
		circle = circle0 ;
		minorMin = -20 ;
		majorMin = -30 ;
	}
	else if ( rho < 1.05 ) {
		circle = circle2 ;
		minorMin = -50 ;
		majorMin = -70 ;
	} 	
	[ self createGrids ] ;
	[ self setNeedsDisplay:YES ] ;
}

- (void)setGainPolarization:(intType)pol
{
	gainPolarization = pol ;
	[ self setNeedsDisplay:YES ] ;
}

- (Boolean)isElevation
{
	return isElevation ;
}

- (AuxPatternView*)auxView 
{
	return auxPatternView ;
}

@end
