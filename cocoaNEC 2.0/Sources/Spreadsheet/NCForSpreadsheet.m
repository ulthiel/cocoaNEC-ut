//
//  NCForSpreadsheet.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/16/09.
//	-----------------------------------------------------------------------------
//  Copyright 2009-2016 Kok Chen, W7AY. 
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

#import "NCForSpreadsheet.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"

@implementation NCForSpreadsheet

- (id)initWithListView:(NSTextView*)view cardView:(NSTableView*)cards
{
	self = [ super init ] ;
	if ( self ) {
		listView = view ;
		cardsView = cards ;
		[ cardsView setDataSource:self ] ;
		hollerithCardColumn = [ [ cardsView tableColumns ] objectAtIndex:1 ] ;
 	}
	return self ;
}

- (void)outputListing:(NC*)client
{
	//  also update cards tableView
	[ cardsView noteNumberOfRowsChanged ] ;	
	[ super outputListing:client ] ;
}

//	(Private API)
- (void)runInSeparateThread:(id)sender
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;

	[ runLock lock ] ;
	runStatus = [ self runWorkFlowCompile:YES execute:YES allowLoops:NO runNEC:YES sourceString:sourceString ] ;
	[ sourceString release ] ;
	[ runLock unlockWithCondition:kThreadFree ] ;
	[ pool release ] ;
	[ NSThread exit ] ;
}

-(void)runSource:(NSString*)source
{
	if ( source == nil ) return ;

	if ( [ runLock tryLockWhenCondition:kThreadFree ] ) {
		[ runLock unlock ] ;
		sourceString = [ source retain ] ;
		[ NSThread detachNewThreadSelector:@selector(runInSeparateThread:) toTarget:self withObject:self ] ;
		return ;
	}
	else {
		[ AlertExtension modalAlert:@"NC engine is already busy processing a spreadsheet model." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe previous run has not yet finished.\n" ] ;
		return ;		//  disable Command G also
	}
}

-(void)createDeck:(NSString*)source
{
	if ( source == nil ) return ;

	if ( [ runLock tryLockWhenCondition:kThreadFree ] ) {
		sourceString = [ source retain ] ;
		runStatus = [ self runWorkFlowCompile:YES execute:YES allowLoops:NO runNEC:NO sourceString:sourceString ] ;
		[ sourceString release ] ;
		[ runLock unlockWithCondition:kThreadFree ] ;
		return ;
	}
	else {
		[ AlertExtension modalAlert:@"NC engine is already busy processing a spreadsheet model." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe previous run has not yet finished.\n" ] ;
		return ;		//  disable Command G also
	}
}

- (NSTextView*)listingView
{
	return listView ;
}

//	v0.55 -- client of outputListing supplies this as input string
- (NSString*)listingInput
{
	return sourceString ;
}

//	v0.55b
- (void)setProgress:(Boolean)state
{
	[ [ [ NSApp delegate ] currentSpreadsheet ] setProgress:state ] ;
}

@end
