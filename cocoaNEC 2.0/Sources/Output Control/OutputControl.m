//
//  OutputControl.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/26/07.
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

#import "OutputControl.h"
#import "Bundle.h"

@implementation OutputControl


- (id)init
{
	self = [ super init ] ;
	if ( self ) {
        
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"OutputControl" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;

		controllingWindow = nil ;
	}
	return self ;
}

- (void)awakeFromNib
{
	azimuthMatrix[0] = azimuth0Matrix ;
	azimuthMatrix[1] = azimuth1Matrix ;
	azimuthMatrix[2] = azimuth2Matrix ;
	elevationMatrix[0] = elevation0Matrix ;
	elevationMatrix[1] = elevation1Matrix ;
	elevationMatrix[2] = elevation2Matrix ;
	
	// make sheet opaque
	[ window setAlphaValue:1.0 ] ;
}

- (void)setDefaultPattern:(Boolean)seton
{
	int i ;
	
	for ( i = 0; i < 3; i++ ) {
		 [ azimuthMatrix[i] selectCellAtRow:0 column:0 ] ;
		 [ elevationMatrix[i] selectCellAtRow:0 column:0 ] ;
	}
	if ( seton ) {
		 [ azimuthMatrix[1] selectCellAtRow:0 column:1 ] ;
		 [ elevationMatrix[0] selectCellAtRow:0 column:1 ] ;
	}
}

// angles > 1000 == no azimuth plot
- (float*)elevationAnglesForAzimuthPlot
{
	int i ;
	
	for ( i = 0; i < 3; i++ ) {
		if ( [ azimuthMatrix[i] selectedColumn ] == 0 ) elevationAngles[i] = 1001 ; 
		else {
			elevationAngles[i] = [ [ elevationAngle cellAtRow:i column:0 ] floatValue ] ;
		}
	}
	return elevationAngles ;
}

// angles > 1000 == no elevation plot
- (float*)azimuthAnglesForElevationPlot
{
	int i ;
	
	for ( i = 0; i < 3; i++ ) {
		if ( [ elevationMatrix[i] selectedColumn ] == 0 ) azimuthAngles[i] = 1001 ; 
		else {
			azimuthAngles[i] = [ [ azimuthAngle cellAtRow:i column:0 ] floatValue ] ;
		}
	}
	return azimuthAngles ;
}

- (int)numberOfAzimuthPlots
{
	int i, count ;
	
	count = 0 ;
	for ( i = 0; i < 3; i++ ) {
		if ( [ azimuthMatrix[i] selectedColumn ] != 0 ) count++ ;
	}
	return count ;
}

- (int)numberOfElevationPlots
{
	int i, count ;
	
	count = 0 ;
	for ( i = 0; i < 3; i++ ) {
		if ( [ elevationMatrix[i] selectedColumn ] != 0 ) count++ ;
	}
	return count ;
}

- (float)azimuthDistance
{
	float v ;
	
	v = fabs( [ azimuthDistance floatValue ] ) ;
	if ( v < 0.1 ) v = 0.1 ;
	return v ;
}

- (float)elevationDistance
{
	float v ;
	
	v = fabs( [ elevationDistance floatValue ] ) ;
	if ( v < 0.1 ) v = 0.1 ;
	return v ;
}

- (Boolean)isQuadPrecision
{
	return ( [ [ precisionMatrix selectedCell ] tag ] == 1 ) ;
}

- (Boolean)isExtendedkernel
{
	return ( [ [ ekMatrix selectedCell ] tag ] == 1 ) ;
}

- (Boolean)is3DSelected
{
	return ( [ [ d3Matrix selectedCell ] tag ] == 1 ) ;
}

- (void)showSheet:(NSWindow*)mainWindow
{
	controllingWindow = mainWindow ;
    
    //  v0.88 beginsheet deprecated
	//  [ NSApp beginSheet:window modalForWindow:controllingWindow modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;

    [ controllingWindow beginSheet:window completionHandler:nil ] ;
}

- (IBAction)closeSheet:(id)sender
{
	if ( controllingWindow ) {
		[ NSApp endSheet:window ] ;
		[ window orderOut:controllingWindow ] ;
		controllingWindow = nil ;
	}
}

- (NSMutableDictionary*)makeDictionaryForPlist 
{
	NSMutableDictionary *plist ;
	NSArray *array ;

	plist = [ [ NSMutableDictionary alloc ] init ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ precisionMatrix selectedColumn ] == 1 ) ] forKey:@"quad precision" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ ekMatrix selectedColumn ] == 1 ) ]  forKey:@"extended kernel" ] ;

	[ plist setObject:[ NSNumber numberWithBool:( [ azimuth0Matrix selectedColumn ] == 1 ) ] forKey:@"azimuth plot 1" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ azimuth1Matrix selectedColumn ] == 1 ) ] forKey:@"azimuth plot 2" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ azimuth2Matrix selectedColumn ] == 1 ) ] forKey:@"azimuth plot 3" ] ;
	[ plist setObject:[ azimuthDistance stringValue ] forKey:@"azimuth distance" ] ;
	array = [ NSArray arrayWithObjects:
		[ [ elevationAngle cellAtRow:0 column:0 ] stringValue ],
		[ [ elevationAngle cellAtRow:1 column:0 ] stringValue ],
		[ [ elevationAngle cellAtRow:2 column:0 ] stringValue ],
		nil ] ;		
	[ plist setObject:array forKey:@"elevation angles" ] ;
	
	[ plist setObject:[ NSNumber numberWithBool:( [ elevation0Matrix selectedColumn ] == 1 ) ] forKey:@"elevation plot 1" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ elevation1Matrix selectedColumn ] == 1 ) ] forKey:@"elevation plot 2" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ elevation2Matrix selectedColumn ] == 1 ) ] forKey:@"elevation plot 3" ] ;
	[ plist setObject:[ elevationDistance stringValue ] forKey:@"elevation distance" ] ;
	array = [ NSArray arrayWithObjects:
		[ [ azimuthAngle cellAtRow:0 column:0 ] stringValue ],
		[ [ azimuthAngle cellAtRow:1 column:0 ] stringValue ],
		[ [ azimuthAngle cellAtRow:2 column:0 ] stringValue ],
		nil ] ;		
	[ plist setObject:array forKey:@"azimuth angles" ] ;


	return plist ;
}

- (void)restoreFromDictionary:(NSDictionary*)dict
{	
	NSArray *array ;
	
	if ( [ dict objectForKey:@"quad precision" ] ) {
		[ precisionMatrix selectCellAtRow:0 column:[ [ dict objectForKey:@"quad precision" ] boolValue ] ? 1 : 0 ] ;
		[ ekMatrix selectCellAtRow:0 column:[ [ dict objectForKey:@"extended kernel" ] boolValue ] ? 1 : 0 ] ;

		[ azimuth0Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"azimuth plot 1" ] boolValue ] ? 1 : 0 ] ;
		[ azimuth1Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"azimuth plot 2" ] boolValue ] ? 1 : 0 ] ;
		[ azimuth2Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"azimuth plot 3" ] boolValue ] ? 1 : 0 ] ;
		[ azimuthDistance setStringValue:[ dict objectForKey:@"azimuth distance" ] ] ;
		
		array = [ dict objectForKey:@"elevation angles" ] ;
		if ( array ) {
			[ [ elevationAngle cellAtRow:0 column:0 ] setStringValue: [ array objectAtIndex:0 ] ] ;
			[ [ elevationAngle cellAtRow:1 column:0 ] setStringValue: [ array objectAtIndex:1 ] ] ;
			[ [ elevationAngle cellAtRow:2 column:0 ] setStringValue: [ array objectAtIndex:2 ] ] ;
		}	

		[ elevation0Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"elevation plot 1" ] boolValue ] ? 1 : 0 ] ;
		[ elevation1Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"elevation plot 2" ] boolValue ] ? 1 : 0 ] ;
		[ elevation2Matrix selectCellAtRow:0 column:[ [ dict objectForKey:@"elevation plot 3" ] boolValue ] ? 1 : 0 ] ;
		[ elevationDistance setStringValue:[ dict objectForKey:@"elevation distance" ] ] ;
		
		array = [ dict objectForKey:@"azimuth angles" ] ;
		if ( array ) {
			[ [ azimuthAngle cellAtRow:0 column:0 ] setStringValue: [ array objectAtIndex:0 ] ] ;
			[ [ azimuthAngle cellAtRow:1 column:0 ] setStringValue: [ array objectAtIndex:1 ] ] ;
			[ [ azimuthAngle cellAtRow:2 column:0 ] setStringValue: [ array objectAtIndex:2 ] ] ;
		}	
	}
}

- (void)dealloc
{
    [ retainedNibObjects release ] ;
    [ super dealloc ] ;
}

@end
