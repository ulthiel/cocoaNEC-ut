//
//  NCBase.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/15/09.
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

#import "NCBase.h"
#import "AlertExtension.h"
#import "NCError.h"
#import "ApplicationDelegate.h"
#import "NCFunctionObject.h"

@implementation NCBase

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		compiler = nil ;
		stack.sourcePath = nil ;
		stack.system = nil ;
		documentNumber = 101 ;
		//  create arrays to collect card deck information
		hollerithArray = [ [ NSMutableArray alloc ] initWithCapacity:60 ] ;
		stack.commentDeck = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
		stack.geometryElements = [ [ NSMutableArray alloc ] initWithCapacity:32 ] ;
		stack.controlDeck = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
		stack.exceptions = [ [ NSMutableArray alloc ] initWithCapacity:32 ] ;	//  exceptions such as current sources and radials
		stack.errors = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
		stack.coaxLines = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
		runLock = [ [ NSConditionLock alloc ] initWithCondition:kThreadFree ] ;
		nec2ThreadLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

//  v0.64
- (void)releaseCompiler
{
	if ( compiler ) [ compiler release ] ;
	compiler = nil ;
	[ stack.commentDeck removeAllObjects ] ;
	[ stack.geometryElements removeAllObjects ] ;
	[ stack.controlDeck removeAllObjects ] ;
	[ stack.exceptions removeAllObjects ] ; 
	[ stack.errors removeAllObjects ] ;
	[ stack.coaxLines removeAllObjects ] ;		//  v0.77
}

- (void)dealloc
{
	if ( stack.sourcePath ) [ stack.sourcePath release ] ;
	[ hollerithArray release ] ;
	[ self releaseCompiler ] ;
	[ stack.commentDeck release ] ;
	[ stack.geometryElements release ] ;
	[ stack.controlDeck release ] ;
	[ stack.exceptions release ] ;
	[ stack.errors release ] ;
	[ stack.coaxLines release ] ;
	[ runLock release ] ;
	[ nec2ThreadLock release ] ;
	[ super dealloc ] ;
}

- (void)appendText:(NSString*)string toView:(NSTextView*)view
{
	NSRange end = NSMakeRange( [ [ view string ] length ], 0 ) ;
	
	[ view replaceCharactersInRange:end withString:string ] ;
	end.location += [ string length ] ;
	[ view scrollRangeToVisible:end ] ;
	//[ view display ] ;
}

//	v0.55  -- client of outputListing supplies this as output textview
- (NSTextView*)listingView
{
	return nil ;
}

//	v0.55 -- client of outputListing supplies this as input string
- (NSString*)listingInput
{
	return @"" ;
}

- (void)makeListingViewVisible
{
}

- (void)outputListing:(NC*)client
{
	int i, j, t=0, line, parseErrorIndex, parseErrorLine, firstErrorPosition ;
    intType errorCount, lineLocation[MAXLINES] ;
	const char *input ;
	char buf[182], buf8[182], *c ;					// 0.74
	NSFont *font = [ NSFont fontWithName: @"Monaco" size: 10.0 ] ;
	NSArray *parseErrors ;
	NCError *parseError ;
	NSTextView *listingView ;
	NSString *listingInput ;
	
	listingView = [ client listingView ] ;
	listingInput = [ client listingInput ] ;
	
	[ listingView setFont:font ] ;
	[ listingView setString:@"" ] ;

	firstErrorPosition = 0 ;
	parseErrorIndex = 0 ;
	parseErrors = [ compiler parseErrors ] ;
	errorCount = [ parseErrors count ] ;
	
	if ( errorCount == 0 ) {
		parseError = nil ;
		parseErrorLine = MAXLINES+2 ;
	}
	else {
		parseError = [ parseErrors objectAtIndex:0 ] ;
		parseErrorLine = [ parseError line ] ;
		if ( errorCount > 1 ) {
			[ self appendText:[ NSString stringWithFormat:@"\n --------  %ld errors found. -----------\n\n", errorCount ] toView:listingView ] ;
		}
		else {
			[ self appendText:[ NSString stringWithFormat:@"\n --------  1 error found.  -----------\n\n" ] toView:listingView ] ;
		}
		[ self makeListingViewVisible ] ;
	}
	
	//  read input a line at a time.  For sanity check, limit to 4000 lines.
	input = [ listingInput UTF8String ] ;	
	line = 1 ;
	lineLocation[0] = 0 ;
	
	for ( i = 0; i < MAXLINES; i++ ) {
	
		//  mark location so we can scroll to an error later
		lineLocation[line] =  [ [ listingView string ] length ] ;
	
		//  fetch a line
		for ( j = 0; j < 180; j++ ) {
			t = *input ;
			if ( t == '\t' ) {
				do {
					buf[j] = ' ' ;
					j++ ;
				} while ( ( j & 0x3 ) != 0 ) ;
				j-- ;
			}
			else {
				buf[j] = t ;
				if ( t == 0 ) break ;
			}
			input++ ;
			if ( t == '\n' || t == '\r' ) break ;
		}

		buf[j+1] = 0 ;
		if ( t == 0 && j == 0 ) break ;
		
		// v0.74 remove Unicode 0xc2 (first byte of micro) from line
		c = buf8 ;
		for ( j = 0; j < 180; j++ ) {
			t = buf[j] & 0xff ;
			if ( t == 0xc2 || t == 0xc3 ) continue ;
			*c++ = t ;
			if ( t == 0 ) break ;
		}
		[ self appendText:[ NSString stringWithFormat:@" %04d  %s", line, buf8 ]  toView:listingView ] ;
			
		//  insert error message after the proper line number
		if ( parseError != nil && line == parseErrorLine ) {	
			if ( firstErrorPosition == 0 ) firstErrorPosition = line ;
			
			[ self appendText:[ NSString stringWithFormat:@"\n >>>>  %s\n", [ [ parseError string ] UTF8String ] ] toView:listingView ] ;

			while ( parseErrorLine == line ) {			
				parseErrorIndex++ ;
				if ( parseErrorIndex >= errorCount ) {
					parseError = nil ;
					parseErrorLine = MAXLINES+2 ;
				}
				else {				
					parseError = [ parseErrors objectAtIndex:parseErrorIndex ] ;
					parseErrorLine = [ parseError line ] ;
					if ( parseErrorLine == line ) [ self appendText:[ NSString stringWithFormat:@" >>>>  %s\n", [ [ parseError string ] UTF8String ] ] toView:listingView ] ;
				}
			}
			[ self appendText:@"\n" toView:listingView ] ;
		}
		line++ ;
	}
	//  scroll to first error location (or to the top, if there are no errors)
	int low = firstErrorPosition-6 ;
	int high = firstErrorPosition+6 ;
	if ( low < 0 ) low = 0 ;
	if ( high >= line ) high = line-1 ;
	
	NSRange top = NSMakeRange( lineLocation[low], lineLocation[high] ) ;
	[ listingView scrollRangeToVisible:top ] ;
}

- (NCSystem*)system 
{
	return [ compiler system ] ;
}

- (NCCompiler*)compiler
{
	return compiler ;
}

//		use this to set the runningstate (e.g.,for a progress bar)
- (void)setProgress:(Boolean)state
{
}

//	v0.55
- (Boolean)outputHollerithToFile:(NSString*)filePath
{
	intType i, count ;
	NSMutableString *cards ;
	
	count = [ hollerithArray count ] ;
	if ( count == 0 ) {
        
        //  v0.88
        [ AlertExtension modalAlert:@"Hollerith card deck not created." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nError found in the interpreter, Card deck is not created.\n" ] ;
 
		return NO ;
	}
	cards = [ [ NSMutableString alloc ] initWithCapacity:8000 ] ;
	for ( i = 0; i < count; i++ ) {
		[ cards appendString:[ hollerithArray objectAtIndex:i ] ] ;
		[ cards appendString:@"\n" ] ;
	}
	[ cards writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil ] ;
	[ cards release ] ;
	return YES ;
}

- (void)copyDeck:(NSArray*)deckArray
{
	int i ;
	
	//  clear cards
	[ hollerithArray removeAllObjects ] ;
	//  copy card images
	for ( i = 0; i < [ deckArray count ]; i++ ) {
		[ hollerithArray addObject:[ NSString stringWithString:[ deckArray objectAtIndex:i ] ] ] ;
	}
}

- (void)dispatchEngine
{
	runResult = *[ [ NSApp delegate ] runNECEngine:inputPath output:outputPath sourcePath:stack.sourcePath useQuad:[ [ compiler system ] useQuadPrecision ] ] ;
	
	if ( runResult.errorCode == 0 ) {
		//  since output processing involves NSViews, do it in the main thread
		[ self performSelectorOnMainThread:@selector(processNEC2Output) withObject:nil waitUntilDone:YES ] ;
		//  copy NEC-2 results to local structure 
		necResults.directivity = runResult.directivity ;
		necResults.maxGain = runResult.maxGain ;
		necResults.averageGain = runResult.averageGain ;		//  v0.62
		necResults.efficiency = runResult.efficiency ;
		necResults.azimuthAngleAtMaxGain = runResult.azimuthAngleAtMaxGain ;
		necResults.elevationAngleAtMaxGain = runResult.elevationAngleAtMaxGain ;
		necResults.frontToBackRatio = runResult.frontToBackRatio ;
		necResults.frontToRearRatio = runResult.frontToRearRatio ;
		
		[ necResults.feedpointArray setArray:runResult.feedpointArray ] ;
	}
	else {
		//  dispatchEngine is not in main thread -- dispatch alert to main thread
		if ( runResult.errorCode != kEngineNotFound ) [ self performSelectorOnMainThread:@selector(NEC2ErrorAlert) withObject:nil waitUntilDone:YES ] ;
	}
}

- (void)setModelFunction:(NCFunctionObject*)model
{
	NCSystem *system = [ compiler system ] ;
	[ system setModelName:[ [ model function ] modelName ] ] ;
}

- (NECRadials*)necRadials
{
	return &necRadials ;
}

- (void)setSourcePath:(NSString*)path
{
	if ( stack.sourcePath != nil ) [ stack.sourcePath autorelease ] ;
	stack.sourcePath = [ [ NSString alloc ] initWithString:path ] ;
}

//	(Private API)
- (void)reportRuntimeErrors
{
	intType errCount ;

	errCount = [ stack.errors count ] ;
	if ( errCount > 0 ) {
        //  v0.88
		[ AlertExtension modalAlert:@"Runtime Error." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:[ stack.errors objectAtIndex:errCount-1 ] ] ;
	}
}

- (void)processNEC2Output
{
	Boolean resetAllContexts ;
    
	resetAllContexts = ( runModelCount < 1 ) || ( [ stack.system keepDataBetweenModelRuns ] == NO ) ;
	[ [ NSApp delegate ] displayNECOutput:stack.sourcePath hollerith:inputPath lpt:outputPath source:stack.sourcePath exceptions:stack.exceptions resetContext:resetAllContexts result:&runResult ] ;
}

- (Boolean)dispatchNEC2
{
	intType errCount ;
	NCSymbolTable *symbolTable ;
	NCDeck *necInputDeck ;
	Boolean canSendToNEC ;

	//  check if there are NC runtime errors (each error is an NSString)
	errCount = [ stack.errors count ] ;
	
	if ( errCount == 0 ) {	
		symbolTable = [ compiler symbolTable ] ;
		//  initialize results
		necResults.directivity = necResults.maxGain = necResults.azimuthAngleAtMaxGain = necResults.elevationAngleAtMaxGain = 0.0 ;
		necResults.frontToBackRatio = necResults.frontToBackRatio = 0.0 ;
		[ necResults.feedpointArray removeAllObjects ] ;
		
		inputPath = [ [ NSString stringWithFormat:@"/tmp/necinput%d.dat", documentNumber ] stringByExpandingTildeInPath ] ;
		outputPath = [ [ NSString stringWithFormat:@"/tmp/necoutput%d.txt", documentNumber ] stringByExpandingTildeInPath ] ;
		
		//  create the deck and place into inputPath
		necInputDeck = [ [ NCDeck alloc ] initForPath:inputPath ] ;
		stack.system = [ compiler system ] ;
		canSendToNEC = [ necInputDeck generateDeck:&stack ] ;
		[ self copyDeck:[ necInputDeck hollerithArray ] ] ;
		[ necInputDeck release ] ;
		if ( sendCardToNEC && canSendToNEC ) {
			[ self dispatchEngine ] ;	
			return ( runResult.errorCode == 0 ) ;
		}
		return YES ;
	}
	[ self reportRuntimeErrors ] ;
	return NO ;
}

//  called from control block function runModel() or from -execute
- (Boolean)runModel
{
	NCSystem *system ;
	NCFunctionObject *model ;
	
	model = (NCFunctionObject*)[ [ compiler symbolTable ] containsIdent:@"model" ] ;
	if ( model == nil || [ model isFunction ] == NO ) {
		printf( "did not find model function?\n" ) ;
		return NO ;
	}
	system = [ compiler system ] ;	
	[ self performSelectorOnMainThread:@selector(setModelFunction:) withObject:model waitUntilDone:YES ] ;
	
	//  remove geometry objects in case we run from the control block (otherwise it will accumulate)
	[ stack.geometryElements removeAllObjects ] ;
	
	necRadials.useNECRadials = NO ;
	stack.system = system ;
	[ system clearAbort ] ;
	[ system clearRadialsAndPlots ] ;		//  0.46 -- control() was accumulating them!
	[ model runBlock:&stack ] ;
	
	//  run NEC2 in separate thread
	[ self dispatchNEC2 ] ;

	runModelCount++ ;
	return YES ;
}

//  called from user interface (-execute)
- (Boolean)execute:(Boolean)runNEC allowLoops:(Boolean)allowLoops
{
	NCFunctionObject *control ;
	NCSystem *system ;
	
	system = [ compiler system ] ;
	[ system clearAbort ] ;
	[ system setRunLoops:0 ] ;				//  block any runs for now
	
	stack.system = system ;
	[ system setRuntimeStack:&stack ] ;		//  set up the runtime stack for this run
	sendCardToNEC = runNEC ;				//	used to emit hollerith only
	
	runModelCount = 0 ;
	[ stack.system setKeepDataBetweenModelRuns:NO ] ;	//  v0.81d
	//  first look for a control() block, run it if it is found
	control = (NCFunctionObject*)[ [ compiler symbolTable ] containsIdent:@"control" ] ;
	if ( control != nil || [ control isFunction ] == YES ) {
		[ system setRunLoops:( allowLoops ) ? 20000 : 1 ] ;		//  allow a max of 20,000 loops
		[ control runBlock:&stack ] ;
		return YES ;
	}
	return [ self runModel ] ;
}

//		override by subclasses that needs GUI action
- (void)displayStop:(Boolean)state
{
}

- (void)NEC2ErrorAlert
{				
	[ AlertExtension modalAlert:@"NEC-2 Error." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nThe NEC-2 engine returned an error.\n\nPossible errors are wire elements that touches z=0 or a geometry element that has been reflected upon itself.\n" ] ;
}

//  return 0 if successful, 1 if compile error, 2 if execute error
- (int)runWorkFlowCompile:(Boolean)doCompile execute:(Boolean)doExecute allowLoops:(Boolean)allowLoops runNEC:(Boolean)doRun sourceString:(NSString*)sourceString
{
	Boolean success ;
	NCSystem *system ;
	
	if ( doCompile ) {
		[ self setProgress:YES ] ;
		
		compiler = [ [ NCCompiler alloc ] initWithString:sourceString documentNumber:documentNumber ] ;
		system = [ compiler system ] ;
		
		[ [ NSApp delegate ] setCurrentNCSystem:system ] ;
		success = [ compiler precompile ] ;
		success = ( [ compiler compile ] && success == YES ) ;
			
		if ( success == NO ) {
			[ self performSelectorOnMainThread:@selector(outputListing:) withObject:self waitUntilDone:YES ] ;
			[ self setProgress:NO ] ;
			[ self releaseCompiler ] ;
			return 1 ;
		}
		if ( success == YES ) {
			[ self displayStop:YES ] ;
			if ( doExecute ) {
				//  run the compiled code
				success = [ self execute:doRun allowLoops:allowLoops ] ;
				if ( !success ) {
					[ self releaseCompiler ] ;
					return 2 ;
				}
			}
			//  send source listing to panel
			[ self performSelectorOnMainThread:@selector(outputListing:) withObject:self waitUntilDone:YES ] ;
			[ self displayStop:NO ] ;
		}
	}
	[ self releaseCompiler ] ;
	[ self setProgress:NO ] ;
	return 0 ;
}


//  support for card deck output
//  cards TableView
- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(intType)row
{
	if ( tableView == cardsView ) {
	
		if ( row >= [ hollerithArray count ] ) return @"" ;
		
		if ( tableColumn == hollerithCardColumn ) {
			return [ hollerithArray objectAtIndex:row ] ;
		}
		return [ NSString stringWithFormat:@"%d", (int)( row+1 ) ] ;
	}
	return @"" ;
}

//  cards TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
	if ( tableView == cardsView ) {
		return [ hollerithArray count ] ;
	}
	return 0 ;
}

@end
