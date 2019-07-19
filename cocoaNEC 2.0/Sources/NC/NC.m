//
//  NC.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/15/07.
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

#import "NC.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "Bundle.h"
#import "NCNode.h"
#import "NCError.h"
#import "NCFunction.h"
#import "NCFunctionObject.h"
#import "SavePanelExtension.h"


//			NC
//				-run (NSButton)
//					NCCompiler -compile				-> produces intermediate "code"
//					- execute						-> executes intermediate code
//					- runNEC2						-> generates cards with NCDeck
//						AppDelegate - runNECEngine

@implementation NC

- (id)initWithDocumentNumber:(int)num untitled:(Boolean)isUntitled
{
	self = [ super init ] ;
	if ( self ) {
		documentNumber = num ;
		untitled = isUntitled ;
		dirty = NO ;
		sendCardToNEC = YES ;		// disable to output card deck only
        
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"NC" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;

        necResults.feedpointArray = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
    }
	return self ;
}

- (void)dealloc
{
	[ window setDelegate:nil ] ;
	[ necResults.feedpointArray release ] ;
    [ retainedNibObjects release ] ;
	[ super dealloc ] ;
}

//  v0.70
- (NSString*)windowPosition
{
	if ( window ) return [ window stringWithSavedFrame ] ;
	return nil ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)setTextFont
{
	[ textView setFont:[ NSFont fontWithName: @"Monaco" size: 10.0 ] ] ;
}

- (void)awakeFromNib
{
	NSRect frame ;
		
	frame = [ window frame ] ;
	frame.origin.x += 20*( documentNumber-1 ) ;
	frame.origin.y -= 22*( documentNumber-1 ) ;
	[ window setFrame:frame display:YES ] ;

	[ window setTitle:[ NSString stringWithFormat:@"Untitled NC Model-%d", documentNumber ] ] ;
	[ window setHidesOnDeactivate:NO ] ;
	[ window setLevel:NSNormalWindowLevel ] ;
	[ window setDelegate:self ] ;
	
	cardsView = cardsTable ;
	[ cardsView setDataSource:self ] ;
	hollerithCardColumn = [ [ cardsView tableColumns ] objectAtIndex:1 ] ;
	
	[ self setInterface:stopButton to:@selector(stop) ] ;
	[ stopButton setHidden:YES ] ;
	
	[ progressIndicator setUsesThreadedAnimation:YES ] ;
	
	[ self setTextFont ] ;
	[ textView setDelegate:self ] ;		//  for dirty check
}

//  update the textView
- (void)updateFromPath:(NSString*)path
{	
	NSString *text ;
	
	[ window setTitle:[ [ path stringByDeletingPathExtension ] lastPathComponent ] ] ;
	text = [ NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil ] ;
	if ( text ) {
		[ self setTextFont ] ;
		[ textView setString:text ] ;
		dirty = NO ;
	}
}

//  get a path to save
- (NSString*)save:(Boolean)ask
{
	NSSavePanel *panel ;
	NSString *filePath, *directory ;
	NSInteger resultCode ;
	
	filePath = nil ;
	
	if ( ask || stack.sourcePath == nil ) {
		panel = [ NSSavePanel savePanel ] ;
		[ panel setTitle:@"Save NC model" ] ;
        //  v0.88  setRequiredFileType deprecated
		//[ panel setRequiredFileType:@"nc" ] ;
        [ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"nc" ] ] ;
        
        
		directory = ( stack.sourcePath ) ? [ stack.sourcePath stringByDeletingLastPathComponent ] : [ (ApplicationDelegate*)[ NSApp delegate ] defaultDirectory ] ;
        
        resultCode = [ SavePanelExtension runModalFor:panel directory:directory file:[ window title ] ] ;
        
        if ( resultCode == NSModalResponseOK  && [ panel URL ] != nil ) {
			filePath = [ [ panel URL ] path ] ;
		}
	}
	else {
		filePath = stack.sourcePath ;
	}
	if ( filePath != nil ) {
		[ [ textView string ] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil ] ;
		[ window setTitle:[ [ filePath lastPathComponent ] stringByDeletingPathExtension ] ] ;
		[ (ApplicationDelegate*)[ NSApp delegate ] setDefaultDirectory:[ filePath stringByDeletingLastPathComponent ] ] ;
		[ self setSourcePath:filePath ] ;
		untitled = NO ;
		dirty = NO ;
	}
	return filePath ;
}

- (NSString*)title
{
	return [ window title ] ;
}

 - (void)setTitle:(NSString*)title 
 {
	[ window setTitle:title ] ;
 }

- (void)becomeKeyWindow
{
	[ window makeKeyAndOrderFront:self ] ;
}

- (void)setWindowPosition:(NSString*)pos
{
	if ( pos != nil ) [ window setFrameFromString:pos ] ;
}

- (void)appendToOutputViewInMainThread:(NSString*)str
{
	[ self appendText:str toView:outputView ] ;
}

- (void)appendToOutputView:(NSString*)str
{
	[ self performSelectorOnMainThread:@selector(appendToOutputViewInMainThread:) withObject:str waitUntilDone:YES ] ;
}

- (NECInfo*)necResults
{
	return &necResults ;
}


//  v0.92 fix thread safe crashes
- (void)runInSeparateThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
    
	[ runLock lock ] ;
    
    dispatch_sync( dispatch_get_main_queue(), ^{ self->sourceString = [ textView string ] ; } ) ;        

    [ self runWorkFlowCompile:YES execute:YES allowLoops:YES runNEC:YES sourceString:sourceString ] ;
    
    dispatch_sync( dispatch_get_main_queue(), ^{ 
        [ self->window makeKeyAndOrderFront:self ] ;
        [ self->runButton setEnabled:YES ] ;
    } ) ;       
    
	[ runLock unlockWithCondition:kThreadFree ] ;
	
	[ pool release ] ;
	[ NSThread exit ] ;
}

//  called from Execute button or Main menu (through ApplicationDelegate)
- (IBAction)run:(id)sender
{
	if ( [ runLock tryLockWhenCondition:kThreadFree ] ) {
		[ runButton setEnabled:NO ] ;
		[ runLock unlock ] ;
		[ NSThread detachNewThreadSelector:@selector(runInSeparateThread:) toTarget:self withObject:self ] ;
	}
	else {
        //  v0.88
		[ AlertExtension modalAlert:@"NC is already busy." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe previous run has not yet finished.\n" ] ;
        
        return ;		//  disable Command G also
	}
}

- (void)stop
{
	NCSystem *system ;
	
	if ( compiler ) {
		system = [ compiler system ] ;
		if ( system ) [ system setAbort ] ;
	}
}

- (void)makeListingViewVisible
{
	[ ncTab selectTabViewItemAtIndex:2 ] ;
}

- (NSTextView*)listingView
{
	return listView ;
}

//	v0.55 -- client of outputListing supplies this as input string
- (NSString*)listingInput
{
	return [ textView string ] ;
}

//  Delegate to window
- (void)windowDidBecomeKey:(NSNotification*)aNotification
{
	[ (ApplicationDelegate*)[ NSApp delegate ] ncBecameKey:self ] ;
}

//  return YES if not dirty
- (Boolean)windowCanClose
{
	NSInteger result ;
	const char *name ;
	
	//  make the window key before asking
	[ window makeKeyAndOrderFront:self ] ;
	if ( dirty ) {
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
	
	[ (ApplicationDelegate*)[ NSApp delegate ] ncClosing:self ] ;
	return YES ;
}

//	v0.77m	perform on main thread
- (void)showStop
{
	[ stopButton setHidden:NO ] ;
	[ stopButton display ] ;
}

//	v0.77m	perform on main thread
- (void)hideStop
{
	[ stopButton setHidden:YES ] ;
}

- (void)displayStop:(Boolean)state
{
	if ( state == YES ) {
		[ self performSelectorOnMainThread:@selector(showStop) withObject:nil waitUntilDone:YES ] ;	//  v0.77m
	}
	else {
		[ self performSelectorOnMainThread:@selector(hideStop) withObject:nil waitUntilDone:YES ] ;	//  v0.77m
	}
}

- (void)saveToHollerith
{
	NSSavePanel *panel ;
	NSString *filePath, *directory ;
	NSInteger resultCode ;
	
	panel = [ NSSavePanel savePanel ] ;
	[ panel setTitle:@"Save NEC-2 Hollerith Deck" ] ;
    [ panel setAllowedFileTypes:[ NSArray arrayWithObject:@"deck" ] ] ;
	
	directory = [ (ApplicationDelegate*)[ NSApp delegate ] defaultDirectory ] ;
    
    resultCode = [ SavePanelExtension runModalFor:panel directory:directory file:[ window title ] ] ;
    
	if ( resultCode == NSModalResponseOK  && [ panel URL ] != nil ) {
		filePath = [ [ panel URL ] path ] ;
		if ( [ self runWorkFlowCompile:YES execute:YES allowLoops:NO runNEC:NO sourceString:[ textView string ] ] == 0 ) {	//  v0.65
			[ self outputHollerithToFile:filePath ] ;
		}
	}
}

- (int)documentNumber
{
	return documentNumber ;
}

- (Boolean)untitled
{
	return untitled ;
}

//	v0.77 - perform progress in main thread
- (void)startAnimation
{
	[ progressIndicator startAnimation:self ] ;
}

//	v0.77 - perform progress in main thread
- (void)stopAnimation
{
	[ progressIndicator stopAnimation:self ] ;
}

- (void)setProgress:(Boolean)state
{
	if ( state == YES ) {
		//  v0.77
		[ self performSelectorOnMainThread:@selector(startAnimation) withObject:nil waitUntilDone:NO ] ;
		//[ progressIndicator startAnimation:self ] ;
	}
	else {
		//  v0.77
		[ self performSelectorOnMainThread:@selector(stopAnimation) withObject:nil waitUntilDone:NO ] ;
		//[ progressIndicator stopAnimation:self ] ;
	}
}

//  delegate of textView to check dirty state
//  v0.45
- (BOOL)textView:(NSTextView*)view shouldChangeTextInRange:(NSRange)charRange replacementString:(NSString*)str
{
	NSString *string ;
	intType i, j, length, location, check, tabcheck, tabcount ;
	char tabs[128] ;
	
	if ( view == textView ) {
		if ( str != nil && [ str length ] > 0 ) {
			check = [ str characterAtIndex:0 ] ;
			if (  check == '\n' || check == '\r' ) {
				string = [ view string ] ;
				length = [ string length ] ;
				if ( length > 256 ) length = 256 ;		//  limit check span to 256 characters
				location = ( charRange.location - 1 ) ;
				check = 0 ;
				for ( i = 1 ; i < length; i++ ) {
					j = location-i ;
					if ( j < 0 ) break ;
					check = [ string characterAtIndex:j ] ;
					if ( check == '\n' || check == '\r' ) break ;
				}
				if ( check == '\n' || check == '\r' ) {
					tabcount = 0 ;
					for ( j = 1; j <= i; j++ ) {
						tabcheck = [ string characterAtIndex:location-i+j ] ;
						if ( tabcheck == ' ' || tabcheck == '\t' ) {
							tabs[ tabcount++ ] = tabcheck ;
						}
						else break ;
					}
					if ( tabcount > 0 ) {
						//  add spaces and tabs to new line
						tabs[ tabcount++ ] = 0 ;
                        //  v0.88   -insertText deprecated in 10.11
						//  [ view insertText:[ NSString stringWithCString:tabs encoding:NSASCIIStringEncoding ] ] ;
                        
                        [ view insertText:[ NSString stringWithCString:tabs encoding:NSASCIIStringEncoding ] replacementRange:charRange ] ;
					}
				}
			}
		}
		dirty = YES ;
	}
	return YES ;
}


@end
