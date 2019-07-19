//
//  Environment.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/15/07.
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

#import "Environment.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "ControlCard.h"
#import "NewArray.h"
#import "Spreadsheet.h"


@implementation Environment

@synthesize window ;

//  parameters are keys in an NSMutableDictionary

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		rows = 0 ;
		numberColumn = hollerithColumn = commentColumn = ignoreColumn = nil ;
		controlCards = newArray() ;
		parameter = [ [ NSMutableDictionary alloc ] init ] ;
		controllingWindow = nil ;
		frequencyArray = newArray() ;
		commentsArray = newArray() ;
		radialsArray = newArray() ;
		radialsX = [ [ NSString alloc ] initWithString:@"" ] ;
		radialsY = [ radialsX retain ] ;
		radialsZ = [ radialsX retain ] ;
		selectedRadials = 0 ;
		hasWarned = NO ;
		//constEvaluator = [ [ Expression alloc ] init ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ controlCards release ] ;
	[ frequencyArray release ] ;
	[ commentsArray release ] ;
	[ radialsArray release ] ;
	//[ constEvaluator release ] ;
	[ super dealloc ] ;
}

//	(Private API)
- (void)setDirty
{
	if ( client != nil ) [ client setDirty ] ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)setFrequencySelection
{
	intType row ;
	Boolean selectSingle, selectSweep, selectMultiple ;
	
	row = [ freqMatrix selectedRow ] ;
	
	switch (row ) {
	case 0:
	default:
		selectSingle = YES ;
		selectSweep = NO ;
		selectMultiple = NO ;
		break ;
	case 1:
		selectSingle = NO ;
		selectSweep = YES ;
		selectMultiple = NO ;
		break ;
	case 2:
		selectSingle = NO ;
		selectSweep = NO ;
		selectMultiple = YES ;
		break ;
	}
	[ freqField setEnabled:selectSingle ] ;
	[ freqLowField setEnabled:selectSweep ] ;
	[ freqHighField setEnabled:selectSweep ] ;
	[ freqStepField setEnabled:selectSweep] ;
	[ linearCheckBox setEnabled:selectSweep ] ;
	[ f1Field setEnabled:selectMultiple ] ;
	[ f2Field setEnabled:selectMultiple ] ;
	[ f3Field setEnabled:selectMultiple ] ;
	[ f4Field setEnabled:selectMultiple ] ;
}

- (void)awakeFromNib
{
	NSArray *column = [ table tableColumns ] ;

	numberColumn = [ column objectAtIndex:0 ] ;
	hollerithColumn = [ column objectAtIndex:1 ] ;
	ignoreColumn = [ column objectAtIndex:2 ] ;
	commentColumn = [ column objectAtIndex:3 ] ;
	
	// make sheet opaque
	[ window setAlphaValue:1.0 ] ;

	//  inline control cards
	[ table setDelegate:self ] ;
	[ table setDataSource:self ] ;
	
	//  ground
	[ self setInterface:groundMenu to:@selector(groundMenuChanged) ] ;
	[ self setInterface:sommerfeldCheckbox to:@selector(groundMenuChanged) ] ;
	[ self setGroundMenu ] ;
	
	// frequency
	[ self setFrequencySelection ] ;
	
	[ self setInterface:freqField to:@selector(frequencyFieldChanged) ] ;
	
	// radials
	[ self setInterface:radialsMatrix to:@selector(radialsMatrixChanged) ] ;
	[ self setRadialsMatrix ] ;
}

- (void)setDoubleValue:(double)value forKey:(NSString*)key
{
	[ parameter setObject:[ NSNumber numberWithDouble:value ] forKey:key ] ;
}

- (void)setDictionary
{
	double freq, dielec, cond ;
	Spreadsheet *eval ;
	
	eval = [ (ApplicationDelegate*)[ NSApp delegate ] currentSpreadsheet ] ;
	
	freq = [ eval doubleValueForObject:freqField ] ;
	[ self setDoubleValue:freq forKey:@"g_frequency" ] ;
	if ( freq < .000001 ) freq = .000001 ;
	
	[ self setDoubleValue:299.792459/freq forKey:@"g_wavelength" ] ;
	
	dielec = [ eval doubleValueForObject:dielectricField ] ;
	[ self setDoubleValue:dielec forKey:@"g_dielectric" ] ;

	cond = [ eval doubleValueForObject:conductivityField ] ;
	[ self setDoubleValue:cond forKey:@"g_conductivity" ] ;

	[ self setDoubleValue:3.14159265358979323 forKey:@"g_pi" ] ;
	[ self setDoubleValue:299.792459 forKey:@"g_c" ] ;
	
	[ client dictionaryChanged ] ;
}

- (void)updateDictionary
{
	[ self setDirty ] ;
	[ self setDictionary ] ;
}

- (NSArray*)frequencyArray
{
	int i, n ;
    intType row ;
	double freq, high, incr, swap ;
	Spreadsheet *eval ;
	
	eval = [ (ApplicationDelegate*)[ NSApp delegate ] currentSpreadsheet ] ;
	
	row = [ freqMatrix selectedRow ] ;
	[ frequencyArray removeAllObjects ] ;
	
	switch ( row ) {
	case 0:
	default:
		freq = [ eval doubleValueForObject:freqField ] ;
		[ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
		break ;
	case 1:
		n = [ freqStepField intValue ] ;
		if ( n < 1 ) n = 1 ; else if ( n > 16 ) n = 16 ;
		
		freq = [ eval doubleValueForObject:freqLowField ] ;
		
		if ( [ linearCheckBox state ] == NSOnState ) {
			// linear
			if ( n == 1 ) incr = 0.0 ; 
			else {
				high = [ eval doubleValueForObject:freqHighField ] ;

				if ( freq > high ) {
					swap = high ;
					high = freq ;
					freq = swap ;
				}
				incr = ( high - freq )/( n-1.0 ) ;
			}
			for ( i = 0; i < n; i++ ) {
				[ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
				freq += incr ;
			}
		}
		else {
			// geometric
			if ( n == 1 ) incr = 1.0 ; 
			else {
				high = [ eval doubleValueForObject:freqHighField ] ;
				if ( freq > high ) {
					swap = high ;
					high = freq ;
					freq = swap ;
				}
				incr = pow( high/freq, 1.0/( n-1.0 ) ) ;
			}
			for ( i = 0; i < n; i++ ) {
				[ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
				freq *= incr ;
			}
		}
		break ;
	case 2:
		freq = [ eval doubleValueForObject:f1Field ] ;
		if ( freq > 0.1 ) [ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;

		freq = [ eval doubleValueForObject:f2Field ] ;
		if ( freq > 0.1 ) [ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
		
		freq = [ eval doubleValueForObject:f3Field ] ;
		if ( freq > 0.1 ) [ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
		
		freq = [ eval doubleValueForObject:f4Field ] ;
		if ( freq > 0.1 ) [ frequencyArray addObject:[ NSNumber numberWithDouble:freq ] ] ;
		break ;
	}
	return frequencyArray ;
}

//  dictionary frequency value
- (double)frequency
{
	return [ [ parameter objectForKey:@"g_frequency" ] doubleValue ] ;
}

//  dictionary dielectric constant value
- (double)dielectric
{
	return [ [ parameter objectForKey:@"g_dielectric" ] doubleValue ] ;
}

//  dictionary conductivity value
- (double)conductivity
{
	double conductivity = [ [ parameter objectForKey:@"g_conductivity" ] doubleValue ] ;
	if ( conductivity < .00001 )  conductivity = .00001 ;
	return conductivity ;
}

//  NSDataSource method
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView != table ) return 0 ;
	return rows ;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView == table ) {
		ControlCard *card = [ controlCards objectAtIndex:row ] ;	
		
		if ( tableColumn == numberColumn ) return [ NSString stringWithFormat:@"%d", row+1 ] ;
		if ( tableColumn == hollerithColumn ) return [ card hollerith ] ;
		if ( tableColumn == ignoreColumn ) return [ card ignoreField ] ;
		if ( tableColumn == commentColumn ) return [ card comment ] ;
	}
	return @"" ;
}

- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	NSArray *column ;
	ControlCard *card ;
	
	if ( tableView != table ) return ;
	
	column = [ table tableColumns ] ;
	card = [ controlCards objectAtIndex:row ] ;
	
	if ( tableColumn == hollerithColumn ) {
		[ card setHollerith:object ] ;
		return ;
	}
	if ( tableColumn == ignoreColumn ) {
		[ card setIgnore:object ] ;
		return ;
	}
	if ( tableColumn == commentColumn ) {
		[ card setComment:object ] ;
		return ;
	}
}

- (void)setHideGroundCaptions:(Boolean)hide
{
	[ dielectricField setHidden:hide ] ;
	[ conductivityField setHidden:hide ] ;
	[ dText setHidden:hide ] ;
	[ cText setHidden:hide ] ;
	[ cUnits setHidden:hide ] ;
}

- (Boolean)isFreeSpace
{
	return isFreeSpace ;
}

//  see -updateGroundType
- (int)groundType
{
	return groundType ;
}

//  set ground type to 0 for normal ground, 1 for perfect ground and 2 for Sommerfeld approximation
- (void)updateGroundType:(Boolean)isPerfectGround
{
	groundType = 0 ;
	if ( isPerfectGround ) {
		[ sommerfeldCheckbox setHidden:YES ] ;
		groundType = 1 ;
	}
	else {
		[ sommerfeldCheckbox setHidden:isFreeSpace ] ;
		if ( [ sommerfeldCheckbox state ] == NSOnState ) groundType = 2 ;
	}
	[ self updateDictionary ] ;
}

- (void)setRadialsMatrix
{
	intType selection = [ radialsMatrix selectedRow ] ;
	
	if ( selectedRadials == 1 ) {
		//  save radials coordinates 
		[ radialsX release ] ;
		[ radialsY release ] ;
		[ radialsZ release ] ;
		radialsX = [ [ NSString alloc ] initWithString:[ [ radialsCoordMatrix cellAtRow:0 column:0 ] stringValue ] ] ;
		radialsY = [ [ NSString alloc ] initWithString:[ [ radialsCoordMatrix cellAtRow:1 column:0 ] stringValue ] ] ;
		radialsZ = [ [ NSString alloc ] initWithString:[ [ radialsCoordMatrix cellAtRow:2 column:0 ] stringValue ] ] ;
	}
	
	selectedRadials = selection ;
	switch ( selectedRadials ) {
	case 0:
	default:
		[ radialsCoordMatrix setEnabled:NO ] ;
		[ radialsParamMatrix setEnabled:NO ] ;
		[ [ radialsCoordMatrix cellAtRow:0 column:0 ] setStringValue:@"" ] ;
		[ [ radialsCoordMatrix cellAtRow:1 column:0 ] setStringValue:@"" ] ;
		[ [ radialsCoordMatrix cellAtRow:2 column:0 ] setStringValue:@"" ] ;
		return ;
	case 1:
		[ radialsCoordMatrix setEnabled:YES ] ;
		[ radialsParamMatrix setEnabled:YES ] ;
		[ [ radialsCoordMatrix cellAtRow:0 column:0 ] setStringValue:radialsX ] ;
		[ [ radialsCoordMatrix cellAtRow:1 column:0 ] setStringValue:radialsY ] ;
		[ [ radialsCoordMatrix cellAtRow:2 column:0 ] setStringValue:radialsZ ] ;
		return ;
	case 2:
		[ radialsCoordMatrix setEnabled:NO ] ;
		[ radialsParamMatrix setEnabled:YES ] ;
		[ [ radialsCoordMatrix cellAtRow:0 column:0 ] setStringValue:@"0" ] ;
		[ [ radialsCoordMatrix cellAtRow:1 column:0 ] setStringValue:@"0" ] ;
		[ [ radialsCoordMatrix cellAtRow:2 column:0 ] setStringValue:@"0" ] ;
	}
}

- (void)radialsMatrixChanged
{
	[ self setDirty ] ;
	[ self setRadialsMatrix ] ;
}

- (void)setGroundMenu
{
	double c = 0, er = 0 ;
	Boolean isPerfectGround ;
	NSString *format ;
	Boolean hide ;
	
	hide = isPerfectGround = isFreeSpace = NO ;
	[ self setDirty ] ;
	
	switch ( [ [ groundMenu selectedItem ] tag ] ) {
	case 0:
		//  free space
		c = 0.0 ;
		er = 1.0 ;
		hide = isFreeSpace = YES ;
		break ;
	case 1:
		//  poor ground
		c = 0.001 ;
		er = 3.0 ;
		break ;
	case 2:
		//  average ground
		c = 0.005 ;
		er = 13.0 ;
		break ;
	case 3:
		//  good ground
		c = 0.0303 ;
		er = 20.0 ;
		break ;
	case 4:
		//  perfect ground
		c = 5000.0 ;
		er = 1000.0 ;
		hide = isPerfectGround = YES ;
		break ;
	case 5:
		//  other
		[ dielectricField setEditable:YES ] ;
		[ conductivityField setEditable:YES ] ;
		[ self updateGroundType:NO ] ;
		return ;
	case 6:
		//  fresh water
		c = 0.001 ;
		er = 80.0 ;
		break ;		
	case 7:
		//  salt water
		c = 5.0 ;
		er = 81.0 ;
		break ;
	}
	[ dielectricField setStringValue:[ NSString stringWithFormat:@"%.1f", er ] ] ;
	if ( c == 0 ) {
		[ conductivityField setStringValue:@"0.0" ] ;
	}
	else {
		if ( c < 1.0 ) format = @"%6.4f" ;
		else if ( c < 10.0 ) format = @"%7.3f" ;
		else if ( c < 100.0 ) format = @"%8.2f" ;
		else format = @"%.0f" ;
		[ conductivityField setStringValue:[ NSString stringWithFormat:format, c ] ] ;
	}
	[ self setHideGroundCaptions:hide ] ;
	[ dielectricField setEditable:NO ] ;
	[ conductivityField setEditable:NO ] ;
	[ self updateGroundType:isPerfectGround ] ;
}

- (NSDictionary*)parameter
{
	return parameter ;
}

- (void)addComment:(char*)line
{
	if ( line == nil ) return ;
	[ comments insertText:[ NSString stringWithUTF8String:line ] ] ;
	[ comments insertText:@"\n" ] ;
}

- (void)groundMenuChanged
{
	[ self setDirty ] ;
	[ self setGroundMenu ] ;
}

- (void)frequencyFieldChanged
{
	[ self setDirty ] ;
	[ self updateDictionary ] ;
}

- (IBAction)freqMatrixChanged:(id)sender
{
	[ self setDirty ] ;
	[ self setFrequencySelection ] ;
}

- (IBAction)addInline:(id)sender
{
	intType n = [ table selectedRow ]+1 ;
	
	if ( n < 0 ) n = 0 ; 
	
	[ self setDirty ] ;
	[ controlCards insertObject:[ [ ControlCard alloc ] init ] atIndex:n ] ;
	rows++ ;
	
	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:n ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:n ] ;	
	[ table editColumn:1 row:n withEvent:nil select:YES ] ;
}

- (void)showSheet:(NSWindow*)mainWindow
{
	controllingWindow = mainWindow ;
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

//  (Private API)
- (void)removeRow:(intType)row
{
	ControlCard *card ;
	
	[ self setDirty ] ;
	card = [ controlCards objectAtIndex:row ] ;
	[ controlCards removeObjectAtIndex:row ] ;
	[ card release ] ;
	rows-- ;
	if ( rows < 0 ) rows = 0 ;
	[ table reloadData ] ;
}

- (IBAction)removeInline:(id)sender
{
	intType row = [ table selectedRow ] ;
	if ( row < 0 ) return ;

	[ self removeRow:row ] ;
}

//  avoid %f format problems with negative numbers
- (const char*)dbl:(double)value
{
	NSString *fmt ;
	double p ;

	p = fabs( value ) ;

	if ( p == 0 ) fmt = @"%10.6f" ;
	else if ( p < .001 ) fmt = @"%10.2E" ;
	else if ( p < 10.0 ) fmt = @"%10.6f" ;
	else if ( p < 100.0 ) fmt = @"%10.5f" ;
	else if ( p < 1000.0 ) fmt = @"%10.4f" ;
	else if ( p < 10000.0 ) fmt = @"%10.3f" ;
	else fmt = @"%10.2E" ;

	return [ [ NSString stringWithFormat:fmt, value ] UTF8String ] ;
}

//  v0.55 generate NC code
- (Boolean)generateNECRadials:(NSMutableString*)string
{
	if ( [ radialsMatrix selectedRow ] != 2 ) return NO ;
	
	[ string appendString:@"necRadials(" ] ;
	[ string appendArguments:radialsParamMatrix count:3 addition:@");\n" ] ;
	return YES ;
}

//	v0.55  generate NC code
- (Boolean)generateRadials:(NSMutableString*)string eval:(Spreadsheet*)eval
{
	double radius, length ;
	int radials ;
	
	if ( [ radialsMatrix selectedRow ] != 1 ) return NO ;
	
	//  sanity checks
	radius = [ eval doubleValueForObject:[ radialsParamMatrix cellAtRow:1 column:0 ] ] ;
	if ( radius < 0.0001 ) {
		[ AlertExtension modalAlert:@"Wire radius specified for radials is too small." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nRadials are not generated.\n\nPlease correct in the Environment:Radials sheet.\n" ] ;
		return NO ;
	}
	
	radials = [ eval intValueForObject:[ radialsParamMatrix cellAtRow:2 column:0 ] ] ;
	if ( radials < 1 ) {
		[ AlertExtension modalAlert:@"Number of radials fewer than one??" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\n\nRadials are not generated.\n\nYou need at least one element!\n\nPlease correct in the Environment:Radials sheet.\n" ] ;
		return NO ;
	}
	
	length = [ eval doubleValueForObject:[ radialsParamMatrix cellAtRow:0 column:0 ] ] ;
	if ( length < radius*10 ) {
		[ AlertExtension modalAlert:@"The length of a radial wire is too short." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\n\nRadials are not generated.\n\nThe length needs to be at least 10 times longer than the radius of the wire.\n\nPlease correct in the Environment:Radials sheet.\n" ] ;
		return NO ;
	}
	
	//  generate NC code
	[ string appendString:@"radials(" ] ;
	[ string appendArguments:radialsCoordMatrix count:3 addition:@"," ] ;
	[ string appendArguments:radialsParamMatrix count:3 addition:@");\n" ] ;
	return YES ;
}

//	v0.55  generate NC comments
- (int)generateComments:(NSMutableString*)string
{
	const char *str, *next ;
	char copy[128], *s ;
	int count ;
	
	count = 0 ;
	str = [ [ [ comments textStorage ] string ] UTF8String ] ;
	while ( *str ) {
		s = copy ;
		while ( *str && *str != '\n' ) *s++ = *str++ ;
		next = ( *str == 0 ) ? str : ( str+1 ) ;
		*s = 0 ;
		if ( *copy != 0 ) {
			count++ ;
			[ string appendString:@"//  " ] ;
			[ string appendString:[ NSString stringWithUTF8String:copy ] ] ;
			[ string appendString:@"\n" ] ;
		}
		str = next ;
	}
	return count ;
}

//  create a dictionary of radials
- (NSMutableDictionary*)makeRadials 
{
	NSMutableDictionary *dict ;

	dict = [ [ NSMutableDictionary alloc ] init ] ;
	[ dict setObject:[ NSNumber numberWithLong:[ radialsMatrix selectedRow ] ] forKey:@"has radials" ] ;
	[ dict setObject:[ [ radialsCoordMatrix cellAtRow:0 column:0 ] stringValue ] forKey:@"x" ] ;
	[ dict setObject:[ [ radialsCoordMatrix cellAtRow:1 column:0 ] stringValue ] forKey:@"y" ] ;
	[ dict setObject:[ [ radialsCoordMatrix cellAtRow:2 column:0 ] stringValue ] forKey:@"z" ] ;
	[ dict setObject:[ [ radialsParamMatrix cellAtRow:0 column:0 ] stringValue ] forKey:@"length" ] ;
	[ dict setObject:[ [ radialsParamMatrix cellAtRow:1 column:0 ] stringValue ] forKey:@"radius" ] ;
	[ dict setObject:[ [ radialsParamMatrix cellAtRow:2 column:0 ] stringValue ] forKey:@"radials" ] ;
	return dict ;
}

- (void)restoreRadialsFromDictionary:(NSDictionary*)dict
{
	NSString *s ;
	NSNumber *n ;
	
	if ( dict ) {
		selectedRadials = 0 ;
		n = [ dict objectForKey:@"has radials" ] ;
		if ( n ) selectedRadials = [ n intValue ] ;
		[ radialsMatrix selectCellAtRow:selectedRadials column:0 ] ;
		
		s = [ dict objectForKey:@"x" ] ; if ( s ) [ [ radialsCoordMatrix cellAtRow:0 column:0 ] setStringValue:s ] ;
		s = [ dict objectForKey:@"y" ] ; if ( s ) [ [ radialsCoordMatrix cellAtRow:1 column:0 ] setStringValue:s ] ;
		s = [ dict objectForKey:@"z" ] ; if ( s ) [ [ radialsCoordMatrix cellAtRow:2 column:0 ] setStringValue:s ] ;
		s = [ dict objectForKey:@"length" ] ; if ( s ) [ [ radialsParamMatrix cellAtRow:0 column:0 ] setStringValue:s ] ;
		s = [ dict objectForKey:@"radius" ] ; if ( s ) [ [ radialsParamMatrix cellAtRow:1 column:0 ] setStringValue:s ] ;
		s = [ dict objectForKey:@"radials" ] ; if ( s ) [ [ radialsParamMatrix cellAtRow:2 column:0 ] setStringValue:s ] ;
		
		radialsX = [ [ radialsCoordMatrix cellAtRow:0 column:0 ] stringValue ] ;
		radialsY = [ [ radialsCoordMatrix cellAtRow:1 column:0 ] stringValue ] ;
		radialsZ = [ [ radialsCoordMatrix cellAtRow:2 column:0 ] stringValue ] ;
	}
}

//	(Private API)
- (NSArray*)arrayOfComments
{
	const char *str, *next ;
	char copy[128], *s ;
	
	[ commentsArray removeAllObjects ] ;
	
	str = [ [ [ comments textStorage ] string ] UTF8String ] ;
	while ( *str ) {
		s = copy ;
		while ( *str && *str != '\n' ) *s++ = *str++ ;
		next = ( *str == 0 ) ? str : ( str+1 ) ;
		*s = 0 ;
		[ commentsArray addObject:[ NSString stringWithUTF8String:copy ] ] ;
		str = next ;
	}
	return commentsArray ;
}

- (NSMutableDictionary*)makeDictionaryForPlist 
{
	NSMutableDictionary *plist ;
	NSMutableArray *cards ;
	intType i, count ;

	plist = [ [ NSMutableDictionary alloc ] init ] ;
	[ plist setObject:[ freqField stringValue ] forKey:@"frequency" ] ;
	[ plist setObject:[ f1Field stringValue ] forKey:@"f1" ] ;
	[ plist setObject:[ f2Field stringValue ] forKey:@"f2" ] ;
	[ plist setObject:[ f3Field stringValue ] forKey:@"f3" ] ;
	[ plist setObject:[ f4Field stringValue ] forKey:@"f4" ] ;
	[ plist setObject:[ NSNumber numberWithBool:([ freqMatrix selectedRow ] == 0 ) ] forKey:@"fixed" ] ;
	[ plist setObject:[ NSNumber numberWithBool:([ freqMatrix selectedRow ] == 2 ) ] forKey:@"multiple" ] ;
	[ plist setObject:[ freqLowField stringValue ] forKey:@"low" ] ;
	[ plist setObject:[ freqHighField stringValue ] forKey:@"high" ] ;
	[ plist setObject:[ freqStepField stringValue ] forKey:@"step" ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ linearCheckBox state ] == NSOnState ) ] forKey:@"linear" ] ;

	[ plist setObject:[ dielectricField stringValue ] forKey:@"dielectric" ] ;
	[ plist setObject:[ conductivityField stringValue ] forKey:@"conductivity" ] ;
	[ plist setObject:[ groundMenu titleOfSelectedItem ] forKey:@"ground type" ] ;

	//  create array of comment lines
	[ plist setObject:[ self arrayOfComments ] forKey:@"comment" ] ;
	
	//  inline control cards
	cards = [ [ NSMutableArray alloc ] init ] ;
	count = [ controlCards count ] ;
	for ( i = 0; i < count; i++ ) {
		[ cards addObject:[ [ controlCards objectAtIndex:i ] dictForCard ] ] ;
	}
	[ plist setObject:cards forKey:@"controlCards" ] ;
	
	return plist ;
}

- (void)setCommentFromArray:(NSArray*)array
{
	intType count, i ;
	
	count = [ array count ] ;
	for ( i = 0; i < count; i++ ) {
		[ self addComment:(char*)[ [ array objectAtIndex:i ] UTF8String ] ] ;
	}
}

- (void)restoreFromDictionary:(NSDictionary*)dict
{
	NSArray *cards ;
	NSNumber *linear, *multiple ;
	ControlCard *controlCard ;
	int i, state ;
    intType count ;
	
	[ freqField setStringValue:[ dict objectForKey:@"frequency" ] ] ;
	if ( [ dict objectForKey:@"f1" ] ) [ f1Field setStringValue:[ dict objectForKey:@"f1" ] ] ;
	if ( [ dict objectForKey:@"f2" ] ) [ f2Field setStringValue:[ dict objectForKey:@"f2" ] ] ;
	if ( [ dict objectForKey:@"f3" ] ) [ f3Field setStringValue:[ dict objectForKey:@"f3" ] ] ;
	if ( [ dict objectForKey:@"f4" ] ) [ f4Field setStringValue:[ dict objectForKey:@"f4" ] ] ;
	[ freqLowField setStringValue:[ dict objectForKey:@"low" ] ] ;
	[ freqHighField setStringValue:[ dict objectForKey:@"high" ] ] ;
	[ freqStepField setStringValue:[ dict objectForKey:@"step" ] ] ;
	
	//  v0.55 - add "multiple"
	if ( [ [ dict objectForKey:@"fixed" ] intValue ] == 1 ) {
		[ freqMatrix selectCellAtRow:0 column:1 ] ;
	}
	else {
		multiple = [ dict objectForKey:@"multiple" ] ;
		if ( multiple == nil ) {
			//  pre-v0.55
			[ freqMatrix selectCellAtRow:1 column:0 ] ;
		}
		else {
			[ freqMatrix selectCellAtRow:( ( [ multiple intValue ] == 0 ) ? 1 : 2 ) column:0 ] ;
		}
	}
	linear = [ dict objectForKey:@"linear" ] ;
	state = ( linear == nil ) ? NO : [ linear boolValue ] ;
	[ linearCheckBox setState:( state ) ? NSOnState : NSOffState ] ;
	
	[ self setFrequencySelection ] ;
	[ self setRadialsMatrix ] ;

	[ dielectricField setStringValue:[ dict objectForKey:@"dielectric" ] ] ;
	[ conductivityField setStringValue:[ dict objectForKey:@"conductivity" ] ] ;
	[ groundMenu selectItemWithTitle:[ dict objectForKey:@"ground type" ] ] ;
	
	[ self groundMenuChanged ] ;	//  v0.49
	
	//  comments
	[ self setCommentFromArray:[ dict objectForKey:@"comment" ] ] ;
	
	//  inline cards
	cards = [ dict objectForKey:@"controlCards" ] ;
	if ( cards ) {
		count = [ cards count ] ;
		if ( count > 0 ) {
			for ( i = 0; i < count; i++ ) {
				controlCard = [ [ ControlCard alloc ] init ] ;
				[ controlCards insertObject:controlCard atIndex:rows ] ;
				rows++ ;
				[ controlCard setCardFromDict:[ cards objectAtIndex:i ] ] ;
			}
			[ table reloadData ] ;
			[ table deselectAll:self ] ;
			[ table scrollRowToVisible:0 ] ;	
		}
	}
	[ self setDictionary ] ;
}

@end
