//
//  ElementGeometry.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/5/07.
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

#import "ElementGeometry.h"
#import "ApplicationDelegate.h"
#import "ArcGeometry.h"
#import "Bundle.h"
#import "HelixGeometry.h"
#import "InlineGeometry.h"
#import "MPatchGeometry.h"
#import "PatchGeometry.h"
#import "WireGeometry.h"
#import "formats.h"


//  An object of this class manages the data for each row of the Geometry tableView.

@implementation ElementGeometry

//  Each Wire correspond to a GW "tag" in NEC-2 together with LD and EX properties.
//  Just as not all tags have an LD or EX card, not all Wire object has a the LD and EX properties.


- (id)initWithDelegate:(id)client
{
	self = [ super init ] ;
	if ( self ) {
		delegate = client ;
		selectedType = WIRETYPE ;
		card1 = card2 = name = comment = nil ;
		startingTag = endingTag = -1 ;
		opened = ignore = dirty = NO ;
		plist = nil ;
		attachedWire = nil ;
		elementIndex = 0 ;
	}
	return self ;
}

- (id)initWithDelegate:(id)client type:(intType)type
{
	ElementGeometry *e ;
	Boolean autoOpen = YES ;
	
	switch ( type ) {
	default:
	case WIRETYPE: 
		e = [ WireGeometry alloc ] ; 
		autoOpen = NO ;
		break ;
	case ARCTYPE: 
		e = [ ArcGeometry alloc ] ; 
		break ;
	case HELIXTYPE: 
		e = [ HelixGeometry alloc ] ; 
		break ;
	case PATCHTYPE: 
		e = [ PatchGeometry alloc ] ; 
		break ;
	case MPATCHTYPE: 
		e = [ MPatchGeometry alloc ] ; 
		break ;
	case INLINE: 
		e = [ InlineGeometry alloc ] ; 
		break ;
	}
	[ self autorelease ] ;
	
	self = [ e initWithDelegate:client ] ;
	selectedType = type ;
    
    //  v0.88 old loadNibNamed deprecated in 10.10
    retainedNibObjects = [ Bundle loadNibNamed:@"Geometry" owner:self ] ;
    if ( retainedNibObjects == nil ) return nil ;
 	
	if ( autoOpen ) [ self openInspector:self ] ;
	return self ;
}

//  init with data from plist (an NSDictionary)
- (id)initWithDelegate:(id)client data:(NSDictionary*)dict
{
	ElementGeometry *e ;
	int type ;
	NSString *typeString ;
	
	typeString = [ dict objectForKey:@"type" ] ;
	
	if ( [ typeString isEqualToString:ArcTypeString ] ) {
		type = ARCTYPE ;
		e = [ ArcGeometry alloc ] ; 
	}
	else if ( [ typeString isEqualToString:HelixTypeString ] ) {
		type = HELIXTYPE ;
		e = [ HelixGeometry alloc ] ; 
	}
	else if ( [ typeString isEqualToString:PatchTypeString ] ) {
		type = PATCHTYPE ; 
		e = [ PatchGeometry alloc ] ; 
	}
	else if ( [ typeString isEqualToString:MPatchTypeString ] ) {
		type = MPATCHTYPE ; 
		e = [ MPatchGeometry alloc ] ; 
	}
	else if ( [ typeString isEqualToString:InlineTypeString ] ) {
		type = INLINE ; 
		e = [ InlineGeometry alloc ] ; 
	}	
	else {
		type = WIRETYPE ;
		e = [ WireGeometry alloc ] ; 
	}
	[ self autorelease ] ;
	
	self = [ e initWithDelegate:client ] ;
	selectedType = type ;

    //  v0.88 old loadNibNamed deprecated in 10.10
    retainedNibObjects = [ Bundle loadNibNamed:@"Geometry" owner:self ] ;
    if ( retainedNibObjects == nil ) return nil ;
    	
	[ self selectTabView ] ;
	[ self restoreGeometryFieldsFromDictionary:dict ] ;
	
	return self ;
}

- (void)dealloc
{
	[ window setDelegate:nil ] ;
	if ( card1 ) [ card1 release ] ;
	if ( card2 ) [ card2 release ] ;
	if ( attachedWire ) [ attachedWire release ] ;
	[ self releasePlist ] ;
    [ retainedNibObjects release ] ;
	[ super dealloc ] ;
}

- (void)setDirty
{
	[ delegate setDirty ] ;
}

//  v0.55
- (int)elementIndex
{
	return elementIndex ;
}

- (id)delegate
{
	return delegate ;
}

- (ElementGeometry*)attachedWire
{
	return attachedWire ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)setDirtyWhenTouched:(id)object
{
	[ self setInterface:object to:@selector(setDirty) ] ;
}

- (void)awakeFromNib
{
	[ window setDelegate:self ] ;
	// sent any field editing to delegate
	[ self setInterface:wireCoord1 to:@selector(spreadsheetCellChanged:) ] ;
	[ self setInterface:wireCoord2 to:@selector(spreadsheetCellChanged:) ] ;
	[ self setInterface:wireProperties to:@selector(spreadsheetCellChanged:) ] ;
		
	[ self setInterface:wireTransform to:@selector(spreadsheetCellChanged:) ] ;	
	[ self setInterface:arcTransform to:@selector(spreadsheetCellChanged:) ] ;	
	[ self setInterface:helixTransform to:@selector(spreadsheetCellChanged:) ] ;	
	[ self setInterface:patchTransform to:@selector(spreadsheetCellChanged:) ] ;	
	[ self setInterface:mpatchTransform to:@selector(spreadsheetCellChanged:) ] ;	

	[ self setDirtyWhenTouched:arcIntMatrix ] ;
	[ self setDirtyWhenTouched:arcFloatMatrix ] ;
	
	[ self setDirtyWhenTouched:helixIntMatrix ] ;
	[ self setDirtyWhenTouched:helixFloatMatrix ] ;

	[ self setDirtyWhenTouched:patchShape ] ;
	[ self setDirtyWhenTouched:patchFloatMatrix1 ] ;
	[ self setDirtyWhenTouched:patchFloatMatrix2 ] ;
	
	[ self setDirtyWhenTouched:mpatchNX ] ;
	[ self setDirtyWhenTouched:mpatchNY ] ;
	[ self setDirtyWhenTouched:mpatchFloatMatrix1 ] ;
	[ self setDirtyWhenTouched:mpatchFloatMatrix2 ] ;
	
	[ self setDirtyWhenTouched:inlineCard ] ;
	[ self setDirtyWhenTouched:exLocationMatrix ] ;
	[ self setDirtyWhenTouched:exLocationSegment ] ;
	[ self setDirtyWhenTouched:exVoltageMatrix ] ;
	[ self setDirtyWhenTouched:exHollerith ] ;
	[ self setDirtyWhenTouched:seriesLocationMatrix ] ;
	[ self setDirtyWhenTouched:seriesLocationFrom ] ;
	[ self setDirtyWhenTouched:seriesLocationTo ] ;
	[ self setDirtyWhenTouched:seriesRLCMatrix ] ;
	[ self setDirtyWhenTouched:seriesPerLength ] ;
	[ self setDirtyWhenTouched:parallelLocationMatrix ] ;
	[ self setDirtyWhenTouched:parallelLocationFrom ] ;
	[ self setDirtyWhenTouched:parallelLocationTo ] ;
	[ self setDirtyWhenTouched:parallelRLCMatrix ] ;
	[ self setDirtyWhenTouched:parallelPerLength ] ;
	[ self setDirtyWhenTouched:impedanceLocationMatrix ] ;
	[ self setDirtyWhenTouched:impedanceLocationFrom ] ;
	[ self setDirtyWhenTouched:impedanceLocationTo ] ;
	[ self setDirtyWhenTouched:impedanceMatrix ] ;
	[ self setDirtyWhenTouched:conductivityLocationMatrix ] ;
	[ self setDirtyWhenTouched:conductivityLocationFrom ] ;
	[ self setDirtyWhenTouched:conductivityLocationTo ] ;
	[ self setDirtyWhenTouched:conductivity ] ;
	[ self setDirtyWhenTouched:loadHollerith ] ;
	
	[ typeTab setDelegate:self ] ;
}

//	Subclasses should return the text field for Transform.
- (NSTextField*)transformField
{
	return nil ;
}

- (void)selectTabView
{
	NSArray *tabs ;
	intType count, i ;
	
	tabs = [ typeTab tabViewItems ] ;
	count = [ tabs count ] ;
	for ( i = 0; i < count; i++ ) {
		if ( [ [ [ tabs objectAtIndex:i ] identifier ] intValue ] == selectedType ) {
			[ typeTab setDelegate:nil ] ;
			[ typeTab selectTabViewItemAtIndex:i ] ;
			//  disallow user selection
			[ typeTab setDelegate:self ] ;
			return ;
		}
	}	
}

//  open the inspector window at the tab that correspond to the wire type
- (void)openInspector:(id)client
{
	[ self selectTabView ] ;
	opened = YES ;
	[ window makeKeyAndOrderFront:client ] ;
}

- (void)closeInspector:(id)client 
{
	[ window orderOut:client ] ;
}

- (void)bringToFront
{
	if ( [ window isVisible ] ) [ window orderFront:self ] ;
}

- (Boolean)opened
{
	return opened ;
}

- (Boolean)ignoreCard
{
	return ignore ;
}

- (intType)wireType
{
	return selectedType ;
}

- (NSString*)typeString
{
	return @" " ;
}

//  this sends a message to the delegate when any editing terminates
- (void)spreadsheetCellChanged:(id)sender
{
	dirty = YES ;
	if ( delegate && [ delegate respondsToSelector:@selector(spreadsheetCellChanged:) ] ) [ delegate spreadsheetCellChanged:sender ] ;
}

- (NSString*)componentOfEnd1:(int)index
{
	return @"" ; 
}

- (void)setComponentOfEnd1:(int)index string:(NSString*)str 
{
}

- (NSString*)componentOfEnd2:(int)index
{
	return @"" ; 
}

- (void)setComponentOfEnd2:(int)index string:(NSString*)str 
{
}

- (NSString*)nameField
{
	if ( name == nil ) return @"" ;
	return name ;
}

- (void)setName:(NSString*)str
{
	if ( name != nil ) [ name release ] ;
	if ( [ str length ] > 0 && [ str characterAtIndex:0 ] == ' ' ) str = [ str substringFromIndex:1 ] ;
	name = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)ignoreField
{
	return ( ignore ) ? @"*" : @"" ;
}

- (void)setIgnore:(NSString*)str
{
	intType length ;
	
	if ( str != nil ) {
		length = [ str length ] ;
		if ( length == 1 || length == 2 ) {
			ignore = ( [ str characterAtIndex:length-1 ] == '*' ) ;
			return ;
		}
	}
	ignore = NO ;
}

- (NSString*)commentField
{
	if ( comment == nil ) return @"" ;
	return comment ;
}

- (void)setComment:(NSString*)str
{
	if ( comment != nil ) [ comment release ] ;
	comment = [ [ NSString alloc ] initWithString:str ] ;
}

- (intType)tag
{
	return startingTag ;
}

- (Boolean)empty
{
	return YES ;
}

//	returns textField/cell/etc where number of segments is defined
//	id is any object that will accept [ object stringValue ]
- (id)fieldForNumberOfSegments
{
	return @"" ;
}

//	returns textField/cell/etc where wire radius is defined
//	id is any object that will accept [ object stringValue ]
- (id)fieldForWireRadius
{
	return @"" ;
}

//	returns textField/cell/etc where the (x,y,z) cooreinate of wire end 1 is defined
//	id is any object that will accept [ object stringValue ]
- (id)fieldForCoordinate1:(int)component 
{
	return @"" ;
}

//	returns textField/cell/etc where the (x,y,z) cooreinate of wire end 2 is defined
//	id is any object that will accept [ object stringValue ]
- (id)fieldForCoordinate2:(int)component 
{
	return @"" ;
}

- (int)numberOfSegments
{
	return [ [ NSApp delegate ] intValueForObject:[ self fieldForNumberOfSegments ] ] ;
}

- (double)wireRadius
{
	return [ [ NSApp delegate ] doubleValueForObject:[ self fieldForWireRadius ] ] ;
}

- (double)valueOfCoordinate1:(int)component
{
	return [ [ NSApp delegate ] doubleValueForObject:[ self fieldForCoordinate1:component ] ] ;
}

- (double)valueOfCoordinate2:(int)component
{
	return [ [ NSApp delegate ] doubleValueForObject:[ self fieldForCoordinate2:component ] ] ;
}

//	v0.55
- (NSString*)ncForGeometry:(int)index
{
	return [ NSString stringWithFormat:@"// ncForGeometry not Implemented for element %d\n", index ] ;
}

//	v0.55
- (int)selectedSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field
{
	int segments, segment ;

	segments = [ self numberOfSegments ] ;
	
	switch ( [ matrix selectedRow ] ) {
	default:
	case 0:
		return ( segments+1 )/2 ;
	case 1:
		return 1 ;
	case 2:
		return segments ;
	case 3:
		segment = [ field intValue ] ;
		if ( segment < 1 ) segment = 1 ; else if ( segment > segments ) segment = segments ;
		return segment ;
	}
	return 1 ;
}

//	v0.55
- (SegmentRange)selectedSegment:(NSMatrix*)matrix segNumber:(NSTextField*)from to:(NSTextField*)to
{
	int segments ;
	SegmentRange range ;

	segments = [ self numberOfSegments ] ;

	switch ( [ matrix selectedRow ] ) {
	default:
        break ;
	case 0:
		// center segment
		range.from = range.to = 0 ;
		return range ;
	case 1:
		// all segments
		range.from = 1 ;
		range.to = segments ;
		return range ;
	case 2:
		//  range
		range.from = [ from intValue ] ;
		range.to = [ to intValue ] ;
		return range ;
	}
	range.from = range.to = (int)( segments+1 )/2 ;
	return range ;
}

- (int)excitationSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field segments:(id)segmentsField
{
	int segment, segments ;

	segments = [ [ NSApp delegate ] intValueForObject:segmentsField ] ;

	switch ( [ matrix selectedRow ] ) {
	default:
	case 0:
		segment = ( segments+1 )/2 ;
		if ( segment == 0 ) segment = 1 ;
		return segment ;
	case 1:
		return 1 ;
	case 2:
		return segments ;
	case 3:
		segment = [ [ NSApp delegate ] intValueForObject:field ] ;
		if ( segment < 1 ) segment = 1 ; else if ( segment > segments ) segment = segments ;
		return segment ;
	}
	return 0 ;
}

//  v0.55
- (int)excitationSegment:(NSMatrix*)matrix segNumber:(NSTextField*)field
{
	printf( "ElementGeometry: excitationSegment method not implemented by subclass of ElementGeometry.\n" ) ;
	return 0 ;
}

//	v0.55
//	v0.58 use %e instead of %f
- (NSString*)ncForLoading:(int)index
{
	double f[6] ;
	SegmentRange range ;
	Boolean perLength ;
	int i ;
	
	switch ( [ [ [ loadMenu selectedTabViewItem ] identifier ] intValue ] ) {
	case 1:
		//  series RLC
		perLength = ( [ seriesPerLength state ] == NSOnState ) ;
		range = [ self selectedSegment:seriesLocationMatrix segNumber:seriesLocationFrom to:seriesLocationTo ] ;
		for ( i = 0; i < 3; i++ ) f[i] = [ self evalDouble:seriesRLCMatrix row:i cellName:"series RLC loading" ] ;
		return [ NSString stringWithFormat:@"seriesLoadAtSegments(_e%d, %f, %e, %e, %d, %d, %d );\n", index, f[0], f[1], f[2], perLength, range.from, range.to ] ;
	case 2:
		//  parallel RLC
		perLength = ( [ parallelPerLength state ] == NSOnState ) ;
		range = [ self selectedSegment:parallelLocationMatrix segNumber:parallelLocationFrom to:parallelLocationTo ] ;
		for ( i = 0; i < 3; i++ ) f[i] = [ self evalDouble:parallelRLCMatrix row:i cellName:"parallel RLC loading" ] ;		
		return [ NSString stringWithFormat:@"parallelLoadAtSegments(_e%d, %f, %e, %e, %d, %d, %d );\n", index, f[0], f[1], f[2], perLength, range.from, range.to ] ;
	case 3:
		//  impedance
		range = [ self selectedSegment:impedanceLocationMatrix segNumber:impedanceLocationFrom to:impedanceLocationTo ] ;
		for ( i = 0; i < 2; i++ ) f[i] = [ self evalDouble:impedanceMatrix row:i cellName:"impedance loading" ] ;
		return [ NSString stringWithFormat:@"impedanceAtSegments(_e%d, %f, %f, %d, %d );\n", index, f[0], f[1], range.from, range.to ] ;
	case 4:
		//  conductance
		range = [ self selectedSegment:conductivityLocationMatrix segNumber:conductivityLocationFrom to:conductivityLocationTo ] ;
		f[0] = [ self evalDouble:conductivity row:0 cellName:"conductivity loading" ] ;
		if ( f[0] > .0001 ) return [ NSString stringWithFormat:@"conductivityAtSegments(_e%d, %f, %d, %d );\n", index, f[0], range.from, range.to ] ;
		return [ NSString stringWithFormat:@"conductivityAtSegments(_e%d, %e, %d, %d );\n", index, f[0], range.from, range.to ] ;
	case 5:
		printf( "arbitrary loading card?\n" ) ;
		return @"" ;
	}
	return @"" ;
}

//  v0.55
- (NSString*)ncForExcitation:(int)index
{
	float re, im ;
	int seg ;
	
	switch ( [ [ [ exMenu selectedTabViewItem ] identifier ] intValue ] ) {
	case 1:
		//  voltage
		re = [ [ NSApp delegate ] doubleValueForObject:[ exVoltageMatrix cellAtRow:0 column:0 ] ] ;
		im = [ [ NSApp delegate ] doubleValueForObject:[ exVoltageMatrix cellAtRow:1 column:0 ] ] ;
		seg = [ self excitationSegment:exLocationMatrix segNumber:exLocationSegment ] ;
		return [ NSString stringWithFormat:@"voltageFeedAtSegment(_e%d,%f,%f,%d);\n", index, re, im, seg ] ;
	case 2:
		//  current
		re = [ [ NSApp delegate ] doubleValueForObject:[ currentMatrix cellAtRow:0 column:0 ] ] ;
		im = [ [ NSApp delegate ] doubleValueForObject:[ currentMatrix cellAtRow:1 column:0 ] ] ;
		seg = [ self excitationSegment:curLocationMatrix segNumber:curLocationSegment ] ;
		return [ NSString stringWithFormat:@"currentFeedAtSegment(_e%d,%f,%f,%d);\n", index, re, im, seg ] ;
		break ;
	}
	return @"" ;
}


//  return double float as a 10 character string
- (const char*)evalDoubleAsString:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName
{
	NSString *string ;
	EvalResult result ;
	double resultValue ;
	
	string = [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
	
	
	if ( string == nil || [ string length ] == 0 ) {		
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Empty \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		// empty cell
		resultValue = 0.0 ;
	}
	else {
		result = [ [ [ NSApp delegate ] currentSpreadsheet ] evaluateFormula:string ] ;
		if ( result.errorCode != 0 ) {
			if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Formula error in \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
			resultValue = 0.0 ;
		}
		else {
			resultValue = result.value ;
		}
	}
	return dtos( resultValue ) ;
}

//  use dtosExtended for small capacitances
- (const char*)evalDoubleAsStringExtended:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName
{
	NSString *string ;
	EvalResult result ;
	double resultValue ;
	
	string = [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
	if ( string == nil || [ string length ] == 0 ) {		
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Empty \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		// empty cell
		resultValue = 0.0 ;
	}
	else {
		result = [ [ [ NSApp delegate ] currentSpreadsheet ] evaluateFormula:string ] ;
		if ( result.errorCode != 0 ) {
			if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Formula error in \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
			resultValue = 0.0 ;
		}
		else {
			resultValue = result.value ;
		}
	}
	return dtosExtended( resultValue ) ;
}

- (double)evalDouble:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName
{
	NSString *string ;
	EvalResult result ;
	
	string = [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
	if ( string == nil || [ string length ] == 0 ) {
		// empty cell
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Empty \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		return 0.0 ;
	}
	result = [ [ [ NSApp delegate ] currentSpreadsheet ] evaluateFormula:string ] ;
	if ( result.errorCode != 0 ) {
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Formula error in \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		return 0.0 ;
	}
	return result.value ;
}

- (int)evalInt:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName
{
	NSString *string ;
	EvalResult result ;
	
	string = [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
	if ( string == nil || [ string length ] == 0 ) {
		// empty cell
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Empty \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		return 0 ;
	}
	result = [ [ [ NSApp delegate ] currentSpreadsheet ] evaluateFormula:string ] ;
	if ( result.errorCode != 0 ) {
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Formula error in \"%s\" cell of row %d of spreadsheet", cellName, spreadsheetRow ] ] ;
		return 0 ;
	}
	return ( result.value + 0.1 ) ;
}

- (NSArray*)geometryCards:(Expression*)e tagStarting:(int)tag spreadsheetRow:(int)row
{
	printf( "ElementGeometry: geometryCards is now deprecated.\n" ) ;
	return [ NSArray array ] ;
}

- (NSArray*)excitationCards:(Expression*)e 
{
	return [ NSArray array ] ;
}

- (NSArray*)networkForExcitationCards 
{
	return [ NSArray array ] ;
}

- (NSArray*)loadingCards:(Expression*)e 
{
	return [ NSArray array ] ;
}

- (double)maxDimension 
{
	return 100.0 ;		// if we don't know what it is
}

- (NSString*)stringFromMatrix:(NSMatrix*)matrix index:(int)index
{
	return [ [ matrix cellAtRow:index column:0 ] stringValue ] ;
}

- (void)setMatrix:(NSMatrix*)matrix index:(int)index fromString:(NSString*)str
{
	[ [ matrix cellAtRow:index column:0 ] setStringValue:str ] ;
}

- (NSArray*)arrayForMatrix:(NSMatrix*)matrix count:(int)n
{
	int i ;
	NSMutableArray *array = [ [ NSMutableArray alloc ] init ] ;
	
	for ( i = 0; i < n; i++ ) [ array addObject:[ self stringFromMatrix:matrix index:i ] ] ;	
	return array ;
}

- (void)setMatrix:(NSMatrix*)matrix fromArray:(NSArray*)array count:(int)n
{
	int i ;
	
	for ( i = 0; i < n; i++ ) [ self setMatrix:matrix index:i fromString:[ array objectAtIndex:i ] ] ;	
}

- (void)addCell:(NSMatrix*)matrix at:(int)index toArray:(NSMutableArray*)array
{
	[ array addObject:[ self stringFromMatrix:matrix index:index ] ] ;
}

- (void)restoreCell:(NSMatrix*)matrix at:(int)i fromArray:(NSArray*)array index:(int)j
{
	[ self setMatrix:matrix index:i fromString:[ array objectAtIndex:j ] ] ;
}

- (NSString*)stringFromArray:(NSArray*)array offset:(int)offset
{
	return [ array objectAtIndex:offset ] ;
}

//  create a plist array with the standard geometry fields
- (NSMutableDictionary*)createGeometryForPlist
{
	NSMutableDictionary *p ;
	
	p = [ [ NSMutableDictionary alloc ] init ] ;
	[ p setObject:[ self typeString ] forKey:@"type" ] ;
	[ p setObject:[ self ignoreField ] forKey:@"ignore" ] ;
	[ p setObject:[ self nameField ] forKey:@"name" ] ;
	[ p setObject:[ self commentField ] forKey:@"comment" ] ;

	return p ;
}

- (void)addExcitationToDict:(NSMutableDictionary*)base
{
	NSMutableDictionary *dict ;
	int excitationKind ;
	
	dict = [ [ NSMutableDictionary alloc ] init ] ;
	
	excitationKind = [ [ [ exMenu selectedTabViewItem ] identifier ] intValue ] ;
	[ dict setObject:[ NSNumber numberWithInt:excitationKind ] forKey:@"type" ] ;	
	
	switch ( excitationKind ) {
	case 0:
	default:
		//  none
		break ;
	case 1:
		//  voltage
		[ dict setObject:[ NSNumber numberWithLong:[ exLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ exLocationSegment stringValue ] forKey:@"segment" ] ;
		[ dict setObject:[ self arrayForMatrix:exVoltageMatrix count:2 ] forKey:@"voltage" ] ;
		break ;
	case 2:
		//  current
		[ dict setObject:[ NSNumber numberWithLong:[ curLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ curLocationSegment stringValue ] forKey:@"segment" ] ;
		[ dict setObject:[ self arrayForMatrix:currentMatrix count:2 ] forKey:@"current" ] ;
		break ;		
	case 3:
		//  hollerith
		[ dict setObject:[ [ exHollerith stringValue ] uppercaseString ] forKey:@"hollerith" ] ;
		break ;
	}
	[ base setObject:dict forKey:@"excitation" ] ;
}

- (void)restoreExcitation:(NSDictionary*)dict
{
	int row, excitationKind ;
	NSString *str ;
	NSArray *array ;
	
	excitationKind = [ [ dict objectForKey:@"type" ] intValue ] ;
	[ exMenu selectTabViewItemAtIndex:excitationKind ] ;
	
	switch ( excitationKind ) {
	case 0:
	default:
		//  none
		break ;
	case 1:
		//  voltage
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ exLocationMatrix selectCellAtRow:row column:0 ] ;
		str = [ dict objectForKey:@"segment" ] ;
		if ( str ) [ exLocationSegment setStringValue:str ] ;
		array = [ dict objectForKey:@"voltage" ] ;
		if ( array ) [ self setMatrix:exVoltageMatrix fromArray:array count:2 ] ;
		break ;
	case 2:
		//  voltage
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ curLocationMatrix selectCellAtRow:row column:0 ] ;
		str = [ dict objectForKey:@"segment" ] ;
		if ( str ) [ curLocationSegment setStringValue:str ] ;
		array = [ dict objectForKey:@"current" ] ;
		if ( array ) [ self setMatrix:currentMatrix fromArray:array count:2 ] ;
		break ;
	case 3:
		//  hollerith
		[ exHollerith setStringValue:[ dict objectForKey:@"hollerith" ] ] ;
		break ;
	}
}

- (void)addLoadToDict:(NSMutableDictionary*)base
{
	NSMutableDictionary *dict ;
	int loadKind ;
	
	dict = [ [ NSMutableDictionary alloc ] init ] ;
	
	loadKind = [ [ [ loadMenu selectedTabViewItem ] identifier ] intValue ] ;
	[ dict setObject:[ NSNumber numberWithInt:loadKind ] forKey:@"type" ] ;	
	
	switch ( loadKind ) {
	case 0:
		//  none
		break ;
	case 1:
		//  series RLC
		[ dict setObject:[ NSNumber numberWithLong:[ seriesLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ seriesLocationFrom stringValue ] forKey:@"from" ] ;
		[ dict setObject:[ seriesLocationTo stringValue ] forKey:@"to" ] ;
		[ dict setObject:[ self arrayForMatrix:seriesRLCMatrix count:3 ] forKey:@"RLC" ] ;
		[ dict setObject:[ NSNumber numberWithBool:( [ seriesPerLength state ] == NSOnState ) ] forKey:@"perLength" ] ;
		break ;
	case 2:
		//  parallel RLC
            [ dict setObject:[ NSNumber numberWithLong:[ parallelLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ parallelLocationFrom stringValue ] forKey:@"from" ] ;
		[ dict setObject:[ parallelLocationTo stringValue ] forKey:@"to" ] ;
		[ dict setObject:[ self arrayForMatrix:parallelRLCMatrix count:3 ] forKey:@"RLC" ] ;
		[ dict setObject:[ NSNumber numberWithBool:( [ parallelPerLength state ] == NSOnState ) ] forKey:@"perLength" ] ;
		break ;
	case 3:
		//  impedance
            [ dict setObject:[ NSNumber numberWithLong:[ impedanceLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ impedanceLocationFrom stringValue ] forKey:@"from" ] ;
		[ dict setObject:[ impedanceLocationTo stringValue ] forKey:@"to" ] ;
		[ dict setObject:[ self arrayForMatrix:impedanceMatrix count:2 ] forKey:@"impedance" ] ;
		break ;
	case 4:
		//  conductivity
            [ dict setObject:[ NSNumber numberWithLong:[ conductivityLocationMatrix selectedRow ] ] forKey:@"location" ] ;
		[ dict setObject:[ conductivityLocationFrom stringValue ] forKey:@"from" ] ;
		[ dict setObject:[ conductivityLocationTo stringValue ] forKey:@"to" ] ;
		[ dict setObject:[ self arrayForMatrix:conductivity count:1 ] forKey:@"conductivity" ] ;
		break ;
	case 5:
		//  hollerith
		[ dict setObject:[ [ loadHollerith stringValue ] uppercaseString ] forKey:@"hollerith" ] ;
		break ;
	}
	[ base setObject:dict forKey:@"loading" ] ;
}

- (void)restoreLoad:(NSDictionary*)dict
{
	int row, loadKind ;
	
	loadKind = [ [ dict objectForKey:@"type" ] intValue ] ;
	[ loadMenu selectTabViewItemAtIndex:loadKind ] ;
	
	switch ( loadKind ) {
	case 0:
		//  none
		break ;
	case 1:
		//  series RLC
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ seriesLocationMatrix selectCellAtRow:row column:0 ] ;		
		[ seriesLocationFrom setStringValue:[ dict objectForKey:@"from" ] ] ;
		[ seriesLocationTo setStringValue:[ dict objectForKey:@"to" ] ] ;
		[ self setMatrix:seriesRLCMatrix fromArray:[ dict objectForKey:@"RLC" ] count:3 ] ;
		[ seriesPerLength setState:( [ [ dict objectForKey:@"perLength" ] boolValue ] ) ? NSOnState : NSOffState ] ;
		break ;
	case 2:
		//  parallel RLC
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ parallelLocationMatrix selectCellAtRow:row column:0 ] ;		
		[ parallelLocationFrom setStringValue:[ dict objectForKey:@"from" ] ] ;
		[ parallelLocationTo setStringValue:[ dict objectForKey:@"to" ] ] ;
		[ self setMatrix:parallelRLCMatrix fromArray:[ dict objectForKey:@"RLC" ] count:3 ] ;
		[ parallelPerLength setState:( [ [ dict objectForKey:@"perLength" ] boolValue ] ) ? NSOnState : NSOffState ] ;
		break ;
	case 3:
		//  impedance
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ impedanceLocationMatrix selectCellAtRow:row column:0 ] ;		
		[ impedanceLocationFrom setStringValue:[ dict objectForKey:@"from" ] ] ;
		[ impedanceLocationTo setStringValue:[ dict objectForKey:@"to" ] ] ;
		[ self setMatrix:impedanceMatrix fromArray:[ dict objectForKey:@"impedance" ] count:2 ] ;
		break ;
	case 4:
		//  conductivity
		row = [ [ dict objectForKey:@"location" ] intValue ] ;
		[ conductivityLocationMatrix selectCellAtRow:row column:0 ] ;		
		[ conductivityLocationFrom setStringValue:[ dict objectForKey:@"from" ] ] ;
		[ conductivityLocationTo setStringValue:[ dict objectForKey:@"to" ] ] ;
		[ self setMatrix:conductivity fromArray:[ dict objectForKey:@"conductivity" ] count:1 ] ;
		break ;
	case 5:
		//  hollerith
		[ loadHollerith setStringValue:[ dict objectForKey:@"hollerith" ] ] ;
		break ;
	}
}

- (NSMutableDictionary*)makePlist 
{
	return nil ;
}

- (void)restoreCommonGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	[ self setIgnore:[ dict objectForKey:@"ignore" ] ] ;
	[ self setName:[ dict objectForKey:@"name" ] ] ;
	[ self setComment:[ dict objectForKey:@"comment" ] ] ;
}


- (void)restoreGeometryFieldsFromDictionary:(NSDictionary*)dict
{
	//  override by sub classes
	printf( "error: restoreGeometryFieldsFromDictionary unimplemented for this wire type\n" ) ;
}

- (void)releasePlist
{
	if ( plist ) {
		[ plist removeAllObjects ] ;
		[ plist release ] ;
		plist = nil ;
	}
}
	
- (void)hideWindow
{
	[ window orderOut:self ] ;
}

- (void)showWindow
{
	[ window orderFront:self ] ;
}

//  user closed inspector
- (void)windowWillClose:(NSNotification*)aNotification
{
	opened = NO ;
}

//  delegate to tab view
- (BOOL)tabView:(NSTabView*)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if ( tabView == typeTab ) return NO ;		//  don't allow changes
	return YES ;
}


@end
