//
//  Variables.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/4/07.
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


#import "Variables.h"
#import "AlertExtension.h"
#import "VariableObject.h"
#import "Primary.h"


static Boolean alpha( int a ) ;
static Boolean numer( int a ) ;


@implementation Variables

//  This class is the data source of the Variables tableview

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		rows = 0 ;
		dictionary = [ [ NSMutableDictionary alloc ] initWithCapacity:16 ] ;
		variableArray = [ [ NSMutableArray alloc ] init ] ;
		plist = nil ;
		nameColumn = valueColumn = commentColumn = nil ;
		delegate = nil ;
		controllingWindow = nil ;
	}
	return self ;
}

- (void)setDelegate:(id)client
{
	delegate = client ;
}

- (void)deselectAll
{
	[ table deselectAll ] ;
}

- (void)awakeFromNib
{
	NSArray *column = [ table tableColumns ] ;

	nameColumn = [ column objectAtIndex:0 ] ;
	valueColumn = [ column objectAtIndex:1 ] ;
	commentColumn = [ column objectAtIndex:2 ] ;

	[ table setDelegate:self ] ;
	[ table setDataSource:self ] ;
	
	// make sheet opaque
	[ window setAlphaValue:1.0 ] ;
}

//	(Private API)
- (void)setDirty
{
	if ( delegate != nil ) [ delegate setDirty ] ;
}

- (NSMutableDictionary*)dictionary
{
	return dictionary ;
}

- (NSArray*)variableList
{
	return variableArray ;
}

- (void)showSheet:(NSWindow*)mainWindow
{
	controllingWindow = mainWindow ;
    
    //  v0.88 beginSheet deprecated in 10.10
	//[ NSApp beginSheet:window modalForWindow:controllingWindow modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;
    
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

- (IBAction)addVariable:(id)sender
{
	intType n = [ table selectedRow ]+1 ;
	
	if ( n < 0 ) n = 0 ; 
	
	[ variableArray insertObject:[ [ VariableObject alloc ] init ] atIndex:n ] ;
	rows++ ;

	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:n ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:n ] ;	
	[ table editColumn:0 row:n withEvent:nil select:YES ] ;
	[ self setDirty ] ;
}

- (void)removeRow:(intType)row
{
	NSString *str ;
	VariableObject *v ;
	
	v = [ variableArray objectAtIndex:row ] ;
	
	str = [ v name ] ;
	if ( [ str length ] > 0 ) [ dictionary removeObjectForKey:str ] ; 
	
	[ variableArray removeObjectAtIndex:row ] ;
	[ v release ] ;
	rows-- ;
	if ( rows < 0 ) rows = 0 ;
	[ table reloadData ] ;
	[ self setDirty ] ;
}

- (IBAction)removeVariable:(id)sender
{
	intType row = [ table selectedRow ] ;
	if ( row < 0 ) return ;

	[ self removeRow:row ] ;
}

//  NSDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView != table ) return 0 ;
	return rows ;
}

//  some name or value changed
- (void)variableChanged:(id)sender
{
	if ( delegate && [ delegate respondsToSelector:@selector(variableChanged:) ] ) [ delegate variableChanged:sender ] ;
	[ self setDirty ] ;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView == table ) {
		VariableObject *var = [ variableArray objectAtIndex:row ] ;	
		
		if ( tableColumn == nameColumn ) return [ var name ] ;
		if ( tableColumn == valueColumn ) return [ var value ] ;
		if ( tableColumn == commentColumn ) return [ var comment ] ;
	}
	return @"" ;
}

- (Boolean)validateName:(NSString*)str
{
    intType i, len ;
    int c ;
	
	len = [ str length ] ;
	
	if ( len > 0 ) {
		if ( alpha( [ str characterAtIndex:0 ] ) ) {
			for ( i = 0; i < len; i++ ) {
				c = [ str characterAtIndex:i ] ;
				if ( !alpha( c ) && !numer( c ) ) break ;
			}
			if ( i >= len ) return YES ;
		}
	}
    
    //  v0.88
	[ AlertExtension modalAlert:@"Bad variable name." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nVariable names should start with an alphabet or the underscore character, and contain only alphabets, numbers or underscore characters.\n" ] ;
   
    return NO ;
}

- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	NSArray *column ;
	NSString *oldName, *newName ;
	VariableObject *v ;
	int i ;
	
	if ( tableView != table ) return ;
	
	column = [ table tableColumns ] ;
	v = [ variableArray objectAtIndex:row ] ;
	
	if ( tableColumn == [ column objectAtIndex:0 ] ) {
		if ( ![ self validateName:object ] ) {
			if ( [ v empty ] ) [ self removeRow:row ] ;
			return ;
		}
		oldName = [ v name ] ;
		newName = object ;
		//  create another dictionary object with the same name and assign the old value
		if ( [ oldName isEqualToString:newName ] ) {
			//  did not change
			return ;
		}
		if ( [ dictionary objectForKey:newName ] != nil ) {
			for ( i = 0; i < rows; i++ ) {
                
				if ( [ newName isEqualToString:[ [ variableArray objectAtIndex:i ] name ] ] ) {
                    
                    NSString *info = [ NSString stringWithFormat:@"\nThe variable %s is already defined in row %d of the variables table.\n", [ newName UTF8String ], i+1 ] ;

                    [ AlertExtension modalAlert:@"Variable name already in use." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
                    
                    if ( [ v empty ] ) [ self removeRow:row ] ;
					return ;
				}
			}
            [ AlertExtension modalAlert:@"Oops!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nInternal error with variable table.  Please save the file, quit and relaunch cocoaNEC.\n" ] ;
 
            if ( [ v empty ] ) [ self removeRow:row ] ;
			return ;
		}
		//  if previous name is different and not empty, first remove from dictionary
		if ( [ oldName length ] > 0 ) [ dictionary removeObjectForKey:oldName ] ;
		//  add new name to dictionary with old Primary value
		[ dictionary setObject:[ v primaryValue ] forKey:newName ] ;
		[ v setName:newName ] ;
		[ self variableChanged:self ] ;
		return ;
	}
	if ( tableColumn == [ column objectAtIndex:1 ] ) {
		[ v setValue:object ] ;
		oldName = [ v name ] ;
		if ( [ oldName length ] > 0 ) [ dictionary setObject:[ v primaryValue ] forKey:oldName ] ;
		[ self variableChanged:self ] ;
		return ;
	}
	//  comment field
	[ v setComment:object ] ;
}
 
//  reselect a row in case a table cell has not yet been registered
//  this should be called everytime just before the variables dictionary is used
- (void)validate
{
	intType row = [ table selectedRow ] ;
	
	if ( row >= 0 ) {
		[ table deselectAll:self ] ;
		[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:row ] byExtendingSelection:NO ] ;
	}
}

- (NSMutableArray*)makePlist 
{
	NSMutableDictionary *item ;
	intType n, i ;
	
	plist = [ [ NSMutableArray alloc ] init ] ;
	n = [ variableArray count ] ;
	for ( i = 0; i < n; i++ ) {
		item = [ [ variableArray objectAtIndex:i ] makeVariable ] ;
		if ( item != nil ) [ plist addObject:item ] ;
	}
	return plist ;
}

- (void)releasePlist
{
	intType i, n ;
	VariableObject *v ;
	
	if ( plist ) {
		[ plist removeAllObjects ] ;
		[ plist release ] ;
		plist = nil ;
		n = [ variableArray count ] ;
		//  release all descendants of plist array
		for ( i = 0; i < n; i++ ) {
			v = [ variableArray objectAtIndex:i ] ;
			if ( v != nil ) [ v releaseVariable ] ;
		}
	}
}

//  update from plist (NSArray of NSDictionary)
- (void)restoreFromArray:(NSArray*)items
{
	intType i, count = [ items count ] ;
	VariableObject *v ;
	NSDictionary *dict ;

	for ( i = 0; i < count; i++ ) {
		dict = [ items objectAtIndex:i ] ;
		v = [ [ VariableObject alloc ] init ] ;
		[ variableArray insertObject:v atIndex:rows ] ;
		[ v restoreVariable:dict ] ;
		// now save into variable dictionry
		[ dictionary setObject:[ v primaryValue ] forKey:[ v name ] ] ;
		rows++ ;
	}
	[ table reloadData ] ;
	[ table scrollRowToVisible:0 ] ;	
	[ table deselectAll:self ] ;
}

static Boolean alpha( int a )
{
	if ( a >= 'a' && a <= 'z' ) return true ;
	if ( a >= 'A' && a <= 'Z' ) return true ;
	return ( a == '_' ) ;
}

static Boolean numer( int a )
{
	return ( a >= '0' && a <= '9' ) ;
}

@end
