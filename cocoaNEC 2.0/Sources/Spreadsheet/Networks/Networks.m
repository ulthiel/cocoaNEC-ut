//
//  Networks.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/13/07.
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

#import "Networks.h"
#import "Expression.h"
#import "Spreadsheet.h"
#import "TwoPort.h"

@implementation Networks

@synthesize window ;

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		networkArray = [ [ NSMutableArray alloc ] init ] ;
		controllingWindow = nil ;
	}
	return self ;
}

- (void)awakeFromNib
{
	NSArray *column = [ table tableColumns ] ;

	numberColumn = [ column objectAtIndex:0 ] ;
	fromColumn = [ column objectAtIndex:1 ] ;
	typeColumn = [ column objectAtIndex:2 ] ;
	toColumn = [ column objectAtIndex:3 ] ;
	commentColumn = [ column objectAtIndex:4 ] ;

	[ table setDelegate:self ] ;
	[ table setDataSource:self ] ;
	
	// make sheet opaque
	[ window setAlphaValue:1.0 ] ;
}

//  NSDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView != table ) return 0 ;
	return [ networkArray count ] ;
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

//  add button and contextual menu for add button comes here (tag selects type to add).
- (IBAction)addNetworkElement:(id)sender
{
	intType n = [ table selectedRow ]+1 ;
	
	if ( n < 0 ) n = [ networkArray count ] ;
	
	[ networkArray insertObject:[ [ TwoPort alloc ] initWithDelegate:self type:[ sender tag ] ] atIndex:n ] ;

	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:n ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:n ] ;
}

- (IBAction)removeNetworkElement:(id)sender
{
	intType row = [ table selectedRow ] ;
	if ( row < 0 ) return ;
	TwoPort *network = [ networkArray objectAtIndex:row ] ;	

	[ networkArray removeObjectAtIndex:row ] ;
	[ network release ] ;
	[ table reloadData ] ;
}

- (void)ncCode:(NSMutableString*)code eval:(Spreadsheet*)client
{
    int i ;
	intType networks ;
	TwoPort *twoport ;	
	
	networks = [ networkArray count ] ;
	
	for ( i = 0; i < networks; i++ ) {
		twoport = [ networkArray objectAtIndex:i ] ;
		[ twoport ncCode:code eval:client networkRow:i ] ;
	}
}

- (void)outputCards:(Spreadsheet*)client expression:(Expression*)e
{
    int i ;
    intType networks ;
	TwoPort *network ;	

	networks = [ networkArray count ] ;
	for ( i = 0; i < networks; i++ ) {
		network = [ networkArray objectAtIndex:i ] ;
		[ client outputCard:[ network networkCard:e spreadsheet:client networkRow:i ] ] ;
	}
}

//  delegate for networks table view
- (BOOL)tableView:(NSTableView*)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView != table || row >= [ networkArray count ] ) return NO ;
	
	TwoPort *network = [ networkArray objectAtIndex:row ] ;			
	
	if ( tableColumn == numberColumn ) {
		[ network openInspector:self ] ;
		return NO ;
	}
	if ( tableColumn == typeColumn ) return NO ;
	
	return YES ;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(intType)row
{
	if ( tableView == table ) {

		if ( tableColumn == numberColumn || row >= [ networkArray count ] ) return [ NSString stringWithFormat:@"%d", (int)( row+1 ) ] ;

		TwoPort *network = [ networkArray objectAtIndex:row ] ;		
		
		if ( tableColumn == fromColumn ) return [ network fromField ] ;
		if ( tableColumn == typeColumn ) return [ network typeField ] ;
		if ( tableColumn == toColumn ) return [ network toField ] ;
		if ( tableColumn == commentColumn ) return [ network commentField ] ;
	}
	return @"" ;
}

//  accept edited name and comment from the tableview field cells
- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(intType)row
{
	if ( tableView != table || row >= [ networkArray count ] ) return ;

	TwoPort *network = [ networkArray objectAtIndex:row ] ;			
	
	if ( tableColumn == fromColumn ) return [ network setFrom:object ] ;
	if ( tableColumn == toColumn ) return [ network setTo:object ] ;
	if ( tableColumn == commentColumn ) return [ network setComment:object ] ;
}

//  make plist for model
- (NSMutableArray*)makePlistArray
{
	NSMutableArray *plist ;
	TwoPort *network ;
	intType i, count ;
	
	count = [ networkArray count ];
	if ( count <= 0 ) return nil ;	
	
	plist = [ [ NSMutableArray alloc ] initWithCapacity:count ] ;
	
	for ( i = 0; i < count; i++ ) {
		network = [ networkArray objectAtIndex:i ] ;	
		[ plist addObject:[ network makePlistDictionary ] ] ;
	}
	return plist ;
}

//  update from plist (NSArray of NSDictionary)
- (void)restoreFromArray:(NSArray*)items
{
	intType i, count ;
	TwoPort *v ;
	NSDictionary *dict ;
	NSString *typeString ;
	
	if ( items == nil ) return ;
	count = [ items count ] ;

	for ( i = 0; i < count; i++ ) {
		dict = [ items objectAtIndex:i ] ;
		typeString = [ dict objectForKey:@"type" ] ;
		if ( typeString ) {
			if ( [ typeString isEqualToString:@"TL" ] ) {
				v = [ [ TwoPort alloc ] initFromDict:dict delegate:self type:TRANSMISSIONLINETYPE ] ;
				[ networkArray addObject:v ] ;
			}
			else if ( [ typeString isEqualToString:@"NT" ] ) {
				v = [ [ TwoPort alloc ] initFromDict:dict delegate:self type:NETWORKTYPE ] ;
				[ networkArray addObject:v ] ;
			}
		}
	}
	[ table reloadData ] ;
	[ table scrollRowToVisible:0 ] ;	
	[ table deselectAll:self ] ;
}


@end
