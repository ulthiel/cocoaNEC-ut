//
//  Spreadsheet.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/1/07.
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


#import "Spreadsheet.h"
#import "ApplicationDelegate.h"
#import "CurrentSource.h"
#import "DateFormat.h"
#import "Environment.h"
#import "expression.h"
#import "formats.h"
#import "Networks.h"
#import "Primary.h"
#import "Exception.h"
#import "Variables.h"
#import "Transforms.h"
#import "VariableObject.h"
#import "tokens.h"

//  v0.55
#import "NCCompiler.h"
#import "NCFunctionObject.h"
#import "NCForSpreadsheet.h"

//  v0.65
#import "StringUtils.h"

//  v0.88
#import "SavePanelExtension.h"
#import "AlertExtension.h"
#import "Bundle.h"

@implementation Spreadsheet

//  This class is the data source of the Geometry tableview
//  if old is not nil, copy all properties from old
- (id)initWithGlobals:(GlobalContext*)glob number:(int)num untitled:(Boolean)isUntitled
{
	self = [ super init ] ;
	if ( self ) {
		nc = nil ;
		globals = glob ;
		documentNumber = num ;
		untitled = isUntitled ;
		cards = 0 ;
		wireArray = [ [ NSMutableArray alloc ] init ] ;		//  array of WireObjects; maps to each row of the spreadsheet
		exceptions = [ [ NSMutableArray alloc ] init ] ;	//  exceptions such as current sources
		selectedRow = 0 ;
		selectedColumn = nil ;
		errorString = nil ;
		conversionType = conversionMETRIC ;
		plist = nil ;
		sourcePath = nil ;
        
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"Spreadsheet" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;

        outputControl = [ [ OutputControl alloc ] init ] ;
		[ outputControl setDefaultPattern:YES ] ;
		
		//  v0.55  NC Stack
		stack.commentDeck = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
		stack.geometryElements = [ [ NSMutableArray alloc ] initWithCapacity:32 ] ;
		stack.controlDeck = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
		stack.exceptions = [ [ NSMutableArray alloc ] initWithCapacity:32 ] ;	//  exceptions such as current sources and radials
		stack.errors = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;

		dirty = NO ;
	}
	return self ;
}

- (void)dealloc
{
	[ window setDelegate:nil ] ;
	if ( sourcePath ) [ sourcePath release ] ;
	if ( plist ) [ plist release ] ;
	if ( nc) [ nc release ] ;
	[ outputControl release ] ;
	[ wireArray release ] ;
    [ retainedNibObjects release ] ;
	[ super dealloc ] ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	NSRect frame ;
	NSArray *column = [ table tableColumns ] ;
	
	numberColumn = [ column objectAtIndex:0 ] ;
	x1Column = [ column objectAtIndex:1 ] ;
	y1Column = [ column objectAtIndex:2 ] ;
	z1Column = [ column objectAtIndex:3 ] ;
	x2Column = [ column objectAtIndex:5 ] ;
	y2Column = [ column objectAtIndex:6 ] ;
	z2Column = [ column objectAtIndex:7 ] ;
	diamColumn = [ column objectAtIndex:9 ] ;
	segmentsColumn = [ column objectAtIndex:10 ] ;
	transformColumn = [ column objectAtIndex:11 ] ;
	ignoreColumn = [ column objectAtIndex:13 ] ;
	nameColumn = [ column objectAtIndex:14 ] ;
	commentColumn = [ column objectAtIndex:15 ] ;
	
	[ table setDelegate:self ] ;
	[ table setDataSource:self ] ;
	
	[ formulaBar setDelegate:self ] ;
	[ formulaBar setEnabled:NO ] ;
	
	[ self setInterface:conversionMenu to:@selector(conversionSelected) ] ;
	[ self conversionSelected ] ;
	
	[ variables setDelegate:self ] ;
	[ transforms setDelegate:self ] ;
	
	frame = [ window frame ] ;
	frame.origin.x += 20*( documentNumber-1 ) ;
	frame.origin.y -= 22*( documentNumber-1 ) ;
	[ window setFrame:frame display:YES ] ;

	[ window setTitle:[ NSString stringWithFormat:@"Untitled Antenna-%d", documentNumber ] ] ;
	[ window setHidesOnDeactivate:NO ] ;
	[ window setLevel:NSNormalWindowLevel ] ;
	[ window setMaxSize:NSMakeSize( 1124, 1000 ) ] ;
	[ window setMinSize:NSMakeSize( 630, 300 ) ] ;
	[ window setDelegate:self ] ;
}

- (void)setSourcePath:(NSString*)path
{
	if ( sourcePath != nil ) [ sourcePath autorelease ] ;
	sourcePath = ( path == nil ) ? nil : [ [ NSString alloc ] initWithString:path ] ;
}

//  delegate to ElementGeometry
- (void)spreadsheetCellChanged:(id)sender
{
	[ table reloadData ] ;
}

//  delegate to Variables
- (void)variableChanged:(id)sender
{
	[ table reloadData ] ;
}

//  place string into the formula bar and select it as first responder
//  when editing is done with a carriage return, the control:textShouldEndEditing will be called
- (Boolean)editFormula:(NSString*)str title:(NSString*)title
{
	[ formulaTitle setTextColor:[ NSColor redColor ] ] ;
	[ formulaTitle setStringValue:[ title stringByAppendingString:@" :" ] ] ;
	[ formulaBar setEnabled:YES ] ;
	[ formulaBar setStringValue:str ] ;
	[ [ formulaBar window ] makeFirstResponder:formulaBar ] ;
	return YES ;
}

- (void)clearFormulaBar
{
	[ formulaBar setEnabled:NO ] ;
	[ formulaBar setStringValue:@"" ] ;
	[ formulaTitle setTextColor:[ NSColor blackColor ] ] ;
	[ formulaTitle setStringValue:@"Edit:" ] ;
}

//  v0.55
- (EvalResult)executeFunction:(NCCompiler*)compiler
{
	NCSystem *system ;
	NCFunctionObject *function ;
	EvalResult result ;
	
	system = [ compiler system ] ;
	[ [ NSApp delegate ] setCurrentNCSystem:system ] ;
	[ system clearAbort ] ;
	[ system setRunLoops:0 ] ;				//  block any runs for now
	
	stack.system = system ;
	[ system setRuntimeStack:&stack ] ;		//  set up the runtime stack for this run

	result.errorCode = result.errorOffset = 0 ;
	result.value = 0 ;
	result.errorString = @"" ;

	function = (NCFunctionObject*)[ [ compiler symbolTable ] containsIdent:@"SpreadSheet" ] ;
	if ( function == nil || [ function isFunction ] == NO ) {
		printf( "did not find spreadsheet function?\n" ) ;
		result.errorCode = 1 ;
		return result ;
	}
	//  update global variables
	[ system setSpreadSheetFrequency:[ environment frequency ] dielectric:[ environment dielectric ] conductivity:[ environment conductivity ] ] ;
	result.value = [ function evalFunctionAsReal:&stack args:nil system:system ] ;
	
	result.errorCode = 0 ;
	return result ;
}

//  v0.57
- (void)addGlobalAssignments:(NSMutableString*)string
{
	double freq ;
	
	freq = [ environment frequency ] ;
	if ( freq < 0.00001 ) freq = 0.00001 ;
	[ string appendString:@"g_pi=3.14159265358979323;\n" ] ;
	[ string appendString:@"g_c=299.792459;\n" ] ;
	[ string appendFormat:@"g_frequency=%f;\n", freq ] ;
	[ string appendFormat:@"g_wavelength=%f;\n", 299.792459/freq ] ;
	[ string appendFormat:@"g_dielectric=%f;\n", [ environment dielectric ] ] ;
	[ string appendFormat:@"g_conductivity=%f;\n", [ environment conductivity ] ] ;
	
}

//  v0.59
- (void)addLocalDeclarations:(NSMutableString*)string
{
	NSArray *var ;
	VariableObject *obj ;
	NSString *value ;
	intType i, count ;
	
	var = [ variables variableList ] ;
	count = [ var count ] ;
	
	for ( i = 0; i < count; i++ ) {
		obj = [ var objectAtIndex:i ] ;
		value = [ obj value ] ;
		if ( value != nil && [ value length ] > 0 ) [ string appendFormat:@"real %s ;\n", [ [ obj name ] UTF8String ] ] ;
	}
}

//  v0.59
- (void)addVariableAssignments:(NSMutableString*)string
{
	NSArray *var ;
	VariableObject *obj ;
	NSString *value ;
	intType i, count ;
	
	var = [ variables variableList ] ;
	count = [ var count ] ;
	
	for ( i = 0; i < count; i++ ) {
		obj = [ var objectAtIndex:i ] ;
		value = [ obj value ] ;
		if ( value != nil && [ value length ] > 0 ) [ string appendFormat:@"%s = %s ;\n", [ [ obj name ] UTF8String ], [ value UTF8String ] ] ;
	}
}

//  v0.59
- (void)addVariables:(NSMutableString*)string
{
	[ self addLocalDeclarations:string ] ;
	[ self addVariableAssignments:string ] ;
}

//  v0.55
- (NSString*)makeFunctionForNC:(NSString*)formula
{
	NSMutableString *result ;
	
	result = [ [ NSMutableString alloc ] initWithCapacity:1024 ] ;
	// add spreadsheet globals
	[ result appendString:@"real SpreadSheet() {\n" ] ;
	// add local variables here
	[ self addVariables:result ] ;
	[ result appendString:@"return (" ] ;
	[ result appendString:formula ] ;
	[ result appendString:@"); }\n" ] ;
	return result ;
}

- (EvalResult)evaluateFormula:(NSString*)formula
{
	NCCompiler *compiler ;
	NSArray *compilerErrors ;
	EvalResult result ;
	Boolean success ;
	NSString *ncCode ;
	
	result.errorCode = 0 ;
	result.value = 0 ;
	result.errorOffset = 0 ;
	result.errorString = @"";

	if ( !formula || [ formula length ] == 0 ) {
		result.errorCode = 1 ;
		return result ;
	}
	
	ncCode = [ self makeFunctionForNC:formula ] ;
	compiler = [ [ NCCompiler alloc ] initWithString:ncCode ] ;
	
	success = [ compiler compile ] ;
	if ( success == NO ) {
		compilerErrors = [ compiler parseErrors ] ;
		if ( [ compilerErrors count ] > 0 ) {
			result.errorCode = 1 ;
			return result ;
		}
	}
	//  initialize stack
	[ stack.commentDeck removeAllObjects ] ;
	[ stack.geometryElements removeAllObjects ] ;
	[ stack.controlDeck removeAllObjects ] ;
	[ stack.exceptions removeAllObjects ] ; 
	[ stack.errors removeAllObjects ] ; 				
	//  run the compiled code
	result = [ self executeFunction:compiler ] ;
	
	return result ;
}

//  v0.55
//	object must take -stringValue
- (int)intValueForObject:(id)object
{
	EvalResult result = [ self evaluateFormula:[ object stringValue ] ] ;
	return (int)( result.value + 0.01 ) ;
}

//  v0.55
//	object must take -stringValue
- (double)doubleValueForObject:(id)object
{
	EvalResult result = [ self evaluateFormula:[ object stringValue ] ] ;
	return result.value ;
}

//	interpret spreadsheet cell
- (NSString*)interpretSpreadsheetCell:(NSString*)formula conversion:(int)conversionMethod
{
	NCCompiler *compiler ;
	NSArray *compilerErrors ;
	Boolean success ;
	EvalResult result ;
	NSString *units, *ncCode ;
	int feet, places, sign, ch ;
	float value, inch, frequency ;
	
	if ( viewAsFormulas ) return formula ;
	
	if ( !formula || [ formula length ] == 0 ) return @"" ;
	ch = [ formula characterAtIndex:0 ] ;
	if ( ch == '@' ) return @"not yet" ;
	if ( ch == '!' ) return formula ;
	
	ncCode = [ self makeFunctionForNC:formula ] ;
	compiler = [ [ NCCompiler alloc ] initWithString:ncCode ] ;
	success = [ compiler compile ] ;
	if ( success == NO ) {
		compilerErrors = [ compiler parseErrors ] ;
		if ( [ compilerErrors count ] > 0 ) return @"*error*" ;
	}
	//  initialize stack
	[ stack.commentDeck removeAllObjects ] ;
	[ stack.geometryElements removeAllObjects ] ;
	[ stack.controlDeck removeAllObjects ] ;
	[ stack.exceptions removeAllObjects ] ; 
	[ stack.errors removeAllObjects ] ; 				
	//  run the compiled code
	result = [ self executeFunction:compiler ] ;
	if ( result.errorCode != 0 ) return @"*error*" ;

	sign = ( result.value < 0 ) ? (-1) : 1 ;
	value = fabs( result.value ) ;
	[ ncCode release ] ;
	
	if ( conversionMethod == conversionInteger ) return [ NSString stringWithFormat:@"%d", (int)( ( value+0.1 )*sign ) ] ;
	if ( conversionMethod == conversionReal ) return [ NSString stringWithFormat:@"%f", result.value ] ;
	
	if ( conversionType == conversionMETRIC  ) {	
		if ( value == 0 ) return @"0.0" ;
		places = ( sign < 0 ) ? 7 : 6 ;
		if ( value > 0.01 ) return [ [ NSString stringWithFormat:@"%f", value*sign ] substringToIndex:places ] ;
		value *= 100 ;
		if ( value > 1 ) {
			units = @" cm" ;
		}
		else {
			value *= 10 ;
			units = @" mm" ;
		}
		return [ [ [ NSString stringWithFormat:@"%f", value*sign ] substringToIndex:places ]  stringByAppendingString:units ] ;
	}
	
	//  English system
	if ( conversionType == conversionENGLISH ) {
		value /= FEET ;
		places = ( sign < 0 ) ? 6 : 5 ;
		if ( value*12 < 1 ) {
			value *= 12 ;
			units = @" in" ;
		}
		else units = @" ft" ;
		
		if ( value == 0.0 ) return [ @"0.0" stringByAppendingString:units ] ; 
		
		return [ [ [ NSString stringWithFormat:@"%f", value*sign ] substringToIndex:places ] stringByAppendingString:units ] ;
	}
	//  Mixed ft/inch
	if ( conversionType == conversionMIXEDENGLISH ) {
		value /= FEET ;
		feet = value ;
		inch = ( value - feet )*12 ;
		if ( inch < 0.001 ) {
			//  no fractional part
			return [ NSString stringWithFormat:@"%d ft", feet*sign ] ;
		}
		if ( feet == 0 ) {
			if ( inch < 1.0 ) return [ NSString stringWithFormat:@"%.3f in", inch*sign ] ;
			return [ NSString stringWithFormat:@"%.1f in", inch*sign ] ;
		}
		return [ NSString stringWithFormat:@"%d' %.1f\"", feet*sign, inch ] ;
	}
	//  wavelength relative
	places = ( sign < 0 ) ? 7 : 6 ;
	frequency = [ environment frequency ] ;
	value = value*frequency/ 299.7925 ;
	if ( value == 0 ) return @"0.0" ;
	return [ [ NSString stringWithFormat:@"%f", value*sign ] substringToIndex:places ] ;
}

//  formula field started editing, set delegate to wait for end notification
- (BOOL)control:(NSControl*)control textShouldBeginEditing:(NSText*)fieldEditor
{
	if ( control == formulaBar ) {
		formulaFieldEditor = fieldEditor ;
		[ fieldEditor setDelegate:self ] ;
		return YES ;
	}
	//  allow name and comment field of spreadsheet to be directly edited
	if ( control == table ) {
		return ( selectedColumn == nameColumn || selectedColumn == commentColumn || selectedColumn == transformColumn ) ;	//  v0.55
	}
	return NO ;
}

- (void)textDidEndEditing:(NSNotification*)notification
{
	int movementCode ;
	NSTableColumn *nextColumn = nil ;
	int nextRow = 0 ;
	
	[ formulaFieldEditor setDelegate:nil ] ;

	//  find if movement code is a tab
	movementCode = [ [ [ notification userInfo ] objectForKey:@"NSTextMovement" ] intValue ] ;
	
	if ( selectedColumn != nil ) {
		WireGeometry *wire = [ wireArray objectAtIndex:selectedRow ] ;

		NSString *editedString = [ formulaBar stringValue ] ;
		
		if ( selectedColumn == x1Column ) {
			[ wire setComponentOfEnd1:0 string:editedString ] ;
			nextColumn = y1Column ;
		}
		else if ( selectedColumn == y1Column ) {
			[ wire setComponentOfEnd1:1 string:editedString ] ;
			nextColumn = z1Column ;
		}
		else if ( selectedColumn == z1Column ) {
			[ wire setComponentOfEnd1:2 string:editedString ] ;
			nextColumn = x2Column ;
		}
		else if ( selectedColumn == x2Column ) {
			[ wire setComponentOfEnd2:0 string:editedString ] ;
			nextColumn = y2Column ;
		}
		else if ( selectedColumn == y2Column ) {
			[ wire setComponentOfEnd2:1 string:editedString ] ;
			nextColumn = z2Column ;
		}
		else if ( selectedColumn == z2Column ) {
			[ wire setComponentOfEnd2:2 string:editedString ] ;
			nextColumn = diamColumn ;
		}
		else if ( selectedColumn == diamColumn ) {
			[ wire setRadiusFormula:editedString ] ;
			nextColumn = segmentsColumn ;
		}
		else if ( selectedColumn == segmentsColumn ) {
			[ wire setSegmentsFormula:editedString ] ;
			nextColumn = nil ;
		}
		nextRow = selectedRow ;
		selectedRow = 0 ;
		selectedColumn = nil ;		
		[ table reloadData ] ;
	}	
	[ self clearFormulaBar ] ;
	
	if ( movementCode == NSTabTextMovement && nextColumn != nil ) {
		//  field editor left on a tab character
		[ self editTableColumn:nextColumn row:nextRow ] ;
	}
}

//  NSDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView != table ) return 0 ;
	return cards ;
}

//	v0.55
- (IBAction)openNC:(id)sender
{
	NSWindow *cardsWindow ;
	
	cardsWindow = [ tabView window ] ;
	[ cardsWindow makeKeyAndOrderFront:self ] ;
}

- (IBAction)openEnvironment:(id)sender
{
	[ environment showSheet:window ] ;
}

- (IBAction)openNetworksPanel:(id)sender
{
	[ networks showSheet:window ] ;
}

- (IBAction)openVariablesPanel:(id)sender
{
	[ variables showSheet:window ] ;
}

- (IBAction)openTransformsPanel:(id)sender
{
	[ transforms showSheet:window ] ;
}

- (IBAction)openOutputControl:(id)sender
{
	[ outputControl showSheet:window ] ;
}

- (void)inspectGeometryElement
{
	intType row ;
	
	if ( table ) {
		row = [ table selectedRow ] ;
		if ( row >= 0 ) {
			selectedRow = 0 ;
			selectedColumn = nil ;		
			[ self clearFormulaBar ] ;
			[ [ wireArray objectAtIndex:row ] openInspector:self ] ;
		}
	}
}

//  add button and contextual menu for add button comes here (tag selects type to add)
- (IBAction)addGeometryCard:(NSButton*)sender
{
	intType n = [ table selectedRow ]+1 ;
	
	if ( n < 0 ) n = cards ; 
	
	[ wireArray insertObject:[ [ ElementGeometry alloc ] initWithDelegate:self type:[ sender tag ] ] atIndex:n ] ;
	cards++ ;

	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:n ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:n ] ;
}

- (IBAction)removeGeometryCard:(id)sender
{
	intType row = [ table selectedRow ] ;
	if ( row < 0 ) return ;

	ElementGeometry *wire = [ wireArray objectAtIndex:row ] ;
	[ wire closeInspector:self ] ;
	[ wireArray removeObjectAtIndex:row ] ;
	[ wire release ] ;
	cards-- ;
	if ( cards < 0 ) cards = 0 ;
	[ table reloadData ] ;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	NSTextField *transformField ;
	
	if ( tableView == table ) {
		WireGeometry *wire = [ wireArray objectAtIndex:row ] ;	

		if ( tableColumn == numberColumn ) return [ NSString stringWithFormat:@"%d", row+1 ] ;
	
		if ( tableColumn == transformColumn ) {			//  v0.55
			transformField = [ wire transformField ] ;
			if ( transformField == nil ) return @"" ;
			return [ transformField stringValue ] ;
		}

		if ( [ wire wireType ] != WIRETYPE ) {
			if ( tableColumn == x1Column ) return [ wire typeString ] ;
		}
		else {
			if ( tableColumn == x1Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd1:0 ] conversion:conversionNormal ] ;
			if ( tableColumn == y1Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd1:1 ] conversion:conversionNormal ] ;
			if ( tableColumn == z1Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd1:2 ] conversion:conversionNormal ] ;
			if ( tableColumn == x2Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd2:0 ] conversion:conversionNormal ] ;
			if ( tableColumn == y2Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd2:1 ] conversion:conversionNormal ] ;
			if ( tableColumn == z2Column ) return [ self interpretSpreadsheetCell:[ wire componentOfEnd2:2 ] conversion:conversionNormal ] ;
			if ( tableColumn == diamColumn ) return [ self interpretSpreadsheetCell:[ wire radiusFormula ] conversion:conversionNormal ] ;
			if ( tableColumn == segmentsColumn ) return [ self interpretSpreadsheetCell:[ wire segmentsFormula ] conversion:conversionInteger ] ;
		}
		if ( tableColumn == nameColumn ) return [ StringUtils prependSpace:[ wire nameField ] ] ;			//  v0.65
		if ( tableColumn == commentColumn ) return [ StringUtils prependSpace:[ wire commentField ] ] ;		//  v0.65
		if ( tableColumn == ignoreColumn ) return [ wire ignoreField ] ;									//  v0.65
	}
	return @"" ;
}

//	(Private API)
- (Boolean)editTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	WireGeometry *wire = [ wireArray objectAtIndex:row ] ;		
	if ( tableColumn == ignoreColumn ) {
		//  flip ignore flag
		[ wire setIgnore:( [ wire ignoreCard ] ? @"" : @"*" ) ] ;
		[ table setNeedsDisplayInRect:[ table rectOfRow:row ] ] ;
		return NO ;
	}

	
	intType wireType = [ wire wireType ] ;
	if ( wireType == WIRETYPE ) {
		selectedRow = 0 ;
		selectedColumn = nil ;
		
		if ( tableColumn == x1Column ) [ self editFormula:[ wire componentOfEnd1:0 ] title:@"x1" ] ;
		else if ( tableColumn == y1Column ) [ self editFormula:[ wire componentOfEnd1:1 ] title:@"y1" ] ;
		else if ( tableColumn == z1Column ) [ self editFormula:[ wire componentOfEnd1:2 ] title:@"z1" ] ;
		else if ( tableColumn == x2Column ) [ self editFormula:[ wire componentOfEnd2:0 ] title:@"x2" ] ;
		else if ( tableColumn == y2Column ) [ self editFormula:[ wire componentOfEnd2:1 ] title:@"y2" ] ;
		else if ( tableColumn == z2Column ) [ self editFormula:[ wire componentOfEnd2:2 ] title:@"z2" ] ;
		else if ( tableColumn == diamColumn ) [ self editFormula:[ wire radiusFormula ] title:@"radius" ] ;
		else if ( tableColumn == segmentsColumn ) [ self editFormula:[ wire segmentsFormula ] title:@"segments" ] ;
	}
	selectedRow = row ;
	selectedColumn = tableColumn ;
	return ( tableColumn == nameColumn || tableColumn == commentColumn ) ;
}

- (BOOL)tableView:(NSTableView*)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView != table ) return NO ;
	
	if ( tableColumn == transformColumn ) {
		selectedColumn = transformColumn ;
		return YES ;		//  v0.55
	}

	if ( tableColumn == numberColumn ) {
		[ self inspectGeometryElement ] ;
		return NO ;
	}
	Boolean canEdit = [ self editTableColumn:tableColumn row:row ] ;
	
	return canEdit ;
}

//  accept edited name and comment from the tableview field cells
- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	NSTextField *transformField ;

	if ( tableView != table ) return ;

	ElementGeometry *wire = [ wireArray objectAtIndex:row ] ;	

	if ( tableColumn == nameColumn ) [ wire setName:object ] ;
	if ( tableColumn == commentColumn ) [ wire setComment:object ] ;
	if ( tableColumn == ignoreColumn ) [ wire setIgnore:object ] ;
	
	if ( tableColumn == transformColumn ) {		//  v0.55
		transformField = [ wire transformField ] ;
		[ transformField setStringValue:object ] ;
	}
}

- (BOOL)tableView:(NSTableView*)tableView shouldSelectRow:(int)row
{
	if ( tableView != table ) return NO ;
	
	ElementGeometry *wire = [ wireArray objectAtIndex:row ] ;	
	intType wireType = [ wire wireType ] ;
	
	if ( wireType != WIRETYPE ) [ wire bringToFront ] ;
	return YES ;
}

- (void)outputCard:(NSString*)cardImage
{
	fprintf( writefd, "%s\n", [ cardImage UTF8String ] ) ;
}

- (ElementGeometry*)wireForName:(NSString*)name
{
	ElementGeometry *wire ;
	intType i, wires ;
	
	wires = [ wireArray count ] ;

	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] && [ name isEqualToString:[ wire nameField ] ] ) return wire ;
	}
	return nil ;
}

//  generate Hollerith cards
- (Boolean)outputHollerith:(NSString*)path
{
	ElementGeometry *wire ;
	CurrentSource *auxWire ;
	Expression *expression ;
	Exception *exception ;
	NSArray *array ;
	int i, j, tag, step, total ;
    intType wires, count, steps ;
	double wiremax, maxDimension ;
	NECRadials *necRadials ;
	
	printf( "Spreadsheet: *OLD* outputHollerith called\n" ) ;

	writefd = fopen( [ path UTF8String ], "w" ) ;	//  becomes nec2's input
	if ( !writefd ) return NO ;
	
	[ [ NSApp delegate ] clearError ] ;
	[ variables validate ] ;
	expression = [ [ Expression alloc ] initWithLibrary:[ globals library ] parameters:[ environment parameter ] variables:[ variables dictionary ] ] ;
	
	wires = [ wireArray count ] ;
	tag = 1 ;
	
	//  Geometry Cards
	total = 0 ;
	wiremax = 0.0 ;
	maxDimension = 1.0 ;
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] ) {
			array = [ wire geometryCards:expression tagStarting:tag spreadsheetRow:i+1 ] ;
			count = [ array count ] ;
			for ( j = 0; j < count; j++ ) [ self outputCard:[ array objectAtIndex:j ] ] ;
			tag += count ;
			total += count ;			
			//  find bounds of geometry
			wiremax = [ wire maxDimension ] ;
			if ( wiremax > maxDimension ) maxDimension = wiremax ;
		}
	}
	if ( total <= 0 ) {
        //  v0.88
		[ AlertExtension modalAlert:@"No Geometry Element??" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThere is no wire in your model.\n" ] ;

        return NO ;
	}
	
	//  generate short wires for current sources
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] ) {
			auxWire = (CurrentSource*)[ wire attachedWire ] ;
			if ( auxWire != nil ) {
				array = [ auxWire geometryCards:expression tag:tag displacement:maxDimension*2 ] ;
				count = [ array count ] ;
				for ( j = 0; j < count; j++ ) [ self outputCard:[ array objectAtIndex:j ] ] ;
				tag += count ;
				total += count ;	
				exception = [ Exception exceptionForCurrentSource:[ auxWire tag ] targetTag:[ auxWire targetTag ] targetSegment:[ auxWire targetSegment ] ] ;
				[ exceptions addObject:exception ] ;

			}
		}
	}
	// end geometry
	Boolean isFreeSpace = [ environment isFreeSpace ] ;
	
	if ( isFreeSpace ) [ self outputCard:@"GE  0" ] ; else [ self outputCard:@"GE  1" ] ;
	
	if ( [ outputControl isExtendedkernel ] )  [ self outputCard:@"EK  0" ] ;

	// Ground card
	necRadials = nil ;
	int nRadials = ( necRadials ) ?  ( necRadials->n ) : 0 ;
	int groundType = [ environment groundType ] ;
	
	if ( groundType == 1 ) {
		//  perfect ground 
		[ self outputCard:[ NSString stringWithFormat:@"GN  1%5d    0                 ", nRadials ] ] ;
	}
	else {
		if ( isFreeSpace == NO ) {
			double dielectric = [ environment dielectric ] ;
			double conductivity = [ environment conductivity ] ;
			int sommerfeld = ( groundType == 2 ) ? 2 : 0 ;
			//  finite ground
			if ( nRadials == 0 ) {
				[ self outputCard:[ NSString stringWithFormat:@"GN  %d%5d    0    0%10s%10s", sommerfeld, nRadials, dtos( dielectric ), dtos( conductivity ) ] ] ;
			}
			else {
				[ self outputCard:[ NSString stringWithFormat:@"GN  %d%5d    0    0%10s%10s%10s%10s", sommerfeld, nRadials, dtos( dielectric ), dtos( conductivity ), dtos( necRadials->length ), dtos( necRadials->wireRadius ) ] ] ;
			}
		}
	}
	
	//  Loading Cards
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] ) {
			array = [ wire loadingCards:expression ] ;
			count = [ array count ] ;
			for ( j = 0; j < count; j++ ) [ self outputCard:[ array objectAtIndex:j ] ] ;
		}
	}
	//  network cards (call back to output)
	[ networks outputCards:self expression:expression ] ;
	
	//  Current source Excitation Cards NT component
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] ) {
			array = [ wire networkForExcitationCards ] ;
			count = [ array count ] ;
			for ( j = 0; j < count; j++ ) [ self outputCard:[ array objectAtIndex:j ] ] ;
		}
	}

	//  Excitation Cards
	total = 0 ;
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;
		if ( ![ wire ignoreCard ] ) {
			array = [ wire excitationCards:expression ] ;
			count = [ array count ] ;
			for ( j = 0; j < count; j++ ) [ self outputCard:[ array objectAtIndex:j ] ] ;
			total += count ;
		}
	}
	if ( total <= 0 ) {
        //  v0.88
		[ AlertExtension modalAlert:@"No Excitation??" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nYou need to add an exitation (feed point) to at least one of the wires.\n" ] ;
        return NO ;
	}

	//  There is a bug in nec2c.rxq with multiple frequencies.
	//  Use local frequency stepping.
	NSArray *freqArray ;
	freqArray = [ environment frequencyArray ] ;
	steps = [ freqArray count ] ;
	
	for ( step = 0; step < steps; step++ ) {
	
		double freq = [ [ freqArray objectAtIndex:step ] doubleValue ] ;
		//  v0.52
		if ( freq < 999.9 ) {
			[ self outputCard:[ NSString stringWithFormat:@"FR  0    1    0    0%10.5f%10.5f", freq, 0.0 ] ] ;
		}
		else {
			[ self outputCard:[ NSString stringWithFormat:@"FR  0    1    0    0%10.3f%10.5f", freq, 0.0 ] ] ;
		}
		
		//  far field radiation patterns at 5000m distance
		float *azimuthArray = [ outputControl elevationAnglesForAzimuthPlot ] ;
		float *elevationArray = [ outputControl azimuthAnglesForElevationPlot ] ;
		int linear = 1 ;
		for ( i = 0; i < 3; i++ ) {
			//  azimuth pattern
			if ( azimuthArray[i] < 1000 ) {
				[ self outputCard:[ NSString stringWithFormat:@"RP  0%5d%5d %1d000%10.3f%10.3f%10.3f%10.3f%10.3E", 1, 360, linear, 90-azimuthArray[i], 0.0, 0.0, 1.0, [ outputControl azimuthDistance ] ] ] ;
			}
		}
		for ( i = 0; i < 3; i++ ) {
			//  elevation pattern
			if ( elevationArray[i] < 1000 ) {
				[ self outputCard:[ NSString stringWithFormat:@"RP  0%5d%5d %1d000%10.3f%10.3f%10.3f%10.3f%10.3E", 360, 1, linear, -90.0, elevationArray[i], 1.0, 0.0, [ outputControl elevationDistance ] ] ] ;
			}
		}
		//  Radiation Pattern for directivity computation
		//  RP  0   30   60 1000   0.00000   0.00000   6.00000   6.00000  5.00E+03  
		[ self outputCard:[ NSString stringWithFormat:@"RP  0%5d%5d %1d000%10.3f%10.3f%10.3f%10.3f%10.3E", 91, 120, linear, 0.0, 0.0, 2.0, 3.0, 5000.0 ] ] ;

		//  execute and end cards
		[ self outputCard:@"XQ" ] ;
	}
	[ self outputCard:@"EN" ] ;
	fclose( writefd ) ;
	
	[ expression release ] ;
	return YES ;
}

//  v0.59
- (void)addGlobalDeclarations:(NSMutableString*)string
{
	[ string appendString:@"real g_pi, g_c, g_frequency, g_wavelength, g_dielectric, g_conductivity ;\n" ] ;
}

//	v0.55
//	Used by =createDeckAndRun and -saveToHollerith
- (Boolean)createNCProgram
{
    int i ;
	intType elementCount, groundType ;
	ElementGeometry *element ;
	Boolean hasNECRadials, hasRadials ;
	NSString *codeString ;
	
	code = [ NSMutableString stringWithCapacity:8192 ] ;
	
	NSString *dateString = [ DateFormat descriptionWithCalendarFormat:@"Y-M-d HH:mm" ] ;
	[ code appendFormat:@"model( \"COCOANEC 2.0  %s\" ) {\n", [ dateString UTF8String ] ] ;
	[ environment generateComments:code ] ;

	//  geometry elements
	elementCount = [ wireArray count ] ;
	
	//  add element declarations
	if ( elementCount > 0 ) {
		[ code appendFormat:@"element" ] ;
		for ( i = 0; i < elementCount; i++ ) {
			if ( i < elementCount-1 ) [ code appendFormat:@" _e%d,", i ] ; else  [ code appendFormat:@" _e%d;\n", i ] ;
		}
	}
	//  global declarations
	[ self addGlobalDeclarations:code ] ;		//  v0.57
	//	local variables
	[ self addLocalDeclarations:code ] ;
	
	//  global assignments
	[ self addGlobalAssignments:code ] ;
	//  local assignments
	[ self addVariableAssignments:code ] ;
	
	for ( i = 0; i < elementCount; i++ ) {
		element = [ wireArray objectAtIndex:i ] ;
		if ( [ element ignoreCard ] == NO ) {
			codeString = [ element ncForGeometry:i ] ;
			[ code appendString:codeString ] ;
			[ code appendString:[ element ncForExcitation:i ] ] ;
			[ code appendString:[ element ncForLoading:i ] ] ;
		}
	}
	
	//  Generate radials if any, but only if NEC Radials is not requested.
	hasNECRadials = [ environment generateNECRadials:code ] ;
	if ( hasNECRadials == NO ) {
		hasRadials = [ environment generateRadials:code eval:self ] ;
	}
	if ( [ outputControl isExtendedkernel ] ) [ code appendString:@"useExtendedKernel(1);\n" ] ;
	
	//  Grounds
	
	groundType = [ environment groundType ] ;
	if ( groundType == 1 ) {
		[ code appendString:@"perfectGround();\n" ] ;
	}
	else {
		if ( [ environment isFreeSpace ] ) {
			[ code appendString:@"freespace();\n" ] ;
		}
		else {
			if ( groundType == 2 ) [ code appendString:@"useSommerfeldGround(1);\n" ] ;
			[ code appendFormat:@"ground(%f,%f);\n", [ environment dielectric ], [ environment conductivity ] ] ;
		}
	}
	
	//  networks
	[ networks ncCode:code eval:self ] ;
	
	NSArray *freqArray = [ environment frequencyArray ] ;
	intType freqSteps = [ freqArray count ] ;
	
	for ( i = 0; i < freqSteps; i++ ) {
		double freq = [ [ freqArray objectAtIndex:i ] doubleValue ] ;
		if ( i == 0 ) [ code appendFormat:@"setFrequency(%f);\n", freq ] ; else [ code appendFormat:@"addFrequency(%f);\n", freq ] ;
	}

	float *azimuthArray = [ outputControl elevationAnglesForAzimuthPlot ] ;
	[ code appendFormat:@"setAzimuthPlotDistance(%f);\n",[ outputControl azimuthDistance ] ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( azimuthArray[i] < 1000 ) {
			[ code appendFormat:@"azimuthPlotForElevationAngle(%f);\n", azimuthArray[i] ] ;
		}
	}
	
	
	float *elevationArray = [ outputControl azimuthAnglesForElevationPlot ] ;
	[ code appendFormat:@"setElevationPlotDistance(%f);\n",[ outputControl elevationDistance ] ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( elevationArray[i] < 1000 ) {
			[ code appendFormat:@"elevationPlotForAzimuthAngle(%f);\n", elevationArray[i] ] ;
		}
	}
	
	if ( [ outputControl isQuadPrecision ] ) [ code appendFormat:@"useQuadPrecision(1);\n" ] ;
	
	[ code appendString:@"}\n" ] ;
	return YES ;
}

- (void)saveToHollerith
{
	NSSavePanel *panel ;
	NSString *filePath, *directory ;
	NSInteger result ;

	panel = [ NSSavePanel savePanel ] ;
	[ panel setTitle:@"Save NEC-2 Hollerith Deck" ] ;
    //  v0.88  setRequiredFileType deprecated
    //  [ panel setRequiredFileType:@"deck" ] ;
    [ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"deck" ] ] ;
    
	directory = ( sourcePath ) ? [ sourcePath stringByDeletingLastPathComponent ] : [ [ NSApp delegate ] defaultDirectory ] ;	
    result = [ SavePanelExtension runModalFor:panel directory:directory file:[ window title ] ] ;
    
	if ( result == NSModalResponseOK  && [ panel URL ] != nil ) {
		filePath = [ [ panel URL ] path ] ; ;
		if ( [ self createNCProgram ] ) {
			if ( nc == nil ) nc = [ [ NCForSpreadsheet alloc ] initWithListView:ncView cardView:cardView ] ;
			[ [ NSApp delegate ] setCurrentNC:(NC*)nc ] ;
			[ nc setSourcePath:sourcePath ] ;
			[ nc createDeck:code ] ;
			[ nc outputHollerithToFile:filePath ] ;
		}
	}
}

- (Boolean)createDeckAndRun
{	
	if ( [ self createNCProgram ] ) {
		if ( nc == nil ) nc = [ [ NCForSpreadsheet alloc ] initWithListView:ncView cardView:cardView ] ;
		[ [ NSApp delegate ] setCurrentNC:(NC*)nc ] ;
		[ nc setSourcePath:sourcePath ] ;
		[ nc runSource:code ] ;
		return YES ;
	}
	return NO ;
}

- (Boolean)sanityCheck 
{
	if ( [ [ environment frequencyArray ] count ] < 2 ) return YES ;	
	if ( [ outputControl numberOfAzimuthPlots ] > 1 || [ outputControl numberOfElevationPlots ] > 1 ) {
		[ AlertExtension modalAlert:@"Too many plots." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nYou cannot have multiple frequencies selected in the Environment sheet and multiple angles selected in the Output Control sheet at the same time.\n\nEither use a single frequency or use only one azimuth and one elevation angle.\n" ] ;
		return NO ;
	}
	return YES ;
}

- (IBAction)runButtonPushed:(id)sender
{
	if ( [ self sanityCheck ] ) {
		[ self createDeckAndRun ] ;
		[ self spreadsheetCellChanged:self ] ;		// this will update the spreadsheet display	
		[ [ NSApp delegate ] showError ] ;
	}
}

/*  Unused
- (intType)tagForName:(NSString*)name
{
	intType i, wires = [ wireArray count ] ;
	ElementGeometry *e ;
	
	for ( i = 0; i < wires; i++ ) {
		e = [ wireArray objectAtIndex:i ] ;
		if ( [ name isEqualToString:[ e nameField ] ] == YES ) return [ e tag ] ;
	}
	return ( -1 ) ;
}
 */

- (void)conversionSelected
{
	conversionType = [ [ conversionMenu selectedItem ] tag ] ;
	[ table reloadData ] ;
}

- (void)dictionaryChanged
{
	[ table reloadData ] ;
}

- (void)setVariable:(NSString*)name to:(double)value
{
	Primary *p ;
	
	p = [ [ Primary alloc ] initWithDouble:value ] ;
}

// this comes from the Hide and Show in the dock (and hide in the main menu)
- (void)hideWindow
{
	intType i, wires ;
	ElementGeometry *wire ;
	
	[ window orderOut:self ] ;
	
	wires = [ wireArray count ] ;
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;	
		if ( [ wire opened ] ) [ wire hideWindow ] ;
	}
}

// this comes from the Hide and Show in the dock (and hide in the main menu)
- (void)showWindow
{
	intType i, wires ;
	ElementGeometry *wire ;

	[ window orderFront:self ] ;

	wires = [ wireArray count ] ;
	for ( i = 0; i < wires; i++ ) {
		wire = [ wireArray objectAtIndex:i ] ;	
		if ( [ wire opened ] ) [ wire showWindow ] ;
	}
}

- (void)becomeKeyWindow
{
	[ window makeKeyAndOrderFront:self ] ;
}

//  Delegate to window
- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
	[ [ NSApp delegate ] spreadsheetBecameKey:self ] ;
}

//  return YES if not dirty
//	v0.55
- (Boolean)windowCanClose
{
	NSInteger result ;
	const char *name ;
	
	//  make the window key before asking
	[ window makeKeyAndOrderFront:self ] ;
	if ( dirty == YES ) {
		name = [ [ window title ] cStringUsingEncoding:NSASCIIStringEncoding ] ;
        
        //  v0.88
        NSString *info = [ NSString stringWithFormat:@"\n%s has unsaved changes.  If you close the window, all changes will be lost.\n", name ] ;
        result = [ AlertExtension modalAlert:@"Warning: do you really want to close the model?" defaultButton:@"Do not close" alternateButton:@"Close" otherButton:nil informativeTextWithFormat:info ] ;
        
        if ( result == NSAlertFirstButtonReturn ) return NO ;
	}
	return YES ;
}

- (BOOL)windowShouldClose:(id)window
{
	if ( ![ self windowCanClose ] ) return NO ;
	[ [ NSApp delegate ] spreadsheetClosing:self ] ;
	return YES ;
}

// NSMenuValidation for "add" contextual menu
-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	return YES ;
}

//  create an array of wires for plist
- (NSMutableArray*)makeWireList 
{
	intType i, n ;
	ElementGeometry *e ;
	NSMutableDictionary *a ;

	plist = [ [ NSMutableArray alloc ] init ] ;
	n = [ wireArray count ] ;
	for ( i = 0; i < n; i++ ) {
		e = [ wireArray objectAtIndex:i ] ;
		if ( e != nil ) {
			a = [ e makePlist ] ;
			if ( a != nil ) [ plist addObject:a ] ;
		}
	}
	return plist ;
}

- (void)releasePlist
{
	intType i, n ;
	ElementGeometry *e ;
	
	if ( plist ) {
		[ plist removeAllObjects ] ;
		[ plist release ] ;
		plist = nil ;
		n = [ wireArray count ] ;
		//  release all descendants of plist array
		for ( i = 0; i < n; i++ ) {
			e = [ wireArray objectAtIndex:i ] ;
			if ( e != nil ) [ e releasePlist ] ;
		}
	}
}

- (void)restoreWiresFromArray:(NSArray*)array
{
	NSDictionary *elementDict ;
	intType i, n ;

	n = [ array count ] ;
	for ( i = 0; i < n; i++ ) {
		elementDict = [ array objectAtIndex:i ] ;
		[ wireArray insertObject:[ [ ElementGeometry alloc ] initWithDelegate:self data:elementDict ] atIndex:cards ] ;
		cards++ ;
	}	
	[ table reloadData ] ;
	[ table deselectAll:self ] ;
	[ table scrollRowToVisible:0 ] ;
}


- (void)updateFromPlist:(NSDictionary*)all name:(NSString*)name
{
	[ window setTitle:name ] ;

	[ self restoreWiresFromArray:[ all objectForKey:@"Wires" ] ] ;
	[ environment restoreRadialsFromDictionary:[ all objectForKey:@"Radials" ] ] ;
	[ variables restoreFromArray:[ all objectForKey:@"Variables" ] ] ;
	[ transforms restoreFromArray:[ all objectForKey:@"Transforms" ] ] ;
	[ environment restoreFromDictionary:[ all objectForKey:@"Controls" ] ] ;
	[ outputControl restoreFromDictionary:[ all objectForKey:@"Output" ] ] ;
	[ networks restoreFromArray:[ all objectForKey:@"Networks" ] ] ;

	dirty = NO ;
}

- (void)saveToPath:(NSString*)plistPath
{
	NSMutableDictionary *all, *controlList, *radials, *outputList ;
	NSMutableArray *variableList, *transformList, *wireList, *networkList ;
	
	all = [ [ NSMutableDictionary alloc ] init ] ;	
	//  wires
	wireList = [ self makeWireList ] ;
	[ all setObject:wireList forKey:@"Wires" ] ;
	//  radials
	radials = [ environment makeRadials ] ;
	[ all setObject:radials forKey:@"Radials" ] ;
	//  variables
	variableList = [ (Variables*)variables makePlist ] ;
	[ all setObject:variableList forKey:@"Variables" ] ;
	//  transforms
	transformList = [ (Transforms*)transforms makePlist ] ;
	[ all setObject:transformList forKey:@"Transforms" ] ;
	//  controls
	controlList = [ environment makeDictionaryForPlist ] ;
	[ all setObject:controlList forKey:@"Controls" ] ;
	//  output controls
	outputList = [ outputControl makeDictionaryForPlist ] ;
	[ all setObject:outputList forKey:@"Output" ] ;
	//  networks
	networkList = [ (Networks*)networks makePlistArray ] ;
	if ( networkList ) [ all setObject:networkList forKey:@"Networks" ] ;
	
	[ all writeToFile:plistPath atomically:YES ] ;
	[ all release ] ;
	
	//  release all descendants of plist array
	[ self releasePlist ] ;
	[ variables releasePlist ] ;
}

//  get a path to save
- (NSString*)save:(Boolean)ask
{
	NSSavePanel *panel ;
	NSString *plistPath, *directory ;
	NSInteger result ;
	
	plistPath = nil ;
	if ( ask || sourcePath == nil ) {
		plistPath = nil ;
		panel = [ NSSavePanel savePanel ] ;
		[ panel setTitle:@"Save antenna model" ] ;
        //  v0.88  setRequiredFileType deprecated
        //  [ panel setRequiredFileType:@"nec" ] ;
        [ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"nec" ] ] ;
 		
		directory = ( sourcePath ) ? [ sourcePath stringByDeletingLastPathComponent ] : [ [ NSApp delegate ] defaultDirectory ] ;	
        result = [ SavePanelExtension runModalFor:panel directory:directory file:[ window title ] ] ;
		if ( result == NSModalResponseOK && [ panel URL ] != nil ) {
			plistPath = [ [ panel URL ] path ] ;
			[ self saveToPath:plistPath ] ;
			[ window setTitle:[ [ plistPath lastPathComponent ] stringByDeletingPathExtension ] ] ;
			[ [ NSApp delegate ] setDefaultDirectory:[ plistPath stringByDeletingLastPathComponent ] ] ;
			[ self setSourcePath:plistPath ] ;
		}
	}
	else {
		plistPath = sourcePath ;
	}
	if ( plistPath != nil ) {
		[ self saveToPath:plistPath ] ;
		[ window setTitle:[ [ plistPath lastPathComponent ] stringByDeletingPathExtension ] ] ;
		[ [ NSApp delegate ] setDefaultDirectory:[ plistPath stringByDeletingLastPathComponent ] ] ;
		[ self setSourcePath:plistPath ] ;
		untitled = NO ;
		dirty = NO ;
	}
	return plistPath ;
}

- (NSString*)title
{
	return [ window title ] ;
}

- (void)setTitle:(NSString*)title 
{
	[ window setTitle:title ] ;
}

- (void)setDirty
{
	dirty = YES ;
}
 
- (Boolean)untitled
{
	return untitled ;
}

- (Boolean)viewAsFormulas
{
	return viewAsFormulas ;
}

- (void)setViewAsFormulas:(Boolean)state 
{
	viewAsFormulas = state ;
	[ table reloadData ] ;
}

- (NSArray*)transformStringsForTransform:(NSString*)name
{
	return [ transforms transformForName:name ] ;
}

//	v0.77m - perform progress in main thread
- (void)startAnimation
{
	[ progressIndicator startAnimation:self ] ;
}

//	v0.77m - perform progress in main thread
- (void)stopAnimation
{
	[ progressIndicator stopAnimation:self ] ;
}

//	v0.55b
- (void)setProgress:(Boolean)state
{
	if ( state == YES ) {
		//  v0.77
		[ self performSelectorOnMainThread:@selector(startAnimation) withObject:nil waitUntilDone:NO ] ;	//  v0.77m
		//[ progressIndicator startAnimation:self ] ;		
	}
	else {
		//  v0.77
		[ self performSelectorOnMainThread:@selector(stopAnimation) withObject:nil waitUntilDone:NO ] ;		//  v0.77m
		//[ progressIndicator stopAnimation:self ] ;
	}
}


@end
