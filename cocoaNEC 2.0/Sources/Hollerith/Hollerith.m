//
//  Hollerith.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/20/07.
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

#import "Hollerith.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "Bundle.h"
#import "ColumnScale.h"
#import "HollerithCard.h"
#import "SavePanelExtension.h"

@implementation Hollerith

- (id)initWithDocumentNumber:(int)number
{
	self = [ super init ] ;
	if ( self ) {
		documentNumber = number ;
        
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"Hollerith" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;

        outputControl = [ [ OutputControl alloc ] init ] ;
		[ outputControl setDefaultPattern:NO ] ;
		rows = 0 ;
		cards = [ [ NSMutableArray alloc ] init ] ;
		sourcePath = nil ;
		dirty = NO ;
	}
	return self ;
}

- (void)dealloc
{
	[ window setDelegate:nil ] ;
	[ outputControl release ] ;
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
	NSAttributedString *string = [ metricField attributedStringValue ] ;
	NSDictionary *attributes ;
	NSFont *font ;
	NSSize advance ;
	
	attributes = [ string attributesAtIndex:1 effectiveRange:nil ] ;
	font = [ attributes objectForKey:@"NSFont" ] ;
	if ( font ) {
		advance = [ font advancementForGlyph:'0' ] ;
		advanceWidth = advance.width + [ font leading ] ;
		[ scale setGrid:advanceWidth ] ;
	}	
	//  extract table info
	NSArray *column = [ table tableColumns ] ;

	indexColumn = [ column objectAtIndex:0 ] ;
	cardColumn = [ column objectAtIndex:1 ] ;
	ignoreColumn = [ column objectAtIndex:2 ] ;
	noteColumn = [ column objectAtIndex:3 ] ;
	
	[ editField setDelegate:self ] ;
	[ editField setEnabled:NO ] ;
	[ positionText setStringValue:@"" ] ;
	origin = [ positionText frame ] ;
		
	[ table setDelegate:self ] ;
	[ table setDataSource:self ] ;
	
	[ window setHidesOnDeactivate:NO ] ;
	[ window setLevel:NSNormalWindowLevel ] ;
	[ window setDelegate:self ] ;
}

- (void)setSourcePath:(NSString*)path
{
	if ( sourcePath != nil ) [ sourcePath autorelease ] ;
	sourcePath = [ [ NSString alloc ] initWithString:path ] ;
}

//  read line up to carriage return or linefeed
//  return length or -1 on EOF
//	v0.70 changed from getline to avoid Mac OS X 10.7 conflict.
static int hgetline( char *line, int maxline, FILE *deck ) 
{
	int i, ch=0, count ;
	char *original = line ;
	
	for ( i = 0; i < maxline; i++ ) {
		ch = fgetc( deck ) ;
		//if ( ch <= 0 ) return ( -1 ) ;				//  v0.41
		if ( ch <= 0 ) break ;
		ch &= 0x7f ;
		if ( ch == 012 || ch == 015 ) break ;
		*line++ = ch ;
	}
	*line = 0 ;	
	count = (int)( line-original ) ;
	if ( count == 0 && ch <= 0 ) return -1 ;		//  allow EOF without EOL v0.41
	
	return (int)( line - original ) ;
}

//  update the spreadsheet from a hollerith deck
- (void)updateFromFile:(FILE*)deck name:(NSString*)name
{
	int i, characterCount ;
	char line[201] ;
	HollerithCard *card ;
	
	[ window setTitle:name ] ;
	
	for ( i = 0; i < 2000; i++ ) {		//  sanity check -- limit to 2000 cards
		characterCount = hgetline( line, 200, deck ) ;
		if ( characterCount < 0 ) break ;
		if ( characterCount > 0 ) {
			card = [ [ HollerithCard alloc ] init ] ;
			[ card setImage:[ NSString stringWithUTF8String:line ] ] ;
			[ cards insertObject:card atIndex:rows ] ;
			rows++ ;
		}
	}
	//  refresh table when done
	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:0 ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:0 ] ;	
	dirty = NO ;
}

- (void)createPatternCard:(FILE*)f nth:(int)nth nph:(int)nph theta:(float)theta phi:(float)phi dth:(float)dth dph:(float)dph
{
	fprintf( f, "RP  0%5d%5d 1000%10.3f%10.3f%10.3f%10.3f%10.3f\n", nth, nph, theta, phi, dth, dph, 5000.0 ) ;
}

- (Boolean)writeDeckToPath:(NSString*)path 
{
	HollerithCard *card ;
	FILE *f ;
	float *azimuthArray, *elevationArray ;
	const char *cardImage ;
	int i, j, ge ;
    intType count ;
	Boolean sawFRCard, sawEXCard ;

	f = fopen( [ path UTF8String ], "w" ) ;
	if ( !f ) return NO ;
			
	azimuthArray = [ outputControl elevationAnglesForAzimuthPlot ] ;
	elevationArray = [ outputControl azimuthAnglesForElevationPlot ] ;

	sawFRCard = sawEXCard = NO ;
	count = [ cards count ] ;
	for ( i = 0; i < count; i++ ) {
		card = [ cards objectAtIndex:i ] ;
		cardImage = [ [ [ card imageField ] uppercaseString ] UTF8String ] ;
		if ( ![ card ignore ] ) {
			if ( cardImage[0] == 'G' && cardImage[1] == 'E' ) {
				//  convert GE card to NEC-2 format (nec2c crashes with NEC-4 format
				sscanf( cardImage+2, "%d", &ge ) ;
				fprintf( f, "GE %5d\n", ge ) ;						// v 0.41
			}
			else {
				if ( cardImage[0] == 'F' && cardImage[1] == 'R' ) sawFRCard = YES ;
				if ( cardImage[0] == 'E' && cardImage[1] == 'X' ) sawEXCard = YES ;
				fprintf( f, "%s\n", cardImage ) ;
				
				if ( sawFRCard && sawEXCard ) {
					// output RP cards only after both FR and EX cards are seen
					sawEXCard = NO ;
					//  insert any local RP after EX card
					for ( j = 0; j < 3; j++ ) {
						//  azimuth pattern
						if ( azimuthArray[j] < 1000 ) [ self createPatternCard:f nth:1 nph:360 theta:90-azimuthArray[j] phi:0 dth:0.0 dph:1.0 ] ;
					}
					for ( j = 0; j < 3; j++ ) {
						//  elevation pattern
						if ( elevationArray[j] < 1000 ) [ self createPatternCard:f nth:360 nph:1 theta:-90 phi:elevationArray[j] dth:1.0 dph:0.0 ] ;
					}
					if ( [ outputControl is3DSelected ] ) fprintf( f, "RP  0   91  120 1000     0.000     0.000     2.000     3.000 5.000E+03\n" ) ;	// v 0.41
				}
			}
		}
	}
	fclose( f ) ;
	return YES ;
}

- (NSString*)save:(Boolean)ask
{
	NSSavePanel *panel ;
	NSString *filePath, *directory ;
	NSInteger result ;
	
	if ( ask || sourcePath == nil ) {
		panel = [ NSSavePanel savePanel ] ;
		[ panel setTitle:@"Save NEC-2 Hollerith Deck" ] ;   
        //  v0.88  setRequiredFileType deprecated
        //[ panel setRequiredFileType:@"deck" ] ;
        [ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"deck" ] ] ;
		
		directory = ( sourcePath ) ? [ sourcePath stringByDeletingLastPathComponent ] : [ [ NSApp delegate ] defaultDirectory ] ;	
        result = [ SavePanelExtension runModalFor:panel directory:directory file:[ window title ] ] ;
		if ( result == NSModalResponseOK  && [ panel URL ] != nil ) {
			filePath = [ [ panel URL ] path ] ;
			[ self writeDeckToPath:filePath ] ;
			[ self setSourcePath:filePath ] ;
		}
	}
	else [ self writeDeckToPath:sourcePath ] ;
	
	return sourcePath ;
}

// this comes from the Hide and Show in the dock (and hide in the main menu)
- (void)hideWindow
{
	[ window orderOut:self ] ;
}

// this comes from the Hide and Show in the dock (and hide in the main menu)
- (void)showWindow
{
	[ window orderFront:self ] ;
}

- (void)becomeKeyWindow
{
	[ window makeKeyAndOrderFront:self ] ;
}

//  Delegate to window
- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
	[ [ NSApp delegate ] hollerithBecameKey:self ] ;
}

- (IBAction)runButtonPushed:(id)sender
{
	RunInfo *result ;
	NSString *inputPath, *outputPath ;
	
	inputPath = [ [ NSString stringWithFormat:@"/tmp/necinput%d.dat", documentNumber ] stringByExpandingTildeInPath ] ;
	outputPath = [ [ NSString stringWithFormat:@"/tmp/necoutput%d.txt", documentNumber ] stringByExpandingTildeInPath ] ;
	
	if ( inputPath ) {
	
		if ( [ self writeDeckToPath:inputPath ] ) {
			result = [ [ NSApp delegate ] runNECEngine:inputPath output:outputPath sourcePath:sourcePath useQuad:[ outputControl isQuadPrecision ] ] ;
			if ( result->errorCode == 0 ) {
				[ [ NSApp delegate ] displayNECOutput:sourcePath hollerith:inputPath lpt:outputPath source:sourcePath exceptions:[ NSArray array ] resetContext:YES result:result ] ; //  v0.81d
			}
            else {
                //  v0.88
                [ AlertExtension modalAlert:@"NEC-2 Error." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe NEC-2 engine returned an error.\n\nPossible errors are wire elements that touches z=0 or a geometry element that has been reflected upon itself.\n" ] ;
            }
		}
	}
}

- (IBAction)addHollerithCard:(id)sender
{
	intType n = [ table selectedRow ]+1 ;
	
	if ( n < 0 ) n = 0 ; 
	
	HollerithCard *card = [ [ HollerithCard alloc ] init ] ;
	[ cards insertObject:card atIndex:n ] ;
	rows++ ;

	[ table reloadData ] ;
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:n ] byExtendingSelection:NO ] ;
	[ table scrollRowToVisible:n ] ;	
	
	selectedRow = n ;	
	[ editField setEnabled:YES ] ;
	[ editField setStringValue:@"" ] ;
	[ [ editField window ] makeFirstResponder:editField ] ;
	dirty = YES ;
}

- (IBAction)removeHollerithCard:(id)sender
{
	intType row = [ table selectedRow ] ;
	
	if ( row < 0 ) return ;
	[ cards removeObjectAtIndex:row ] ;
	rows-- ;
	if ( rows < 0 ) rows = 0 ;
	[ table reloadData ] ;
	dirty = YES ;
}

//  return YES if dirty
- (Boolean)windowCanClose
{
	return YES ;
}

- (BOOL)windowShouldClose:(id)window
{
	if ( ![ self windowCanClose ] ) return NO ;
	[ [ NSApp delegate ] hollerithClosing:self ] ;
	return YES ;
}

- (IBAction)openOutputControl:(id)sender
{
	[ outputControl showSheet:window ] ;
}

//  NSDataSource methods
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView != table ) return 0 ;
	return rows ;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( row >= rows ) return @"" ;
	
	HollerithCard *card = [ cards objectAtIndex:row ] ;	
	if ( tableView == table ) {
		if ( tableColumn == indexColumn ) return [ NSString stringWithFormat:@"%d", row+1 ] ;
		if ( tableColumn == cardColumn ) return [ card imageField ] ;
		if ( tableColumn == ignoreColumn ) return [ card ignoreField ] ;
		if ( tableColumn == noteColumn ) return [ card noteField ] ;
	}
	return @"" ;
}

- (BOOL)tableView:(NSTableView*)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView != table || tableColumn == indexColumn ) return NO ;	

	selectedRow = row ;	
	HollerithCard *card = [ cards objectAtIndex:row ] ;
	
	if ( tableColumn == cardColumn ) {
		//  direct card field to the editField instead
		[ editField setEnabled:YES ] ;
		[ editField setStringValue:[ card imageField ] ] ;
		[ [ editField window ] makeFirstResponder:editField ] ;
		return NO ;
	}
	else if ( tableColumn == ignoreColumn ) {
		//  flip ignore flag
		[ card setIgnore:( [ card ignore ] ? @"" : @"*" ) ] ;
		[ table setNeedsDisplayInRect:[ table rectOfRow:row ] ] ;
		return NO ;
	}
	return YES;
}

//  accept edited name and comment from the tableview field cells
- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)row
{
	if ( tableView != table || row >= rows ) return ;

	HollerithCard *card = [ cards objectAtIndex:row ] ;	
	if ( tableColumn == noteColumn ) [ card setNote:object ] ;
	dirty = YES ;
}


//  accept end from editField
- (BOOL)control:(NSControl*)control textShouldEndEditing:(NSText*)fieldEditor
{
	if ( control == editField ) {
		HollerithCard *card = [ cards objectAtIndex:selectedRow ] ;
		//  transfer editField text to card image
		[ card setImage: [ editField stringValue ] ] ;
		dirty = YES ;
		[ table setNeedsDisplayInRect:[ table rectOfRow:selectedRow ] ] ;
		selectedRow = 0 ;
	}	
	[ editField setStringValue:@"" ] ;		//  clear editField
	[ editField setEnabled:NO ] ;
	[ positionText setStringValue:@"" ] ;
	return YES ;
}

- (void)selecting:(int)index
{
	NSString *newString = [ NSString stringWithFormat:@"%d", index+1 ] ;
	if ( [ newString isEqualTo:[ positionText stringValue ] ] ) return ;
	
	//  clear old vernier and replace with new one
	[ positionText setStringValue:@"   " ] ;
	[ positionText display ] ;
	NSRect pos = origin ;
	pos.origin.x += index*advanceWidth*( 72.0/80.0 ) ;
	[ positionText setFrame:pos ] ;
	[ positionText setStringValue:newString ] ;
}


@end
