//
//  NECOutput.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/21/07.
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

#import "NECOutput.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "AzimuthView.h"
#import "Bundle.h"
#import "DateFormat.h"
#import "ElevationView.h"
#import "Feedpoint.h"
#import "GeometryView.h"
#import "NEC4Context.h"
#import "OutputContext.h"
#import "PatternElement.h"
#import "PatternView.h"
#import "Pattern3dView.h"
#import "plist.h"
#import "RadiationPattern.h"
#import "ScalarView.h"
#import "SWRView.h"
#include <complex.h>

@implementation NECOutput


- (NSDictionary*)makeFontAttributeForSize:(float)size
{
	NSFont *verdana ;
	NSMutableDictionary *attributes ;

    //  v0.88 use system font
    verdana = nil ; // [ NSFont fontWithName: @"Verdana" size:size ] ;
	if ( !verdana ) verdana = [ NSFont systemFontOfSize:size ] ;
	attributes = [ [ NSMutableDictionary alloc ] init ] ;
	[ attributes setObject:verdana forKey:NSFontAttributeName ] ;

	return attributes ;
}

- (id)init
{	
	self = [ super init ] ;
	if ( self ) {
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"Output" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;
 
        contexts = [ [ NSMutableArray alloc ] init ] ;
		currentContext = nil ;
		defaultContextIndex = -1 ;
		referenceContext = nil ;
		usePreviousPatternAsReference = NO ;
		savedListing = nil ;	//  v0.64
		smallFontAttributes = [ self makeFontAttributeForSize:9 ] ;
		mediumFontAttributes = [ self makeFontAttributeForSize:10.5 ] ;
	}
	return self ;
}

- (SWRView*)swrView
{
	return swrView ;
}

- (Pattern3dView*)pattern3dView
{
	return pattern3DView ;
}

- (ScalarView*)scalarView
{
	return scalarView ;
}

- (NSString*)savedListing
{
	return savedListing ;
}

- (void)dealloc
{
	[ contexts release ] ;
	[ smallFontAttributes release ] ;
	[ mediumFontAttributes release ] ;
    [ retainedNibObjects release ] ;
	[ super dealloc ] ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)setupTextView:(NSTextView*)view 
{
    NSFont *font = [ NSFont fontWithName: @"Monaco" size:10.0 ] ;
    NSTextContainer *container = [ view textContainer ] ;
    
    [ view setFont:font ] ;
     
    [ container setContainerSize:NSMakeSize( 1000.0, 1.2e6 ) ] ;		//  v0.61 for long listings
    [ container setWidthTracksTextView:NO ] ;
    
    [ view setMaxSize:NSMakeSize( 1000.0, 1.2e6 ) ] ;					//  v0.61 for long listings
    [ view setHorizontallyResizable:YES ] ;								//  this turns on the horizontal scroller
}

//  this is called when the color in the radiation pattern color well changes
- (void)radiationPatternColorChanged:(NSColorWell*)well
{
	[ azimuthView changeColor:well ] ;
	[ elevationView changeColor:well ] ;
	[ summaryAzimuth changeColor:well ] ;
	[ summaryElevation changeColor:well ] ;

	[ azimuthContainer changeColor:well ] ;
	[ elevationContainer changeColor:well ] ;
	[ summaryContainer changeColor:well ] ;
}

- (void)updateRadiationPatternColorWells
{
	[ azimuthView updateColorsFromColorWells:&colorWells ] ;
	[ elevationView updateColorsFromColorWells:&colorWells ] ;
	[ summaryAzimuth updateColorsFromColorWells:&colorWells ] ;
	[ summaryElevation updateColorsFromColorWells:&colorWells ] ;
	[ azimuthContainer updateColorsFromColorWells:&colorWells ] ;
	[ elevationContainer updateColorsFromColorWells:&colorWells ] ;
	[ summaryContainer updateColorsFromColorWells:&colorWells ] ;
}

- (void)awakeFromNib
{
	int i ;
	NSColorWell *well[] = { colorWell0, colorWell1, colorWell2, colorWell3, colorWell4, colorWell5, colorWell6, colorWell7,
						    colorWell8, colorWell9, colorWell10, colorWell11, colorWell12, colorWell13, colorWell14, colorWell15 } ;

	//  connect changes in ScalarView to printing ScalarView
	[ scalarView setPrintView:[ scalarContainer scalarView ] ] ;
	
	//	v0.81e connect geometry current to geometry view
	if ( geometryView ) [ geometryView setCurrentView:wireCurrent ] ;

	//  Color wells cannot be made into an NSMatrix, so we create an array manually,
	//	and set their actions to -radiationPatterColorChanged:
	colorWells.numberOfWells = 16 ;
	for ( i = 0; i < colorWells.numberOfWells; i++ ) {
		colorWells.colorWell[i] = well[i] ;
		[ self setInterface:well[i] to:@selector(radiationPatternColorChanged:) ] ;
	}
	//  pass color wells on to all radiation patterns
	[ self updateRadiationPatternColorWells ] ;
	
	//  v0.70 explict identification as embedded patterns
	[ summaryAzimuth setIsEmbedded:YES ] ;		
	[ summaryElevation setIsEmbedded:YES ] ;
	
	[ modelList setNumberOfVisibleItems:0 ] ;
	[ modelList setUsesDataSource:YES ] ;
	[ modelList setDataSource:self ] ;
	
	[ cardsTable setDataSource:self ] ;
	hollerithCardColumn = [ [ cardsTable tableColumns ] objectAtIndex:1 ] ;
	
	[ self setupTextView:listing ] ;

	[ self setInterface:modelList to:@selector(switchContext) ] ;
	[ self setInterface:gainScaleMatrix to:@selector(gainScaleChanged) ] ;
	[ self setInterface:gainPolarizationMatrix to:@selector(gainPolarizationChanged) ] ;
	[ self setInterface:Z0 to:@selector(updateZ0) ] ;
	[ self setInterface:swrCircle to:@selector(updateSWRCircle) ] ;
	
	[ self setInterface:elevationField to:@selector(geometryControlsChanged:) ] ;
	[ self setInterface:azimuthField to:@selector(geometryControlsChanged:) ] ;
	[ self setInterface:elevationStepper to:@selector(geometryControlsChanged:) ] ;
	[ self setInterface:azimuthStepper to:@selector(geometryControlsChanged:) ] ;
	[ self setInterface:zoomSlider to:@selector(geometryControlsChanged:) ] ;
	[ self setInterface:centerButton to:@selector(geometryCenterChanged:) ] ;

	[ self setInterface:azimuth3dField to:@selector(az3dControlsChanged:) ] ;
	[ self setInterface:azimuth3dStepper to:@selector(az3dControlsChanged:) ] ;
	[ self setInterface:contrast3dSlider to:@selector(contrast3dChanged:) ] ;
	[ self setInterface:phongMatrix to:@selector(phongChanged:) ] ;

	//  v0.64
	[ tabMenu setDelegate:self ] ;
	 
	[ pattern3DView setAngle:[ azimuth3dField floatValue ] ] ;
	[ pattern3DView setContrast:[ contrast3dSlider floatValue ] ] ;

	[ self setInterface:currentsMenu to:@selector(refreshGeometry) ] ;
	[ self setInterface:drawRadialsCheckbox to:@selector(refreshGeometry) ] ;
	[ self setInterface:drawDistributedLoadsCheckbox to:@selector(refreshGeometry) ] ;	//	v0.81d

	[ centerButton setHidden:YES ] ;
	
	[ self refreshGeometry ] ;	//  set the default al-az angles
}

//	v0.64
- (void)appendSummary:(NSString*)string
{
	[ summaryContainer appendText:string ] ;
	[ summary setString:[ [ summary string ] stringByAppendingString:string ] ] ;
}

- (NSString*)imagStr:(float)v
{
	if ( v >= 0 ) return [ NSString stringWithFormat:@"+ i %.3f", v ] ;
	return [ NSString stringWithFormat:@"- i %.3f", -v ] ;
}

- (NSString*)imagStr4:(float)v
{
	if ( v >= 0 ) return [ NSString stringWithFormat:@"+ i %.4f", v ] ;
	return [ NSString stringWithFormat:@"- i %.4f", -v ] ;
}

- (void)refreshGeometry
{
	intType currentType ;
	float az, el, zoom ;
	
	zoom = pow( 2.0, [ zoomSlider floatValue ] ) ;	
	currentType = [ [ currentsMenu selectedItem ] tag ] ;
	az = [ azimuthField floatValue ]+270 ;					// v0.70
	if ( az > 360 ) az -= 360 ;								// v0.70
	el = [ elevationField floatValue ] ;
	
	//  v0.81d
	geometryOptions.radials = ( [ drawRadialsCheckbox state ] == NSOnState ) ;
	geometryOptions.distributedLoads = ( [ drawDistributedLoadsCheckbox state ] == NSOnState ) ;
		
	if ( currentContext ) [ currentContext redrawGeometry:&geometryOptions ] ;
	[ (GeometryView*)geometryView refreshCurrents:currentType azimuth:az elevation:el zoom:zoom options:&geometryOptions ] ;
	[ [ geometryContainer geometryView ] refreshCurrents:currentType azimuth:az elevation:el zoom:zoom options:&geometryOptions ] ;
}

- (void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	int whichTab ;
	
	if ( tabView != tabMenu ) return ;
	
	//  v0.64 -- display output if tab changes to listing view
	whichTab = [ [ tabViewItem identifier ] intValue ] ;
	if ( whichTab == kNECListTab && savedListing ) [ listing setString:savedListing ] ;		//  v0.70 use manifest constant for kNECList
	[ geometryView viewSelected:( whichTab == kGeometryTab ) ] ;
}

- (void)geometryControlsChanged:(id)sender
{
	int az, el ;
	
	if ( sender == elevationStepper ) {
		[ elevationField setIntValue: [ sender intValue ] ] ;
	}
	else if ( sender == azimuthStepper ) {
		[ azimuthField setIntValue: [ sender intValue ] ] ;
	}
	//  limit travels
	az = [ azimuthField intValue ] ;
	el = [ elevationField intValue ] ;
	if ( az < 0 ) az += 360 ; else if ( az >= 360 ) az -= 360 ;
	if ( el < -90 ) el = -90 ; else if ( el > 90 ) el = 90 ;
	
	[ azimuthStepper setIntValue:az ] ;
	[ azimuthField setIntValue:az ] ;
	[ elevationStepper setIntValue:el ] ;
	[ elevationField setIntValue:el ] ;
	
	[ self refreshGeometry ] ;
}

- (void)showRecenterButton
{
	//  show centerButton
	[ centerButton setHidden:NO ] ;
}

- (void)geometryCenterChanged:(id)sender
{
	[ (GeometryView*)geometryView clearPan ] ;
	//  hide center button
	[ centerButton setHidden:YES ] ;
}

- (void)az3dControlsChanged:(id)sender
{
	int az ;

	if ( sender == azimuth3dStepper ) {
		[ azimuth3dField setIntValue: [ sender intValue ] ] ;
	}
	//  limit travels
	az = [ azimuth3dField intValue ] ;
	if ( az < 0 ) az += 360 ; else if ( az >= 360 ) az -= 360 ;
	
	[ azimuth3dStepper setIntValue:az ] ;
	[ azimuth3dField setIntValue:az ] ;	
	[ pattern3DView setAngle:az ] ;
}

- (void)contrast3dChanged:(id)sender
{
	float contrast ;
	
	contrast = [ contrast3dSlider floatValue ] ;
	[ pattern3DView setContrast:contrast ] ;
	[ [ pattern3dContainer view ] setContrast:contrast ] ;
}

//	"Shape" vs "gain" patterns
- (void)phongChanged:(id)sender
{
	[ pattern3DView setPlotType:[ phongMatrix selectedColumn ] ] ;
}

- (void)updateZ0
{
	OutputContext *p ;
	float swr ;
	
	p = ( usePreviousPatternAsReference ) ? currentContext : referenceContext ;
	swr = [ swrCircle floatValue ] ;
	[ swrView setSWRCircle:swr ] ;
	[ [ swrContainer swrView ] setSWRCircle:swr ] ;
	[ swrView updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
	[ [ swrContainer swrView ] updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
	[ scalarView updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
	[ [ scalarContainer scalarView ] updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
}

- (void)updateSWRCircle
{
	OutputContext *p ;
	
	p = ( usePreviousPatternAsReference ) ? currentContext : referenceContext ;
	[ swrView setSWRCircle:[ swrCircle floatValue ] ] ;
	[ swrView updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
	[ [ swrContainer swrView ] setSWRCircle:[ swrCircle floatValue ] ] ;
	[ [ swrContainer swrView ] updateWithContext:currentContext refContext:p z0:[ Z0 floatValue ] ] ;
}

//  (smaller of the) difference between two angles
static float angleDifference( float angle, float target )
{
	float delta ;
	
	delta = fabs( angle - target ) ;
	if ( delta > 180 ) delta = 360-delta ;
	return delta ;
}

//  draw context into output
- (void)displayContext:(intType)index
{
	OutputContext *context ;
	NSArray *array, *refArray, *arrayOfFeedpoints, *loadArray, *patternElements, *prevArray ;
	FeedpointInfo *feed ;
	RadiationPattern *pattern, *pSelected ;
	PatternElement *patternElement ;
	PatternInfo info ;
	float theta, phi, phiTarget, absThetaTarget, elevationAtMax, angle, peakTheta, power, average, peak, maxGain, fb, fbPeak, fr ;
	double averageGain ;
	int i, j, engine, whichTab ;
    intType count, elementCount, feedpointArrays ;
	char *engineName, *necGround ;
	
	defaultContextIndex = index ;
	//  adjust scroller in cards table nd then let NSTableView fill the table
	[ cardsTable noteNumberOfRowsChanged ] ;
	
	[ cardsTable reloadData ] ;
	
	if ( [ contexts count ] <= 0 ) {
		currentContext =  nil ;
		[ modelList setStringValue:@"" ] ;
		defaultContextIndex = -1 ;
	}
	else {
		currentContext = [ contexts objectAtIndex:index ] ;
		[ modelList setStringValue:[ currentContext source ] ] ;
	}
	context = currentContext ;	
	
	if ( context == nil ) {
		// no context, clear all views except summary
		// SWRView
		[ swrView setSWRCircle:[ swrCircle floatValue ] ] ;
		[ swrView updateWithContext:nil refContext:nil z0:[ Z0 intValue ] ] ;
		[ [ swrContainer swrView ] setSWRCircle:[ swrCircle floatValue ] ] ;
		[ [ swrContainer swrView ] updateWithContext:nil refContext:nil z0:[ Z0 intValue ] ] ;
		// scalarView 
		[ scalarView updateWithContext:nil refContext:nil z0:[ Z0 intValue ] ] ;
		[ [ scalarContainer scalarView ] updateWithContext:nil refContext:nil z0:[ Z0 intValue ] ] ;
		//  nec2 output
		[ listing setString:@"" ] ;
		//  hide or unhide reference indicator (black square)
		[ referenceFlag setHidden:YES ] ;
		[ (GeometryView*)geometryView updateWithArray:nil feedpoints:nil loads:nil exceptions:[ NSArray array ] options:&geometryOptions client:self ] ;
		//  azimuth and elevation plots
		[ azimuthView clearPatterns ] ;
		[ elevationView clearPatterns ] ;
		[ self refreshGeometry ] ;
		//  summary view
		[ summaryAzimuth clearPatterns ] ;
		[ summaryElevation clearPatterns ] ;
		//  print views
		[ azimuthContainer clearPatterns ] ;
		[ elevationContainer clearPatterns ] ;		
		[ summaryContainer clearPatterns ] ;
		return ;
	}
	// feedpoints, ref impedance from option tab view
	[ self updateZ0 ] ;
	
	//  nec2 output	
	if ( context ) {
		//  v0.64
		if ( savedListing != nil ) [ savedListing release ] ;
		savedListing = [ context necOutput ] ;
		if ( savedListing != nil ) [ savedListing retain ] ;
		whichTab = [ [ [ tabMenu selectedTabViewItem ] identifier ] intValue ] ;
		if ( whichTab == 9 && savedListing ) [ listing setString:savedListing ] ;	//  v0.78  (whichtab was 8)
	}

	//  hide or unhide reference indicator (black square)
	[ referenceFlag setHidden:( referenceContext != context ) ] ;	
	//  azimuth plot
	if ( context ) {
		array = [ context azimuthPatterns ] ;
		//  check if we gave a reference or previous pattern
		if ( usePreviousPatternAsReference ) {
			refArray = nil ;
			prevArray = [ context previousAzimuthPatterns ] ;
		}
		else {
			prevArray = nil ;
			if ( referenceContext == nil || context == referenceContext ) refArray = nil ; else refArray = [ referenceContext azimuthPatterns ] ;
		}
        //  update views with pattern data
		[ azimuthView updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		//  companion plot in summary and printSummary
		[ summaryAzimuth updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		[ azimuthContainer updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		[ summaryContainer updateAzimuthPatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		
		//  elevation plots
		array = [ context elevationPatterns ] ;
		//  check if we gave a reference or previous pattern
		if ( usePreviousPatternAsReference ) {
			refArray = nil ;
			prevArray = [ context previousElevationPatterns ] ;
		}
		else {
			prevArray = nil ;
			if ( referenceContext == nil || context == referenceContext ) refArray = nil ; else refArray = [ referenceContext elevationPatterns ] ;
		}
		[ elevationView updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		//  companion plot in summary and printSummary
		[ summaryElevation updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		[ elevationContainer updatePatternWithArray:array refArray:refArray prevArray:prevArray ] ;
		[ summaryContainer updateElevationPatternWithArray:array refArray:refArray prevArray:prevArray ] ;

		//  geometry (only need the first set of feedpoints)
		array = [ context geometryElements ] ;
		arrayOfFeedpoints = [ context arrayOfFeedpoints ] ;
		loadArray = [ context loads ] ;
		if ( [ arrayOfFeedpoints count ] > 0 ) {
			[ (GeometryView*)geometryView updateWithArray:array feedpoints:[ arrayOfFeedpoints objectAtIndex:0 ] loads:loadArray exceptions:[ context exceptions ] options:&geometryOptions client:self ] ;
			[ [ geometryContainer geometryView ] updateWithArray:array feedpoints:[ arrayOfFeedpoints objectAtIndex:0 ] loads:loadArray exceptions:[ context exceptions ] options:&geometryOptions client:self ] ;
		}
		[ self refreshGeometry ] ;
	}
	//  summary - start
	engine = [ [ NSApp delegate ] engine ] ;
	
	//	v0.78
	switch ( engine ) {
	case kNEC41Engine:
		engineName = "NEC-4.1" ;
		break ;
	case kNEC42Engine:
	case kNEC42EngineGN2:				//  v0.80
		engineName = "NEC-4.2" ;
		break ;
	default:
		engineName = "nec2c" ;
		break ;
	}
	
	[ summaryContainer clearText ] ;
	[ self appendSummary:@"---------  " ] ;
	[ self appendSummary:[ DateFormat descriptionWithCalendarFormat:@"Y-M-d HH:mm" ] ] ;
	[ self appendSummary:[ NSString stringWithFormat:@"  ---- (%s) -----\n\n", engineName ] ] ;
	
	if ( context ) {
		//  summary: frequencies
		array = [ context frequencies ] ;
		count = [ array count ] ;
		for ( i = 0; i < count; i++ ) {
			float freq = [ [ array objectAtIndex:i ] doubleValue ] ;
			[ self appendSummary:[ NSString stringWithFormat:@"Frequency %.3f MHz\n", freq ] ] ;
		}
		
		//  summary - feedpoints
		arrayOfFeedpoints = [ context arrayOfFeedpoints ] ;
		feedpointArrays = [ arrayOfFeedpoints count ] ;
		
		//  return first frequency set for NC to use
		if ( feedpointArrays <= 0 ) {
			[ context setFeedpoints:[ NSArray array ] ] ;									//  empty array
		}
		else {
			[ context setFeedpoints:[ arrayOfFeedpoints objectAtIndex:0 ] ] ;				//  first frequency set
		}

		for ( j = 0; j < feedpointArrays; j++ ) {
			array = [ arrayOfFeedpoints objectAtIndex:j ] ;
			count = [ array count ] ;
			for ( i = 0; i < count; i++ ) {
				float vswr, r, zref ;
				complex double num, denom, rho ;
				
				feed = [ (Feedpoint*)[ array objectAtIndex:i ] info ] ;
				zref = [ Z0 floatValue ] ;													//  v0.70
				if ( zref < 0.1 ) zref = 50 ;
				
				num = denom = ( feed->zr + feed->zi*(0.0+1.0fj) ) ;
				num -= zref, denom += zref ;
				rho = num/denom ;
				r = cabs( rho ) ;
				vswr = ( r > 0.99 ) ? 99.0 : ( 1+r )/( 1-r ) ;
				[ self appendSummary:[ NSString stringWithFormat:@"Feedpoint(%d) - Z: (%.3f %s)    I: (%.4f %s)     VSWR(Zo=%.0f Ω): %.1f:1\n", 
						i+1,
						feed->zr, [ [ self imagStr:feed->zi ] UTF8String ],
						feed->cr, [ [ self imagStr4:feed->ci ] UTF8String ],
						zref, vswr
				] ] ;
			}
		}
	}
	//  summary: grounds
	if ( [ context freespace ] ) {
		[ self appendSummary:@"Antenna is in free space.\n" ] ;
	}
	else {
		if ( [ context perfectGround ] ) {
		[ self appendSummary:@"Antenna is on perfect ground.\n" ] ;
		}
		else {
			[ self appendSummary:[ NSString stringWithFormat:@"Ground - Rel. dielectric constant %.3f, conductivity: %.5f mhos/meter.", [ context dielectricConstant ],[ context conductivity ] ] ] ;
			necGround = ( engine == kNEC41Engine || engine == kNEC42Engine || engine == kNEC42EngineGN2 ) ? "(NEC-4 ground)" : "(NEC-2 ground)" ;
			[ self appendSummary:[ NSString stringWithFormat:@" %s\n", ( [ context usesSommerfeld ] ? "(Sommerfeld/Norton)" : necGround ) ] ] ;
		}
	}
	//  directivity pattern if we find one
	array = [ context radiationPatterns ] ;
	count = [ array count ] ;
	pSelected = nil ;
	for ( i = 0; i < count; i++ ) {
		pattern = [ array objectAtIndex:i ] ;
		theta = [ pattern thetaRange ] ;
		phi = [ pattern phiRange ] ;
		if ( theta > 85 && phi > 350 ) {
			if ( pSelected == nil || [ pattern count ] > [ pSelected count ] ) pSelected = pattern ;
		}
	}
	if ( pSelected ) {
		PatternInfo info ;
		average = 0 ;
		peak = -1 ;
		count = [ pSelected count ] ;
		if ( count > 10 ) {
			array = [ pSelected array ] ;
			for ( i = 0; i < count; i++ ) {
				patternElement = [ array objectAtIndex:i ] ;
				info = [ patternElement info ] ;
				power = pow( 10.0, info.dBt/10.0 ) ;
				if ( power > peak ) peak = power ;
				average += power * sin( info.theta*3.1415926535/180. ) ;										//  v0.69
			}
			average = average * [ pSelected dTheta ] * [ pSelected dPhi ] * 3.1415926535 / ( 360.0*360.0 ) ;	//  v0.69
											
			power = 10.*log10( peak/average ) ;
			[ context setDirectivity:power ] ;
			[ [ NSApp delegate ] setDirectivity:power ] ;
			[ self appendSummary:[ NSString stringWithFormat:@"Directivity:  %.2f dB\n", power ] ] ;
		}
	}
	else [ context setDirectivity:-1.0 ] ;
	
	//  3d plot
	[ pattern3DView setPattern:pSelected ] ;
	if ( pSelected ) [ pattern3DView setNeedsDisplay:YES ] ;
	
	//  set efficiency
	[ context setEfficiency ] ;
	double efficiency = [ context efficiency ] ;
	if ( efficiency < 99.999 ) {
		[ self appendSummary:[ NSString stringWithFormat:@"Efficiency:  %.2f%%\n", efficiency ] ] ;
	}

	// gain patterns
	peak = -1000 ;
	theta = 90 ;
	phi = elevationAtMax = 0 ;
	array = [ context radiationPatterns ] ;
	count = [ array count ] ;
	if ( count > 0 ) {
		for ( i = 0; i < count; i++ ) {
			//  each radiation pattern
			pattern = [ array objectAtIndex:i ] ;
			if ( [ pattern maxDBt ] > peak ) {
				peak = [ pattern maxDBt ] ;
				theta = [ pattern thetaAtMaxGain ] ;
				phi = [ pattern phiAtMaxGain ] ;
			}
		}
		//  get elevation angle
		elevationAtMax = theta = 90 - fabs( theta ) ;		//  v0.70
		[ self appendSummary:[ NSString stringWithFormat:@"Max gain: %.2f dBi (azimuth %.0f deg., elevation %.0f deg.)\n", peak, phi, elevationAtMax ] ] ;
		[ context setMaxGain:peak ] ;
		[ context setMaxElevation:theta ] ;
		[ context setMaxAzimuth:phi ] ;
	}
	else {
		[ context setMaxGain:0.0 ] ;
		[ context setMaxElevation:0.0 ] ;
		[ context setMaxAzimuth:0.0 ] ;
	}
	//  front to back ratio (assume max gain at azimuth of phi)
	maxGain = peak ;
	phiTarget = phi+180 ;
	if ( phiTarget >= 360 ) phiTarget -= 360 ;
	peakTheta = 0 ;								//  v0.70
	absThetaTarget = 90 - elevationAtMax ;		//  v0.70 note: theta is measured from zenith, elevation is measured from horizon
	fbPeak = 0 ;								//  v0.70
	peak = -1000 ;
	array = [ context radiationPatterns ] ;
	count = [ array count ] ;
	if ( count > 0 ) {
		for ( i = 0; i < count; i++ ) {
			//  each RadiationPattern
			pattern = [ array objectAtIndex:i ] ;
			patternElements = [ pattern array ] ;
			elementCount =[ patternElements count ] ;
			for ( j = 0; j < elementCount; j++ ) {
				info = [ (PatternElement*)[ patternElements objectAtIndex:j ] info ] ;
				angle = info.phi ;
				if ( info.theta < 0 ) angle = angle + 180 ;
				if ( angle > 360.0 ) angle -= 360.0 ;
				//if ( angleDifference( angle, phiTarget ) < 1.5 ) {
				if ( angleDifference( angle, phiTarget ) < 1.5 ) {
					if ( info.dBt > peak ) {
						//  worst case F/B
						peak = info.dBt ;
						peakTheta = info.theta ;
					}
					if (  angleDifference( angle, phiTarget ) < 0.1 && angleDifference( fabs( info.theta ), absThetaTarget ) < 0.1 ) {
						//  v0.70 F/B at same elevation as front lobe
						fbPeak = info.dBt ;
					}
				}
			}
		}
		fb = maxGain - peak ;
		fbPeak = maxGain - fbPeak ;
		[ self appendSummary:[ NSString stringWithFormat:@"Front-to-back ratio: %.2f dB (elevation %.0f deg)\n", fb, 90-fabs(peakTheta) ] ] ;
		[ self appendSummary:[ NSString stringWithFormat:@"Front-to-back ratio: %.2f dB (elevation of front lobe)\n", fbPeak ] ] ;
		[ context setFrontToBack:fb ] ;
	}
	else {		
		//  clear front to back
		[ context setFrontToBack:0.0 ] ;
	}
	
	//  front-to-rear
	peak = -1000 ;
	array = [ context radiationPatterns ] ;
	count = [ array count ] ;
	if ( count > 0 ) {
		for ( i = 0; i < count; i++ ) {
			//  each RadiationPattern
			pattern = [ array objectAtIndex:i ] ;
			patternElements = [ pattern array ] ;
			elementCount = [ patternElements count ] ;
			for ( j = 0; j < elementCount; j++ ) {
				info = [ (PatternElement*)[ patternElements objectAtIndex:j ] info ] ;
				angle = info.phi ;
				if ( info.theta < 0 ) angle = angle + 180 ;
				if ( angle > 360.0 ) angle -= 360.0 ;
				if ( angleDifference( angle, phiTarget ) < 90 ) {
					if ( info.dBt > peak ) peak = info.dBt ;
				}
			}
		}
		fr = maxGain - peak ;
		[ self appendSummary:[ NSString stringWithFormat:@"Front-to-rear ratio: %.2f dB\n", fr ] ] ;
		[ context setFrontToRear:fr ] ;
	}
	else {		
		//  clear front-to-rear
		[ context setFrontToRear:0.0 ] ;
	}
	
	//  average gain  v0.62
	averageGain = [ context averageGain ] ;
	if ( averageGain > 0.01 ) {
		double absGain = averageGain ;
		if ( averageGain < 1.0 ) absGain = 1.0/averageGain ;
		[ self appendSummary:[ NSString stringWithFormat:@"Average Gain: %.4f (%5.3f dB)\n", averageGain, 10.*log10( absGain ) ] ] ;
	}
	
	//  report elapsed time in NEC engine
	float elapsed = [ context elapsedTime ] ;
	if ( elapsed > 2 ) [ self appendSummary:[ NSString stringWithFormat:@"Compute time: %.1f sec\n", elapsed ] ] ; else [ self appendSummary:[ NSString stringWithFormat:@"Compute time: %.2f sec\n", elapsed ] ] ;
	[ self appendSummary:@"\n" ] ;
	
	//  scroll to make end visible
	//[ summary scrollRangeToVisible:NSMakeRange( [ [ summary textStorage ] length ], 0 ) ] ;	
	intType length = [ [ summary string ] length ] ;
	intType remove = 0 ;
	if ( length > 10000 ) {
		remove = length-10000 ;
		[ summary replaceCharactersInRange:NSMakeRange( 0, remove ) withString:@"" ] ;
	}
	[ summary scrollRangeToVisible:NSMakeRange( length-remove, 0 ) ] ;
}

//	v0.81d added resetContext
- (void)processContext:(intType)index
{
	defaultContextIndex = index ;
	
	[ modelList reloadData ] ;
	[ self displayContext:index ] ;
	[ modelList selectItemAtIndex:index ] ;
}

- (void)refreshView
{
	#ifndef RUNNCINSEPARATETHREAD
	if ( 1 ) {
		//  if NC is running in the main thread, we need to update the views
		switch ( [ tabMenu indexOfTabViewItem:[ tabMenu selectedTabViewItem ] ] ) {
		case 0:
			[ azimuthView display ] ;
			break ;
		case 1:
			[ elevationView display ] ;
			break ;
		case 3:
			[ swrView display ] ;
			break ;
		case 5:
			[ summaryAzimuth display ] ;
			[ summaryElevation display ] ;
			break ;
		}
	}
	#endif
}

- (void)newNEC4OutputFor:(NSString*)name lpt:(NSString*)lpt exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result
{
	OutputContext *context ;
	intType i, count ;
	
	//  first check to see if the context has already been established
	count = [ contexts count ] ;
	for ( i = 0; i < count; i++ ) {
		context = [ contexts objectAtIndex:i ] ;
		if ( [ name isEqualToString:[ context name ] ] ) {
			[ context replaceWithName:name hollerith:nil lpt:lpt source:name exceptions:exceptions geometryOptions:&geometryOptions resetAllArrays:resetContext ] ;
			[ context setRunInfo:result ] ;
			[ self processContext:i ] ;
			[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
			return ;
		}
	}
	context = [ [ NEC4Context alloc ] initWithName:name hollerith:nil lpt:lpt source:name exceptions:exceptions geometryOptions:&geometryOptions ] ;
	[ context setRunInfo:result ] ;
	[ contexts addObject:context ] ;
	count = [ contexts count ] ;
	[ self processContext:count-1 ] ;
	[ modelList setNumberOfVisibleItems:count ] ;
	[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
	return ;
}

- (void)newNEC2COutputFor:(NSString*)name lpt:(NSString*)lpt exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result
{
	OutputContext *context ;
	intType i, count ;
 		
	//  first check to see if the context has already been established
	count = [ contexts count ] ;
	for ( i = 0; i < count; i++ ) {
		context = [ contexts objectAtIndex:i ] ;
		if ( [ name isEqualToString:[ context name ] ] ) {
			[ context replaceWithName:name hollerith:nil lpt:lpt source:name exceptions:exceptions geometryOptions:&geometryOptions resetAllArrays:resetContext ] ;
			[ context setRunInfo:result ] ;
			[ self processContext:i ] ;
			[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
			return ;
		}
	}
	context = [ [ OutputContext alloc ] initWithName:name hollerith:nil lpt:lpt source:name exceptions:exceptions geometryOptions:&geometryOptions ] ;
	[ context setRunInfo:result ] ;
	[ contexts addObject:context ] ;
	count = [ contexts count ] ;
	[ self processContext:count-1 ] ;
	[ modelList setNumberOfVisibleItems:count ] ;
	[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
	return ;
}

- (void)newOutputFor:(NSString*)name hollerith:(NSString*)hollerith lpt:(NSString*)lpt source:(NSString*)source exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result
{
	OutputContext *context ;
	intType i, count, engine ;

	engine = [ [ NSApp delegate ] engine ] ;
	
	//  first check to see if the context has already been established (compare name and engine)
	count = [ contexts count ] ;
	for ( i = 0; i < count; i++ ) {
		context = [ contexts objectAtIndex:i ] ;
		if ( [ name isEqualToString:[ context name ] ] && engine == [ context engine ] ) {
			[ context replaceWithName:name hollerith:hollerith lpt:lpt source:source exceptions:exceptions geometryOptions:&geometryOptions resetAllArrays:resetContext ] ;
			[ context setRunInfo:result ] ;
			[ self processContext:i ] ;
			[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
			return ;
		}
	}
	//  create new context
	switch ( engine ) {
	case kNEC41Engine:
	case kNEC42Engine:		//  v0.81 was missing in v0.80
	case kNEC42EngineGN2:	//  v0.80
		context = [ [ NEC4Context alloc ] initWithName:name hollerith:hollerith lpt:lpt source:source exceptions:exceptions geometryOptions:&geometryOptions ] ;
		break ;
	default:
		context = [ [ OutputContext alloc ] initWithName:name hollerith:hollerith lpt:lpt source:source exceptions:exceptions geometryOptions:&geometryOptions ] ;
	}
	[ context setRunInfo:result ] ;
	[ contexts addObject:context ] ;
	count = [ contexts count ] ;
	[ self processContext:count-1 ] ;
	[ modelList setNumberOfVisibleItems:count ] ;
	[ self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:YES ] ;
	return ;
}

- (void)switchContext
{
	intType index, count ;
	
	count = [ contexts count ] ;
	if ( count <= 0 ) {
		[ self displayContext:0 ] ;
		return ;
	}	
	index = [ modelList indexOfSelectedItem ] ;
	if ( index >= 0 && index < count ) {
		if ( currentContext != [ contexts objectAtIndex:index ] ) {
			[ self displayContext:index ] ;
		}
	}
}

- (Boolean)hasModel 
{
	return ( [ contexts count ] > 0 ) ;
}

- (void)useAsReference
{
	if ( currentContext == nil ) {
		[ AlertExtension modalAlert:@"No output to set as Reference." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nYou can only set the Reference to an opened output model.\n" ] ;
		return ;
	}
	referenceContext = currentContext ;
	usePreviousPatternAsReference = NO ;
	[ self switchContext ] ;		// refreshes context
	[ referenceFlag setHidden:NO ] ;
}

- (void)usePreviousRunAsReference
{
	referenceContext = nil ;
	[ referenceFlag setHidden:YES ] ;
	usePreviousPatternAsReference = YES ;
	[ self switchContext ] ;		// refreshes context
}

- (void)removeCurrentReference
{
	referenceContext = nil ;
	usePreviousPatternAsReference = NO ;
	[ referenceFlag setHidden:YES ] ;
}

- (void)gainScaleChanged
{
	double s, scale[] = { 1.118, 1.059998, 1.042572 } ;			// for 2 dB scale factors of 0.80, 0.89 (ARRL) and 0.93
	
	s = scale[ [ gainScaleMatrix selectedRow ] ] ;
	[ azimuthView setGainScale:s ] ;
	[ elevationView setGainScale:s ] ;
	[ pattern3DView setGainScale:s ] ;
	[ summaryAzimuth setGainScale:s ] ;					//  v0.75i
	[ summaryElevation setGainScale:s ] ;				//  v0.75i
}

//	v0.68
- (void)setPlotPolarization:(intType)pol
{
	[ azimuthView setGainPolarization:pol ] ;
	[ elevationView setGainPolarization:pol ] ;
	[ pattern3DView setGainPolarization:pol ] ;
	[ [ pattern3dContainer view ] setGainPolarization:pol ] ;	//  v0.70
	[ summaryAzimuth setGainPolarization:pol ] ;				//  v0.67
	[ summaryElevation setGainPolarization:pol ] ;				//  v0.67
}

//	v0.68 V+H, L+R
- (void)gainPolarizationChanged
{
	intType pol ;
	NSButton *radioButton ;
	
	radioButton = [ gainPolarizationMatrix selectedCell ] ;  // 0.75i
	pol = [ radioButton tag ] ;			// 0 - vert, 1 - horiz, 2 - total, 3 - LHCP, 4 - RHCP, 5 - V+H, 6 - L+R
	[ self setPlotPolarization:pol ] ;
	[ [ NSApp delegate ] setPolarizationMenu:pol ] ;
}

- (void)polarizationChanged:(intType)pol
{
	[ gainPolarizationMatrix selectCellWithTag:pol ] ;
	[ self setPlotPolarization:pol ] ;
}

//  modelList comboBox
- (intType)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
	intType count ;
	
	if ( comboBox == modelList ) {
		count = [ contexts count ] ;
		return count ;
	}
	return 0 ;
}

//  modelList comboBox
- (id)comboBox:(NSComboBox*)comboBox objectValueForItemAtIndex:(intType)index
{
	OutputContext *context ;
	
	if ( comboBox == modelList ) {
		
		//  sanity check: first check if we have any active contexts, if so return blank
		intType numberOfContexts = [ contexts count ] ;
		if ( numberOfContexts <= 0 ) return @"" ;
		
		if ( index < 0 && defaultContextIndex >= 0 ) {
			context = [ contexts objectAtIndex:defaultContextIndex ] ;
			if ( context == nil || [ context source ] == nil ) {
				printf( "default source or context %ld disappeared?\n", (long)context ) ;
				return @"" ;
			}
			return [ context source ] ;
		}
		else if ( index >= 0 && index < [ contexts count ] ) {
			context = [ contexts objectAtIndex:index ] ;
			if ( context == nil || [ context source ] == nil ) {
				printf( "source or context %ld disappeared?\n", (long)context ) ;
				return @"" ;
			}
			return [ context source ] ;
		}
	}
	return @"" ;
}

//  cards TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	OutputContext *context ;
	
	if ( tableView == cardsTable ) {
		if ( [ contexts count ] <= 0 ) return 0 ;	//  nothing yet
		context = [ contexts objectAtIndex:defaultContextIndex ] ;
		return [ [ context hollerithCards ] count ] ;
	}
	return 0 ;
}

//  cards TableView
- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	OutputContext *context ;
	NSArray *array ;
	
	if ( tableView == cardsTable ) {
		if ( tableColumn == hollerithCardColumn ) {
			if ( defaultContextIndex >= 0 ) {
				if ( row < 0 ) row = 0 ;
				context = [ contexts objectAtIndex:defaultContextIndex ] ;
				array = [ context hollerithCards ] ;
				return [ array objectAtIndex:row ] ;
			}
		}
		return [ NSString stringWithFormat:@"%d", row+1 ] ;
	}
	return @"" ;
}

- (void)openWindow
{
	[ window makeKeyAndOrderFront:self ] ;
}

- (IBAction)openColorOptions:(id)sender
{
	int which ;
	
	which = [ [ [ tabMenu selectedTabViewItem ] identifier ] intValue ] ;
	switch ( which ) {
	case kAzimuthTab:
	case kElevationTab:
	case kSummaryID:
		[ colorWindow orderFront:self ] ; 
		break ;
	case kSWRTab:
		[ swrView openColorManager ] ;
		break ;
	case kScalarTab:
	case kGeometryTab:
	case k3DTab:
	case kCardsTab:
	case kNECListTab:
		NSBeep() ;
		break ;
	}
}

//	v0.70 changes to fix many printing problems
//	v0.70 separate printing views are now used for some of the tab views to include auxilary information (colors, etc)
- (IBAction)printView:(id)sender
{
    intType count, which ;
    NSInteger result ;
	NSPrintInfo *printInfo ;
	
	if ( ![ window isVisible ] ) {
		[ AlertExtension modalAlert:@"Output window is not open." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nTo print an output view, the output window must be open and tabbed to the output view that you wish to print.\n\nSelect Output Viewer in the Window Menu.\n" ] ;
		return ;
	}
	count = [ contexts count ] ;
	if ( count <= 0 ) {
		[ AlertExtension modalAlert:@"Output window is empty." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThere is no antenna model present in the output window.\n" ] ;
		return ;
	}
	printInfo = [ NSPrintInfo sharedPrintInfo ] ;
	[ printInfo setLeftMargin:35.0 ] ;
	[ printInfo setRightMargin:35.0 ] ;
	[ printInfo setTopMargin:35.0 ] ;
	[ printInfo setBottomMargin:35.0 ] ;
	
	which = [ [ [ tabMenu selectedTabViewItem ] identifier ] intValue ] ;
	switch ( which ) {
	case kAzimuthTab:
		if ( azimuthContainer ) [ azimuthContainer printWithInfo:printInfo output:self ] ;
		break ;
	case kElevationTab:
		if ( elevationContainer ) [ elevationContainer printWithInfo:printInfo output:self ] ;
		break ;
	case k3DTab:
		if ( pattern3dContainer ) [ pattern3dContainer printWithInfo:printInfo output:self ] ;
		break ;
	case kSWRTab:
		if ( swrContainer  && swrView ) {
			[ swrContainer printWithInfo:printInfo output:self ] ;
			[ swrView setNeedsDisplay:YES ] ; // v0.70 draw SWRView one when done, to remove overdraws when print panel obscures view
		}
		break ;
	case kScalarTab:
		if ( scalarContainer ) {
			//  first make the scalarContainer's scrollview match that of the GUI version
			[ [ scalarContainer scalarView ] setScrollOffset:[ scalarView scrollOffset ] ] ;
			[ scalarContainer printWithInfo:printInfo output:self ] ;
		}
		break ;
	case kGeometryTab:
		if ( geometryContainer ) [ geometryContainer printWithInfo:printInfo output:self ] ;
		break ;
	case kSummaryID:
		//  To avoid the scrollview in summaryBox (the GUI), use a separate NSView (printSummary) to print
		//	The printSummary view contains a non scrolling text view that has the most recent summary.
		if ( summaryContainer ) [ summaryContainer printWithInfo:printInfo output:self ] ;
		break ;
	case kCardsTab:
		if ( cardsTable ) {
			[ cardsTable display ] ;									//  sometimes needed to get more than one page of output
			[ printInfo setHorizontalPagination:NSClipPagination ] ;	//  discard right side of table view that extends more than 80 columns
			[ printInfo setLeftMargin:50.0 ] ;
			[ printInfo setRightMargin:25.0 ] ;
			[ cardsTable print:self ] ;
		}
		break ;
	case kNECListTab:
		result = [ AlertExtension modalAlert:@"Warning: large output." defaultButton:@"Cancel" alternateButton:@"Print" otherButton:nil informativeTextWithFormat:@"\nYou are asking for a large file to be printed.  Do you really want to print the NEC-2 output listing?.\n" ] ;
		if ( result == NSModalResponseOK && lineprinterContainer ) [ lineprinterContainer printWithInfo:printInfo output:self ] ;
		/*
			[ printInfo setHorizontalPagination:NSFitPagination ] ;
			[ printListingView setFont:[ NSFont fontWithName: @"Monaco" size:10.0 ] ] ;
			container = [ printListingView textContainer ] ;
			[ container setContainerSize:NSMakeSize( 700.0, 1e12 ) ] ;
			[ printListingView setString:savedListing ] ;
			[ printListingView print:self ] ;
		*/
		break ;
	default:
		[ AlertExtension modalAlert:@"Not implemented." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nPrinting of this tab view is not (yet) implemented.\n" ] ;
		break ;
	}
}

- (IBAction)removeContext:(id)sender
{
    intType index, n, indexToRemove, numberOfContexts = [ contexts count ] ;
	OutputContext *context ;
	
	if ( numberOfContexts > 0 ) {
		indexToRemove = [ modelList indexOfSelectedItem ] ;

		// note, if there has not been previous selections, the ComboBox will return -1	
		if ( indexToRemove == -1 ) indexToRemove = defaultContextIndex ;
		if ( indexToRemove == -1 ) return ;	// should not happen
		
		if ( indexToRemove >= 0 && indexToRemove < numberOfContexts ) {
			context = [ contexts objectAtIndex:indexToRemove ] ;
			if ( context == referenceContext ) [ self removeCurrentReference ] ;
			[ contexts removeObjectAtIndex:indexToRemove ] ;
			n = [ contexts count ] ;
			[ modelList setNumberOfVisibleItems:n ] ;
			[ modelList reloadData ] ;
			
			//  refresh window with an older context
			index = indexToRemove - 1 ;
			if ( index < 0 ) index = 0 ;
			[ self displayContext:index ] ;
		}
	}
}

- (IBAction)openOptions:(id)sender
{
	if ( optionsDrawer == nil ) return ;
	
	switch ( [ optionsDrawer state ] ) {
	case NSDrawerOpenState:
		[ optionsDrawer close ] ;
		break ;
	default:
		[ optionsDrawer open ] ;
		break ;
	}
}

- (const char*)filename
{
	return [ [ currentContext source ] UTF8String ] ;
}

- (Boolean)drawBorders
{
	return ( [ drawBordersCheckbox state ] == NSOnState ) ;
}

- (Boolean)drawBackgrounds
{
	return ( [ drawBackgroundsCheckbox state ] == NSOnState ) ;
}

- (Boolean)drawFilenames
{
	return ( [ drawFilenamesCheckbox state ] == NSOnState ) ;
}

- (NSDictionary*)smallFontAttributes
{
	return smallFontAttributes ;
}

- (NSDictionary*)mediumFontAttributes
{
	return mediumFontAttributes ;
}

- (void)updatePrefsFromDict:(NSDictionary*)plist 
{
	NSDictionary *dict ;
	NSString *string ;
	NSNumber *state, *number ;
	NSArray *colorArray ;
	NSColor *color ;
	intType n ;
    int i ;
	
	dict = [ plist objectForKey:kOutputWindow ] ;
	if ( dict ) {
		string = [ dict objectForKey:kWindowPosition ] ;
		if ( string ) [ window setFrameFromString:string ] ;
		string = [ dict objectForKey:kReferenceZ ] ;
		if ( string ) [ Z0 setStringValue:string ] ;
		string = [ dict objectForKey:kSWRCircle ] ;
		if ( string ) {
			[ swrCircle setStringValue:string ] ;
			[ swrView setSWRCircle:[ string floatValue ] ] ;
		}
		//  v0.70 Printing options
		state = [ dict objectForKey:kDrawBorders ] ;
		if ( state ) [ drawBordersCheckbox setState:( [ state boolValue ] ? NSOnState : NSOffState ) ] ;
		state = [ dict objectForKey:kDrawBackgrounds ] ;
		if ( state ) [ drawBackgroundsCheckbox setState:( [ state boolValue ] ? NSOnState : NSOffState ) ] ;
		state = [ dict objectForKey:kDrawFilenames ] ;
		if ( state ) [ drawFilenamesCheckbox setState:( [ state boolValue ] ? NSOnState : NSOffState ) ] ;
		//	v0.70 SWR feedpoint colors
		colorArray = [ dict objectForKey:kSWRColors ] ;
		if ( colorArray != nil ) {
			n = [ colorArray count ] ;
			if ( n > 16 ) n = 16 ;
			for ( i = 0; i < n; i++ ) {
				color = [ NSUnarchiver unarchiveObjectWithData:[ colorArray objectAtIndex:i ] ] ;
				if ( color != nil ) {
					[ swrView setWellColor:i color:color ] ;
					[ [ swrContainer swrView ] setWellColor:i color:color ] ;
				}
			}
		}
		// v0.70 Radiation pattern colors
		colorArray = [ dict objectForKey:kRadiationColors ] ;
		if ( colorArray ) {
			n = [ colorArray count ] ;
			if ( n > MAXCOLORWELLS ) n = MAXCOLORWELLS ;
			for ( i = 0; i < n; i++ ) {
				color = [ NSUnarchiver unarchiveObjectWithData:[ colorArray objectAtIndex:i ] ] ;
				[ colorWells.colorWell[i] setColor:color ] ;
			}
			[ self updateRadiationPatternColorWells ] ;
		}
		state = [ dict objectForKey:kSWRInterpolate ] ;
		if ( state ) {
			[ swrView setInterpolate:[ state boolValue ] ] ;
			[ [ swrContainer swrView ] setInterpolate:[ state boolValue ] ] ;
		}
		state = [ dict objectForKey:kSWRSmartInterpolate ] ;
		if ( state ) {
			[ swrView setSmartInterpolate:[ state boolValue ] ] ;
			[ [ swrContainer swrView ] setSmartInterpolate:[ state boolValue ] ] ;
		}
		state = [ dict objectForKey:kScalarInterpolate ] ;
		if ( state ) {
			[ scalarView setInterpolate:[ state boolValue ] ] ;
			[ [ scalarContainer scalarView ] setInterpolate:[ state boolValue ] ] ;
		}
		//	v0.81d
		number = [ dict objectForKey:kDrawDistributedLoads ] ;
		if ( number != nil ) {
			[ drawDistributedLoadsCheckbox setState:( [ number boolValue ] ? NSOnState : NSOffState ) ] ;
		}

	}
}

- (void)savePrefsToPlist:(NSMutableDictionary*)plist
{
	NSMutableDictionary *dict ;
	NSMutableArray *colorArray ;
	int i ;
	
	dict = [ NSMutableDictionary dictionary ] ;
	if ( dict ) {
		[ dict setObject:[ window stringWithSavedFrame ] forKey:kWindowPosition ] ;
		[ dict setObject:[ Z0 stringValue ] forKey:kReferenceZ ] ;
		[ dict setObject:[ swrCircle stringValue ] forKey:kSWRCircle ] ;
		//  v0.70 printing options
		[ dict setObject:[ NSNumber numberWithBool:( [ drawBordersCheckbox state ] == NSOnState ) ] forKey:kDrawBorders ] ;
		[ dict setObject:[ NSNumber numberWithBool:( [ drawBackgroundsCheckbox state ] == NSOnState ) ] forKey:kDrawBackgrounds ] ;
		[ dict setObject:[ NSNumber numberWithBool:( [ drawFilenamesCheckbox state ] == NSOnState ) ] forKey:kDrawFilenames ] ;
		//  v0.70 save colors
		//  colorArray is a list of NSArchiver objects for NSColor, because NSDictionary cannot store NSColors
		colorArray = [ NSMutableArray array ] ;
		for ( i = 0; i < MAXCOLORWELLS; i++ ) [ colorArray addObject:[ NSArchiver archivedDataWithRootObject:[ swrView wellColor:i ] ] ] ;
		[ dict setObject:colorArray forKey:kSWRColors ] ;

		colorArray = [ NSMutableArray array ] ;
		for ( i = 0; i < MAXCOLORWELLS; i++ ) {
			[ colorArray addObject:[ NSArchiver archivedDataWithRootObject:[ colorWells.colorWell[i] color ] ] ] ;
		}
		[ dict setObject:colorArray forKey:kRadiationColors ] ;
		
		[ dict setObject:[ NSNumber numberWithBool:( [ drawDistributedLoadsCheckbox state ] == NSOnState ) ] forKey:kDrawDistributedLoads ] ;	//  v0.81d
		[ dict setObject:[ NSNumber numberWithBool:[ swrView doInterpolate ] ] forKey:kSWRInterpolate ] ;
		[ dict setObject:[ NSNumber numberWithBool:[ swrView doSmartInterpolate ] ] forKey:kSWRSmartInterpolate ] ;
		[ dict setObject:[ NSNumber numberWithBool:[ scalarView doInterpolate ] ] forKey:kScalarInterpolate ] ;
		[ plist setObject:dict forKey:kOutputWindow ] ;
	}
}

//	v0.78
- (OutputContext*)currentContext
{
	return currentContext ;
}

@end
