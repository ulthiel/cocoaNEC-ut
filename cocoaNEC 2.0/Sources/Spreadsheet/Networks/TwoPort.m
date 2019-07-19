//
//  TwoPort.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/12/07.
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

#import "TwoPort.h"
#import "ApplicationDelegate.h"
#import "Bundle.h"
#import "ElementGeometry.h"
#import "Network.h"
#import "TransmissionLine.h"
#import "WireGeometry.h"
#import "formats.h"


@implementation TwoPort

- (id)initWithDelegate:(id)client withType:(intType)type
{
	self = [ super init ] ;
	if ( self ) {
		delegate = client ;
		selectedType = type ;
		card = nil ;
		opened = ignore = NO ;
		to = from = comment = nil ;
        
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"TwoPort" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;
 	}
	return self ;
}

- (id)initWithDelegate:(id)client type:(intType)type
{
	TwoPort *e ;
	
	switch ( type ) {
	default:
	case TRANSMISSIONLINETYPE: 
		e = [ TransmissionLine alloc ] ; 
		break ;
	case NETWORKTYPE: 
		e = [ Network alloc ] ; 
		break ;
	}
	[ self autorelease ] ;
	self = [ e initWithDelegate:client withType:type ] ;
	return self ;
}

- (id)initFromDict:(NSDictionary*)dict delegate:(id)client type:(int)type
{
	TwoPort *e ;
	
	switch ( type ) {
	default:
	case TRANSMISSIONLINETYPE: 
		e = [ TransmissionLine alloc ] ; 
		break ;
	case NETWORKTYPE: 
		e = [ Network alloc ] ; 
		break ;
	}
	[ self autorelease ] ;
	self = [ e initWithDelegate:client withType:type ] ;

	//  now initialize from dictionary
	[ self restoreFromDictionary:dict ] ;
	return self ;
}

- (void)awakeFromNib
{
	[ window setDelegate:self ] ;
	[ typeTab selectTabViewItemWithIdentifier:[ NSString stringWithFormat:@"%ld", selectedType ] ] ;
	[ typeTab setDelegate:self ] ;
}

- (void)dealloc
{
	[ window setDelegate:nil ] ;
	[ typeTab setDelegate:nil ] ;
    [ retainedNibObjects release ] ;
	[ super dealloc ] ;
}

//  open the inspector window at the tab that correspond to the wire type
- (void)openInspector:(id)client
{
	NSArray *tabs ;
	intType count, i ;
	
	opened = YES ;
	tabs = [ typeTab tabViewItems ] ;
	count = [ tabs count ] ;
	for ( i = 0; i < count; i++ ) {
		if ( [ [ [ tabs objectAtIndex:i ] identifier ] intValue ] == selectedType ) {
			[ typeTab selectTabViewItemAtIndex:i ] ;
			break ;
		}
	}	
	[ window makeKeyAndOrderFront:self ] ;
}

- (int)segmentNumberForWire:(ElementGeometry*)wire matrix:(NSMatrix*)locationMatrix segmentField:(NSTextField*)segment
{
	int segments ;

	segments = [ (WireGeometry*)wire numberOfSegments ] ;
	if ( segments <= 0 ) {
		[ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Number of segments missing for element named %s.", [ [ wire nameField ] UTF8String ] ] ] ;
		return 1 ;
	}
	switch ( [ locationMatrix selectedRow ] ) {
	default:
	case 0:
		// center segment
		return ( segments+1 )/2 ;
	case 1:
		return 1 ;
	case 2:
		return segments ;
	case 3:
		return [ segment intValue ] ;
	}
	return 1 ;
}

- (const char*)evalDoubleAsString:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName negate:(Boolean)negate
{
	NSString *string ;
	EvalResult result ;
	double resultValue, p ;
	
	string = [ [ matrix cellAtRow:row column:0 ] stringValue ] ;
	if ( string == nil || [ string length ] == 0 ) {		
		if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Empty \"%s\" cell (row %d of network table).", cellName, networkRow+1 ] ] ;
		// empty cell
		resultValue = 0.0 ;
	}
	else {
		result = [ [ [ NSApp delegate ] currentSpreadsheet ] evaluateFormula:string ] ;
		if ( result.errorCode != 0 ) {
			if ( cellName != nil ) [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Formular error in \"%s\" cell (row %d of network table).", cellName, networkRow+1 ] ] ;
			resultValue = 0.0 ;
		}
		else {
			resultValue = result.value ;
		}
	}
	p = fabs( resultValue ) ;
	
	//  if negate, return negative of the absolute value
	if ( negate ) return dtos( -p ) ;
	return dtos( resultValue ) ;
}

- (const char*)evalDoubleAsString:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName
{
	return [ self evalDoubleAsString:matrix row:row cellName:cellName negate:NO ] ;
}

- (Boolean)ignoreCard
{
	return ignore ;
}

- (void)bringToFront
{
	if ( [ window isVisible ] ) [ window orderFront:self ] ;
}

- (Boolean)opened
{
	return opened ;
}

- (void)hideWindow
{
	[ window orderOut:self ] ;
}

- (void)showWindow
{
	[ window orderFront:self ] ;
}

- (NSString*)fromField
{
	return ( from == nil ) ? @"" : from ;
}

- (void)setFrom:(NSString*)str 
{
	if ( from ) [ from release ] ;
	from = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)typeField
{
	int type ;
	NSTabViewItem *tabItem = [ typeTab selectedTabViewItem ] ;
	type = [ [ tabItem identifier ] intValue ] ;
	
	switch ( type ) {
	case NETWORKTYPE:
		return @"NT" ;
	case TRANSMISSIONLINETYPE:
		return @"TL" ;
	}
	return @"" ;
}

- (NSString*)toField
{
	return ( to == nil ) ? @"" : to ;
}

- (void)setTo:(NSString*)str
{
	if ( to ) [ to release ] ;
	to = [ [ NSString alloc ] initWithString:str ] ;
}

- (NSString*)ignoreField
{
	return ( ignore ) ? @"*" : @"" ;
}

- (void)setIgnore:(NSString*)str
{
	ignore = ( str != nil && [ str length ] == 1 && [ str characterAtIndex:0 ] == '*' ) ;
}

- (NSString*)commentField
{
	return ( comment == nil ) ? @"" : comment ;
}

- (void)setComment:(NSString*)str
{
	if ( comment ) [ comment release ] ;
	comment = [ [ NSString alloc ] initWithString:str ] ;
}

- (ElementGeometry*)getElementGeometry:(NSString*)name row:(int)row type:(char*)type
{
	ElementGeometry *e ;
	
	if ( name == nil ) {
		 [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"%s at row %d of network table is missing an element name.", type, row+1 ] ] ;
		 return nil ;
	}
	e = [ spreadsheet wireForName:name ] ;
	if ( e == nil ) {
		 [ [ NSApp delegate ] insertError:[ NSString stringWithFormat:@"Cannot find an element named \"%s\" used in %s.\n", [ name UTF8String ], type ] ] ;
		 return nil ;
	}
	return e ;
}

//  this is implemented by subclasses Network and TransmissionLine
- (Boolean)ncCode:(NSMutableString*)code eval:(Spreadsheet*)spreadsheet networkRow:(int)row
{
	return NO ;
}

- (NSString*)networkCard:(Expression*)e spreadsheet:(Spreadsheet*)client networkRow:(int)row
{
	return @"none" ;
}

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

- (NSMutableDictionary*)makePlistDictionary
{
	//  override in Network.m and TransmissionLine.m
	return nil ;
}

- (void)restoreFromDictionary:(NSDictionary*)dict
{
	//  override in Network.m and TransmissionLine.m
}

@end
