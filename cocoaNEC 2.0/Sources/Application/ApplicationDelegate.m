//
//  ApplicationDelegate.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/7/07.
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

#import "ApplicationDelegate.h"
#import "AlertExtension.h"
#import "EZImport.h"
#import "nec2cInterface.h"
#import "plist.h"
#import "RecentHollerith.h"
#import "RecentModel.h"
#import "RecentNC.h"
#import "SavePanelExtension.h"


//  cocoNEC 2.0 uses the public domain nec2c.rxq program as its compute engine.
//  nec2c.rxq is the work of Jeroen Vreeken (PE1RXQ) which is based on Neoklis Kyriazis (5B4AZ) nec2c program that was translated from 
//	the original NEC2 that was written by Jerry Burke and A. J. Poggio of the Lawrence Livermore Labs.

@implementation ApplicationDelegate

#define kViewAsNumbers	@"View as Numbers"
#define kViewAsFormulas	@"View as Formulas"

@synthesize prefWindow ;
@synthesize errorPanel ;


- (void)removeSplash
{
    [ splashWindow orderOut:self ] ;
}

- (id)init
{
	int i, j ;
	float v, u ;
	
	self = [ super init ] ;
	if ( self ) {
		windowPosition = nil ;	//  v0.70
		enabled3d = YES ;
		plist = [ [ NSMutableDictionary alloc ] init ] ;
		[ plist setObject:@"nec2c (embedded)" forKey:kEnginePref ] ;
		documentNumber = 1 ;
		spreadsheets = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		currentSpreadsheet = nil ;
		hollerithDecks = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		currentHollerith = nil ;
		ncFiles = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		about = nil ;
		selectedMode = kSpreadsheetMode ;

		visitedFiles = [ [ NSMutableArray alloc ] init ] ;
		defaultDirectory = nil ;
	
		for ( i = 0; i < 256; i++ ) {
			v = i/255.0 ;
			u = 0 ;
			if ( v > 0.8 ) u = ( v - 0.8 )*4.0 ;
			currentMagnitude[i] = [ [ NSColor colorWithDeviceRed:v green:u blue:( 1-v )*0.5 alpha:1.0 ] retain ] ;
			for ( j = 0; j < 64; j++ ) {
				//  hue is phase angle
				u = j/64.0 ;
				currentMagnitudeWithPhase[i*64+j] = [ [ NSColor colorWithDeviceHue:u saturation:1.0 brightness:v alpha:1.0 ] retain ];
			}
		}
	}
	return self ;
}

- (NSString*)windowPosition
{
	return windowPosition ;
}

- (void)setWindowPosition:(NSString*)position
{
	if ( position != nil ) {
		if ( windowPosition != nil ) [ windowPosition release ] ;
		windowPosition = [ [ NSString alloc ] initWithString:position ] ;
	}
}

//	v0.64
- (void)dealloc
{
	int i ;
	
	for ( i = 0; i < 256; i++ ) [ currentMagnitude[i] release ] ;
	for ( i = 0; i < 16384; i++ ) [ currentMagnitudeWithPhase[i] release ] ;
	if ( windowPosition != nil ) [ windowPosition release ] ;
	[ super dealloc ] ;
}

- (void)awakeFromNib
{
    NSString *version ;
    
    //  0.92 Splash screen
    version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
    if ( version ) {
        [ splashVersion setStringValue:[ NSString stringWithFormat:@"Version %s", [ version UTF8String ] ] ] ;
    }
    [ splashWindow center ] ;
    [ splashWindow orderFront:self ] ;

	output = [ [ NECOutput alloc ] init ] ;
 	[ animateMenuItem setState:NSOnState ] ;
	[ engineRadioButtons setAction:@selector( setEngineType ) ] ;
	[ engineRadioButtons setTarget:self ] ;
	[ NSApp setDelegate:self ] ;
	[ self updatePrefs ] ;
}

- (Boolean)enabled3d
{
	return enabled3d ;
}

//  This causes -validateMenuItem to disable certain menu items
- (void)setSelectedMode:(int)mode
{
	selectedMode = mode ;			// either kSpreadsheetMode, kHollerithMode or kNCMode
}

//  use NEC-4 output in the output window
- (IBAction)openNEC4output:(id)sender
{
	NSOpenPanel *open ;
	NSString *name, *path ;
	const char *cpath, *cname ;
	NSInteger result ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil ] ;

    if ( result == NSModalResponseOK  && [ open URL ] != nil ) {
        
        path = [ [ open URL ] path ] ;
        
        if ( path != nil ) {
            name = [ [ path lastPathComponent ] stringByDeletingPathExtension ] ;
            cpath = [ path cStringUsingEncoding:NSASCIIStringEncoding ] ;
            cname = [ name cStringUsingEncoding:NSASCIIStringEncoding ] ;
            
            runInfo.elapsedTime = 0.0 ;	//  v0.61
            runInfo.errorCode = 0 ;
            runInfo.useQuad = NO ;
            //  v0.62 added averageGain
            runInfo.directivity = runInfo.maxGain = runInfo.averageGain = runInfo.azimuthAngleAtMaxGain = runInfo.elevationAngleAtMaxGain = 0.0 ;
            runInfo.frontToBackRatio = runInfo.frontToRearRatio = 0.0 ;
            runInfo.efficiency = 100.0 ;

            [ output newNEC4OutputFor:name lpt:path exceptions:nil resetContext:YES result:&runInfo ] ;
            [ output openWindow ] ;
        }
	}
}

//  use nec2c output in the output window
- (IBAction)openNEC2Coutput:(id)sender
{
	NSOpenPanel *open ;
	NSString *name, *path ;
	const char *cpath, *cname ;
	NSInteger result ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil ] ;

	if ( result == NSModalResponseOK && [ open URL ] != nil ) {
		path = [ [ open URL ] path ] ;
		name = [ [ path lastPathComponent ] stringByDeletingPathExtension ] ;
		cpath = [ path cStringUsingEncoding:NSASCIIStringEncoding ] ;
		cname = [ name cStringUsingEncoding:NSASCIIStringEncoding ] ;
		
		runInfo.elapsedTime = 0.0 ;		//  v0.61
		runInfo.errorCode = 0 ;
		runInfo.useQuad = NO ;
		runInfo.directivity = runInfo.maxGain = runInfo.azimuthAngleAtMaxGain = runInfo.elevationAngleAtMaxGain = 0.0 ;
		runInfo.frontToBackRatio = runInfo.frontToRearRatio = 0.0 ;
		runInfo.efficiency = 100.0 ;

		[ output newNEC2COutputFor:name lpt:path exceptions:nil resetContext:YES result:&runInfo ] ;
		[ output openWindow ] ;
	}
}

- (void)setEngineType
{
	switch ( [ engineRadioButtons selectedRow ] ) {
	case 1:
		engineType = kNEC41Engine ;                 //  v0.78
        [ Config setEngineType:engineType ] ;       //  v0.89
		return ;
	case 2:
		engineType = ( [ useGN2Checkbox state ] == NSOffState ) ? kNEC42Engine : kNEC42EngineGN2 ;		//  v0.78, v0.80
        [ Config setEngineType:engineType ] ;       //  v0.89
		return ;
	}
	engineType = knec2cEngine ;
    [ Config setEngineType:engineType ] ;           //  v0.89
}

//	knec2cEngine		nec2c
//  kNEC41Engine		NEC-4 and NEC-4.1
//  kNEC42Engine		NEC-4.2
//  kNEC42EngineGN2		NEC-4.2 with GN2 ground
- (int)engine
{
	return engineType ;
}

//	(Private API)
//	v0.78
- (int)runNec2c:(NSString*)inputPath output:(NSString*)outputPath useQuad:(Boolean)useQuad
{
	int errorCode ;
	char *inputp = (char*)[ inputPath UTF8String ] ;
	char *outputp = (char*)[ outputPath UTF8String ] ;
    
    errorCode = ( useQuad ) ? necQuad( inputp, outputp, 4 ) : necDouble( inputp, outputp, 4 ) ;		//  allows 4 processors
 
	return errorCode ;
}

//  -------------------------------------------------------------
//  run cards in inputPath through nec2c or other engines (v0.45)
//  write NEC-2 output to outputPath
//  useQuad runsnec2c at quad precision
//  sourcePath is where the original nec, nc or hol file is in
//  -------------------------------------------------------------
- (RunInfo*)runNECEngine:(NSString*)inputPath output:(NSString*)outputPath sourcePath:(NSString*)sourcePath useQuad:(Boolean)useQuad
{
    NSDate *date = [ NSDate date ] ;
	int errorCode, engine ;
	
	engine = [ self engine ] ;
	if ( engine == kNEC41Engine || engine == kNEC42Engine || engine == kNEC42EngineGN2 ) {		//  v0.78, v0.80
		//  NEC-4
		NSTask *task ;
		NSFileHandle *inFile, *outFile ;
		NSString *unit5, *unit6, *workingDirectory, *launchPath ;
		FILE *fd ;
		
		errorCode = 0xdeadbeef ;
		unit5 = @"/tmp/necKeyboardInput" ;
		unit6 = @"/tmp/necErrorOutput" ;
		
		//  unit5 is a file that contains the name of the actual card deck file (inputPath), and the name of the lineprinter output file (outputPath).  
		//  NEC-4 will read the unit5 file in as if the user has typed it.
		
		fd = fopen( [ unit5 cStringUsingEncoding:NSASCIIStringEncoding ], "w" ) ;
		fprintf( fd, "%s\n", [ inputPath cStringUsingEncoding:NSASCIIStringEncoding ] ) ;
		fprintf( fd, "%s\n", [ outputPath cStringUsingEncoding:NSASCIIStringEncoding ] ) ;
		fclose( fd ) ;
		fd = fopen( [ unit6 cStringUsingEncoding:NSASCIIStringEncoding ], "w" ) ;
		fclose( fd ) ;
		
		//  now find the director to connect to
		workingDirectory = [ sourcePath stringByDeletingLastPathComponent ] ;			// v0.47a

		//  use NEC4, copy files
		useQuad = NO ;
		inFile = [ NSFileHandle fileHandleForReadingAtPath:unit5 ] ;
		outFile = [ NSFileHandle fileHandleForWritingAtPath:unit6 ] ;
		task = [ [ NSTask alloc ] init ] ;
		[ task setStandardInput:inFile ] ;
		[ task setStandardOutput:outFile ] ;
		[ task setCurrentDirectoryPath:workingDirectory ] ;								// v0.47a
		//  v0.78
		launchPath = ( engine == kNEC41Engine ) ? @"/Applications/nec4d" : @"/Applications/nec4d42" ;
		if ( [ [ NSFileManager defaultManager ] fileExistsAtPath:launchPath ] == NO ) {
			//  cannot find executable
			switch ( engine ) {
			default:
                {
                    NSString *info = [ NSString stringWithFormat:@"\ncocoaNEC cannot find a NEC-4 executable file at\n\n    %@\n\nPlease select the nec2c engine in the cocoaNEC Preferences window.\n\nNEC-4.1 must be individually licensed to you by the Lawrence Livermore National Labs.\n\nThe NEC-4 source code has to be compiled locally by you to run on Mac OS X and placed at the above location (please see NEC-4 page in the cocoaNEC web site).\n\n", launchPath ] ;
                    
                    [ AlertExtension modalAlert:NSLocalizedString( @"NEC-4 Engine not found.", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
                }
				break ;
			case kNEC41Engine:
                {
                    NSString *info = [ NSString stringWithFormat:@"\ncocoaNEC cannot find a NEC-4.1 executable file at\n\n    %@\n\nPlease select the nec2c engine in the cocoaNEC Preferences window, or move the NEC 4.1 executable file to the above path if it currently has the wrong path name.\n\nNEC-4.1 must be individually licensed to you by the Lawrence Livermore National Labs.\n\nThe NEC-4.1 source code has to be compiled locally by you to run on Mac OS X and placed at the above location (please see NEC-4 page in the cocoaNEC web site).\n\n", launchPath ] ;
                    
                    [ AlertExtension modalAlert:NSLocalizedString( @"NEC-4.1 Engine not found.", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
                }
				break ;
			case kNEC42Engine:
			case kNEC42EngineGN2:
                {
                    NSString *info = [ NSString stringWithFormat:@"\ncocoaNEC cannot find a NEC-4.2 executable file at\n\n    %@\n\nPlease select the nec2c engine in the cocoaNEC Preferences window, or move the NEC 4.2 executable file to the above path if it currently has the wrong path name.\n\nNEC-4.2 must be individually licensed to you by the Lawrence Livermore National Labs.\n\nThe NEC-4.2 source code has to be compiled locally by you to run on Mac OS X and placed at the above location (please see NEC-4 page in the cocoaNEC web site).\n\n", launchPath ] ;
                    
                    [ AlertExtension modalAlert:NSLocalizedString( @"NEC-4.2 Engine not found.", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
                }
				break ;
			}
			errorCode = kEngineNotFound ;
		}
		else {
			[ task setLaunchPath:launchPath ] ;
			[ task launch ] ;
			[ task waitUntilExit ] ;
			errorCode = [ task terminationStatus ] ;
			[ task release ] ;
		}
	}
	else {
		//  NEC-2
		errorCode = [ self runNec2c:inputPath output:outputPath useQuad:useQuad ] ; ;
	}
	
	runInfo.elapsedTime = -[ date timeIntervalSinceNow ] ;					//  v0.61
	
 	runInfo.errorCode = errorCode ;
	runInfo.useQuad = useQuad ;
	//  v0.62 added averageGain
	runInfo.directivity = runInfo.maxGain = runInfo.averageGain = runInfo.azimuthAngleAtMaxGain = runInfo.elevationAngleAtMaxGain = 0.0 ;
	runInfo.frontToBackRatio = runInfo.frontToRearRatio = 0.0 ;
	runInfo.efficiency = 100.0 ;
	
	return &runInfo ;
}

- (void)displayNECOutput:(NSString*)name hollerith:(NSString*)hollerith lpt:(NSString*)lpt source:(NSString*)source exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result
{
	[ output newOutputFor:name hollerith:hollerith lpt:lpt source:source exceptions:exceptions resetContext:resetContext result:result ] ;
	[ output openWindow ] ;
}

- (NSString*)defaultDirectory
{
	return defaultDirectory ;
}

- (void)setDefaultDirectory:(NSString*)str
{
	if ( str == nil ) defaultDirectory = nil ;
	else {
		defaultDirectory = [ [ NSString alloc ] initWithString:[ str stringByExpandingTildeInPath ] ] ;
	}
}

//  check if path is already in visitedFiles array
- (Boolean)visited:(NSString*)path
{
    int i ;
    intType count ;
    
	count = [ visitedFiles count ] ;
	for ( i = 0; i < count; i++ ) {
		if ( [ path isEqualToString:[ visitedFiles objectAtIndex:i ] ] ) return YES ;
	}
	return NO ;
}

- (void)openModelAtPath:(NSString*)path includeInRecent:(Boolean)include
{
	NSDictionary *mlist ;

    // v0.88 deprecated  CFPropertyListRef CFPropertyListCreateFromXMLData(CFAllocatorRef allocator, CFDataRef xmlData, CFOptionFlags mutabilityOption, CFStringRef *errorString)
    //  NSString *errorString ;
    //  NSData *xmlData ;
	//  xmlData = [ NSData dataWithContentsOfFile:path ] ;
	//  mlist = (NSDictionary*)CFPropertyListCreateFromXMLData( kCFAllocatorDefault, (CFDataRef)xmlData, kCFPropertyListImmutable, (CFStringRef*)&errorString ) ;
    
    NSData *nsdata = [ NSData dataWithContentsOfFile:path ] ;
    CFDataRef cfdata = CFDataCreate( kCFAllocatorDefault, [ nsdata bytes ], [ nsdata length ] ) ;
    mlist = ( NSDictionary* )CFPropertyListCreateWithData( kCFAllocatorDefault, cfdata, kCFPropertyListImmutable, nil, nil ) ;
    
    [ self removeSplash ] ;
    
	if ( mlist ) {
		currentSpreadsheet = [ [ Spreadsheet alloc ] initWithGlobals:sharedGlobals number:documentNumber++ untitled:NO ] ;
		[ currentSpreadsheet setSourcePath:path ] ;
		[ spreadsheets addObject:currentSpreadsheet ] ;
		[ currentSpreadsheet updateFromPlist:mlist name:[ [ path stringByDeletingPathExtension ] lastPathComponent ] ] ;
		[ currentSpreadsheet becomeKeyWindow ] ;
		[ self setSelectedMode:kSpreadsheetMode ] ;
		if ( include ) {
			[ recentModel touchedPath:path ] ;
			if ( ![ self visited:path ] ) [ visitedFiles addObject:path ] ;
		}
		[ mlist release ] ;
		return ;
	}
	[ AlertExtension modalAlert:@"Could not find file." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nFile may have moved or have been deleted.\n" ] ;
	[ plist release ] ;
    plist = nil ;
}

- (void)openHollerithAtPath:(NSString*)path
{
	FILE *file ;

    [ self removeSplash ] ;
    
	file = fopen( [ path UTF8String ], "r" ) ;
	if ( file ) {
		currentHollerith = [ [ Hollerith alloc ] initWithDocumentNumber:documentNumber++ ] ;
		[ currentHollerith setSourcePath:path ] ;
		[ hollerithDecks addObject:currentHollerith ] ;
		[ currentHollerith updateFromFile:file name:[ [ path stringByDeletingPathExtension ] lastPathComponent ] ] ;
		[ currentHollerith becomeKeyWindow ] ;
		fclose( file ) ;
		[ recentHollerith touchedPath:path ] ;
		[ self setSelectedMode:kHollerithMode ] ;
		return ;
	}
	[ AlertExtension modalAlert:@"Could not find file." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nFile may have moved or have been deleted.\n" ] ;
}

- (void)openNCModelAtPath:(NSString*)path
{
	FILE *file ;
    
    [ self removeSplash ] ;
	
	file = fopen( [ path UTF8String ], "r" ) ;
	if ( file ) {
		fclose( file ) ;
		currentNC = [ [ NC alloc ] initWithDocumentNumber:documentNumber++ untitled:NO ] ;
		[ currentNC setSourcePath:path ] ;
		[ ncFiles addObject:currentNC ] ;
		[ currentNC updateFromPath:path ] ;
		if ( windowPosition ) [ currentNC setWindowPosition:windowPosition ] ;
		[ currentNC becomeKeyWindow ] ;
		[ recentNC touchedPath:path ] ;
		[ self setSelectedMode:kNCMode ] ;
		return ;
	}
	[ AlertExtension modalAlert:@"Could not find file." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nFile may have moved or have been deleted.\n" ] ;
}

- (void)openEZAtPath:(NSString*)path
{
	FILE *file ;
	EZImport *ez ;
	
    [ self removeSplash ] ;
    
	file = fopen( [ path UTF8String ], "r" ) ;
	if ( file ) {
		fclose( file ) ;
		ez = [ [ EZImport alloc ] initWithGlobals:sharedGlobals number:documentNumber++ untitled:NO ] ;
		currentSpreadsheet = ez ;
		[ spreadsheets addObject:currentSpreadsheet ] ;
		[ ez import:path ] ;
		[ currentSpreadsheet becomeKeyWindow ] ;
		[ self setSelectedMode:kSpreadsheetMode ] ;
	}
}

- (void)hollerithBecameKey:(Hollerith*)which
{
	currentHollerith = which ;
	[ self setSelectedMode:kHollerithMode ] ;
}

- (void)hollerithClosing:(Hollerith*)which
{
	[ hollerithDecks removeObject:which ] ;
}

- (void)spreadsheetBecameKey:(Spreadsheet*)which
{
	currentSpreadsheet = which ;
	[ self setSelectedMode:kSpreadsheetMode ] ;
}

- (void)spreadsheetClosing:(Spreadsheet*)which
{
	[ spreadsheets removeObject:which ] ;
}

- (void)ncBecameKey:(NC*)which
{
	currentNC = which ;
	[ self setSelectedMode:kNCMode ] ;
}

- (void)ncClosing:(NC*)which
{
	[ ncFiles removeObject:which ] ;
}

- (Spreadsheet*)currentSpreadsheet
{
	return currentSpreadsheet ;
}

- (NC*)currentNC
{
	return currentNC ;
}

- (void)setCurrentNC:(NC*)nc
{
	currentNC = nc ;
}

- (void)setCurrentNCSystem:(NCSystem*)sys
{
	currentNCSystem = sys ;
}

- (NCSystem*)currentNCSystem
{
	return currentNCSystem ;
}

- (void)clearError
{
	intType count ;
	NSTextStorage *store ;
	
	hasError = NO ;
	store = [ errorView textStorage ] ;
	count = [ [ store characters ] count ] ;
	if ( count > 0 ) {
		[ store deleteCharactersInRange:NSMakeRange(0,count) ] ;
		[ errorView setNeedsDisplay:YES ] ;
	}
}

- (void)insertError:(NSString*)errString 
{
	hasError = YES ;
	[ errorView insertText:errString ] ;
	[ errorView insertText:@"\n" ] ;
}

- (Boolean)hasError
{
	return hasError ;
}

- (Boolean)showError
{
	NSWindow *window ;
	
	if ( hasError ) {
		window = [ errorView window ] ;
		[ window orderFront:self ] ;
	}
	return hasError ;
}

- (void)applicationWillHide:(NSNotification *)aNotification
{
    int i ;
    intType count ;
	Spreadsheet *target ;
	
	count = [ spreadsheets count ] ;
	for ( i = 0; i < count; i++ ) {
		target = [ spreadsheets objectAtIndex:i ] ;
		if ( target != currentSpreadsheet ) [ target hideWindow ] ;
	}
	// do current spread sheet last so it remains the key window
	[ currentSpreadsheet hideWindow ] ;
}

- (void)applicationWillUnhide:(NSNotification*)aNotification
{
    int i ;
    intType count ;
	Spreadsheet *target ;
	
	count = [ spreadsheets count ] ;
	for ( i = 0; i < count; i++ ) {
		target = [ spreadsheets objectAtIndex:i ] ;
		if ( target != currentSpreadsheet ) [ target showWindow ] ;
	}
	// do current spread sheet last so it is on top
	[ currentSpreadsheet showWindow ] ;
}

- (IBAction)newModel:(id)sender ;
{
    [ self removeSplash ] ;
    
	currentSpreadsheet = [ [ Spreadsheet alloc ] initWithGlobals:sharedGlobals number:documentNumber++ untitled:YES ] ;
	[ currentSpreadsheet setSourcePath:[ currentSpreadsheet title ] ] ;
	[ spreadsheets addObject:currentSpreadsheet ] ;
	[ currentSpreadsheet becomeKeyWindow ] ;
	[ self setSelectedMode:kSpreadsheetMode ] ;
}

- (IBAction)openModel:(id)sender
{
	NSOpenPanel *open ;
	NSInteger result ;
    
    [ self removeSplash ] ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil types:[ NSArray arrayWithObjects:@"nec", @"xml", nil ] ] ;
    if ( result == NSModalResponseOK  && [ open URL ] != nil ) {
		[ self openModelAtPath:[ [ open URL ] path ] includeInRecent:YES ] ;
		[ self setSelectedMode:kSpreadsheetMode ] ;
	}
}

- (NSString*)determineCopiedName:(NSString*)title
{
	NSString *base, *shortened, *check ;
    int i ;
    intType length ;
	
	length = [ title length ] ;
	base = title ;
	
	//  first check to see if title ends with " copy" or " copy n"
	if ( length >= 6 ) {
		if ( [ [ title substringFromIndex:length-5 ] isEqualToString:@" copy" ] ) base = [ title substringToIndex:length-5 ] ;
		else {
			shortened = [ title substringToIndex:length-1 ] ;
			length = [ shortened length ] ;
			if ( length >= 7 ) {
				if ( [ [ shortened substringFromIndex:length-6 ] isEqualToString:@" copy " ] )  base = [ shortened substringToIndex:length-6 ] ;
				else {
					shortened = [ shortened substringToIndex:length-1 ] ;
					length = [ shortened length ] ;
					if ( length >= 7 ) {
						if ( [ [ shortened substringFromIndex:length-6 ] isEqualToString:@" copy " ] )  base = [ shortened substringToIndex:length-6 ] ;
					}
				}
			}
		}
	}
	check = [ base stringByAppendingString:@" copy" ] ;
	if ( ![ self visited:check ] ) return check ;
	for ( i = 0; i < 99; i++ ) {
		check = [ base stringByAppendingString:[ NSString stringWithFormat:@" copy %d", i+1 ] ] ;
		if ( ![ self visited:check ] ) return check ;
	}
	return [ base stringByAppendingString:@" copy_" ] ;
}

- (RunInfo*)runInfo
{
	return &runInfo ;
}

- (void)setDirectivity:(double)value
{
	runInfo.directivity = value ;
}

- (NECOutput*)output
{
	return output ;
}

- (IBAction)duplicateModel:(id)sender
{
	NSString *tempPath, *title ;
	
	if ( currentSpreadsheet == nil ) {
		[ AlertExtension modalAlert:@"No model to duplicate." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"\nYou need to have a model open to make a duplicate.\n" ] ;
		return ;
	}
	tempPath = [ NSString stringWithFormat:@"/tmp/cocoaNECtemp%d.nec", documentNumber ] ;
	[ currentSpreadsheet saveToPath:tempPath ] ;
	title = [ currentSpreadsheet title ] ;
	[ self openModelAtPath:tempPath includeInRecent:NO ] ;
	//  first check if name already have " copy" at the end of the string
	title = [ self determineCopiedName:title ] ;
	[ currentSpreadsheet setTitle:title ] ;
	[ self setSelectedMode:kSpreadsheetMode ] ;
	if ( ![ self visited:title ] ) [ visitedFiles addObject:title ] ;
	[ currentSpreadsheet setSourcePath:title ] ;
	
	[ [ NSFileManager defaultManager] removeItemAtPath:tempPath error:nil ] ;
}

- (IBAction)save:(id)sender
{
	NSString *savedPath ;
	
	if ( selectedMode == kSpreadsheetMode ) {
		if ( [ currentSpreadsheet untitled ] ) {
			//  still untitled, use save as
			[ self saveAs:sender ] ;
			return ;
		}
		savedPath = [ currentSpreadsheet save:NO ] ;
		if ( savedPath ) {
			[ recentModel touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
	if ( selectedMode == kNCMode ) {
		if ( [ currentNC untitled ] ) {
			//  still untitled, use save as
			[ self saveAs:sender ] ;
			return ;
		}
		savedPath = [ currentNC save:NO ] ;
		if ( savedPath ) {
			[ recentNC touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
	if ( selectedMode == kHollerithMode ) {
		savedPath = [ currentHollerith save:NO ] ;
		if ( savedPath ) {
			[ recentHollerith touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
}

- (IBAction)saveAs:(id)sender
{
	NSString *savedPath ;
	
	if ( selectedMode == kSpreadsheetMode ) {
		savedPath = [ currentSpreadsheet save:YES ] ;
		if ( savedPath ) {
			[ recentModel touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
	if ( selectedMode == kNCMode ) {
		savedPath = [ currentNC save:YES ] ;
		if ( savedPath ) {
			[ recentNC touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
	if ( selectedMode == kHollerithMode ) {
		savedPath = [ currentHollerith save:YES ] ;
		if ( savedPath ) {
			[ recentHollerith touchedPath:savedPath ] ;
			if ( ![ self visited:savedPath ] ) [ visitedFiles addObject:savedPath ] ;
		}
		return ;
	}
}

- (IBAction)runModel:(id)sender
{
	[ currentSpreadsheet runButtonPushed:sender ] ;
}

- (IBAction)setAsReference:(id)sender
{
	NSMenuItem *menuItem = [ outputMenu itemWithTitle:@"Use Previous Run As Reference" ] ;
	if ( menuItem ) [ menuItem setState:NSOffState ] ;
	
	[ sender setState:NSOnState ] ;
	[ output useAsReference ] ;
}

- (IBAction)setRunAsReference:(id)sender 
{
	NSMenuItem *menuItem = [ outputMenu itemWithTitle:@"Use As Reference" ] ;
	if ( menuItem ) [ menuItem setState:NSOffState ] ;
	
	[ sender setState:NSOnState ] ;
	[ output usePreviousRunAsReference ] ;
}

- (IBAction)removeReference:(id)sender
{
	NSMenuItem *menuItem = [ outputMenu itemWithTitle:@"Use Previous Run As Reference" ] ;
	if ( menuItem ) [ menuItem setState:NSOffState ] ;
	menuItem = [ outputMenu itemWithTitle:@"Use As Reference" ] ;
	if ( menuItem ) [ menuItem setState:NSOffState ] ;
	
	[ output removeCurrentReference ] ;
}

- (void)polOff
{
	[ polMenu1 setState:NSOffState ] ;
	[ polMenu2 setState:NSOffState ] ;
	[ polMenu3 setState:NSOffState ] ;
	[ polMenu4 setState:NSOffState ] ;
	[ polMenu5 setState:NSOffState ] ;
	[ polMenu6 setState:NSOffState ] ;
	[ polMenu7 setState:NSOffState ] ;
}

//	v0.68
- (IBAction)polarizationChanged:(NSMenuItem*)sender
{
	[ self polOff ] ;
	[ sender setState:NSOnState ] ;
	[ output polarizationChanged:[ sender tag ] ] ;
}

- (void)setPolarizationMenu:(intType)pol
{
	[ self polOff ] ;
	switch ( pol ) {
	case 0:	
		[ polMenu2 setState:NSOnState ] ;
		break ;
	case 1:	
		[ polMenu3 setState:NSOnState ] ;
		break ;
	case 2:	
		[ polMenu1 setState:NSOnState ] ;
		break ;
	case 3:	
		[ polMenu5 setState:NSOnState ] ;
		break ;
	case 4:	
		[ polMenu6 setState:NSOnState ] ;
		break ;
	case 5:	
		[ polMenu4 setState:NSOnState ] ;
		break ;
	case 6:	
		[ polMenu7 setState:NSOnState ] ;
		break ;
	}
}

- (IBAction)enable3D:(id)sender
{
	[ sender setState:( [ sender state ] == NSOnState ) ? NSOffState : NSOnState ] ;
	enabled3d = ( [ sender state ] == NSOnState ) ;
}

- (IBAction)openHollerith:(id)sender
{
	NSOpenPanel *open ;
	NSInteger result ;
    
    [ self removeSplash ] ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil types:nil ] ;
	if ( result == NSModalResponseOK && [ open URL ] != nil ) {
		[ self openHollerithAtPath:[ [ open URL ] path ] ] ;
		[ self setSelectedMode:kHollerithMode ] ;
	}
}

- (IBAction)saveHollerith:(id)sender
{
	switch ( selectedMode ) {
	default:
	case kSpreadsheetMode:
		if ( currentSpreadsheet ) [ currentSpreadsheet saveToHollerith ] ;
		break ;
	case kNCMode:
		if ( currentNC ) [ currentNC saveToHollerith ] ;
		break ;
	}
}

- (IBAction)newNCModel:(id)sender ;
{
    [ self removeSplash ] ;
    
	currentNC = [ [ NC alloc ] initWithDocumentNumber:documentNumber++ untitled:YES ] ;
	if ( currentNC ) {
		[ currentNC setSourcePath:[ currentNC title ] ] ;
		[ ncFiles addObject:currentNC ] ;
		if ( windowPosition ) [ currentNC setWindowPosition:windowPosition ] ;
		[ currentNC becomeKeyWindow ] ;
		[ self setSelectedMode:kNCMode ] ;
	}
}

- (IBAction)openNCModel:(id)sender
{
	NSOpenPanel *open ;
	NSInteger result ;
    
    [ self removeSplash ] ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil types:[ NSArray arrayWithObjects:@"nc", nil ] ] ;
	if ( result == NSModalResponseOK  && [ open URL ] != nil ) {	//  v0.87
		[ self openNCModelAtPath:[ [ open URL ] path ] ] ;
		[ self setSelectedMode:kNCMode ] ;
	}
}

- (IBAction)openNCWindows:(id)sender
{
	if ( currentNC ) [ currentNC becomeKeyWindow ] ;				//  show all NC windows, not just current
}

- (IBAction)executeNC:(id)sender
{
	if ( currentNC ) [ currentNC run:self ] ;
}

// disable until we implement MININEC grounds
- (IBAction)importEZ:(id)sender
{
	NSOpenPanel *open ;
	NSInteger result ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
    result = [ SavePanelExtension runModalFor:open directory:defaultDirectory file:nil types:[ NSArray arrayWithObjects:@"EZ", nil ] ] ;
	if ( result == NSModalResponseOK  && [ open URL ] != nil ) {
		[ self openEZAtPath:[ [ open URL ] path ] ] ;
		[ self setSelectedMode:kSpreadsheetMode ] ;
	}
}

- (IBAction)openElementInspector:(id)sender
{
    if ( currentSpreadsheet ) [ currentSpreadsheet inspectGeometryElement ] ;
}

- (IBAction)openOutputViewer:(id)sender 
{
	[ output openWindow ] ;
}

- (IBAction)print:(id)sender
{
	[ output printView:sender ] ;
}

- (IBAction)showAbout:(id)sender 
{
	if ( about == nil ) about = [ [ About alloc ] init ] ;
	[ about showPanel ] ;
}

- (IBAction)viewAsFormula:(NSMenuItem*)sender 
{
	intType type = [ sender tag ] ;
	
	switch ( type ) {
	case 0:
	default:
		[ sender setTitle:kViewAsNumbers ] ;
		[ sender setTag:1 ] ;
		break ;
	case 1:
		[ sender setTitle:kViewAsFormulas ] ;
		[ sender setTag:0 ] ;
		break ;
	}
	if ( selectedMode == kSpreadsheetMode && currentSpreadsheet != nil ) [ currentSpreadsheet setViewAsFormulas:( type == 0 ) ] ;
}


- (void)updatePrefs
{
	NSNumber *number ;
	NSString *string ;
	NSDictionary *dict ;
	intType i, rows ;
	
    // v0.88 deprecated  CFPropertyListRef CFPropertyListCreateFromXMLData(CFAllocatorRef allocator, CFDataRef xmlData, CFOptionFlags mutabilityOption, CFStringRef *errorString)
	//  NSData *xmlData = [ NSData dataWithContentsOfFile:[ kPrefPath stringByExpandingTildeInPath ] ] ;
    //  NSString *errorString ;
	//  dict = (NSDictionary*)CFPropertyListCreateFromXMLData( kCFAllocatorDefault, (CFDataRef)xmlData, kCFPropertyListImmutable, (CFStringRef*)&errorString ) ;
    
    NSData *nsdata = [ NSData dataWithContentsOfFile:[ kPrefPath stringByExpandingTildeInPath ] ] ;
    CFDataRef cfdata = CFDataCreate( kCFAllocatorDefault, [ nsdata bytes ], [ nsdata length ] ) ;
    dict = ( NSDictionary* )CFPropertyListCreateWithData( kCFAllocatorDefault, cfdata, kCFPropertyListImmutable, nil, nil ) ;
    
	if ( dict ) {
		[ self setDefaultDirectory:[ dict objectForKey:@"NSNavLastRootDirectory" ] ] ;
		[ output updatePrefsFromDict:dict ] ;
		[ recentModel updatePrefsFromDict:dict ] ;
		[ recentHollerith updatePrefsFromDict:dict ] ;
		[ recentNC updatePrefsFromDict:dict ] ;
		//  engine prefs
		[ engineRadioButtons selectCellAtRow:0 column:0 ] ;
		string = [ dict objectForKey:kEnginePref ] ;
		if ( string ) {
			rows = [ engineRadioButtons numberOfRows ] ;
			for ( i = 0; i < rows; i++ ) {
				if ( [ string isEqualToString:[ [ engineRadioButtons cellAtRow:i column:0 ] title ] ] ) {
					[ engineRadioButtons selectCellAtRow:i column:0 ] ;
					break ;
				}
			}
		}
		//	v0.80
		number = [ dict objectForKey:kGroundPref ] ;
		if ( number != nil ) {
			[ useGN2Checkbox setState:( [ number boolValue ] ? NSOnState : NSOffState ) ] ;
		}
		string = [ dict objectForKey:kWindowPosition ] ;					//  v 0.70 window position
		if ( string ) {
			if ( windowPosition ) [ windowPosition release ] ;
			windowPosition = [ [ NSString alloc ] initWithString:string ] ;
		}
		[ self setEngineType ] ;
	}
	[ dict release ] ;
}

//  disallow terminate if some interface does not allow a window to close
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	intType i, count ;
	NSString *windowPos ;
	
	count = [ spreadsheets count ] ;
	for ( i = 0; i < count; i++ ) if ( ![ [ spreadsheets objectAtIndex:i ] windowCanClose ] ) return NO ;
	
	count = [ ncFiles count ] ;
	for ( i = 0; i < count; i++ ) if ( ![ [ ncFiles objectAtIndex:i ] windowCanClose ] ) return NO ;
	
	//  make and save plist
	if ( plist ) [ output savePrefsToPlist:plist ] ;        //  v0.92: had exception if recent model failed in -openModelAtPath:includeInRecent:
	[ recentModel savePrefsToPlist:plist ] ;
	[ recentHollerith savePrefsToPlist:plist ] ;
	[ recentNC savePrefsToPlist:plist ] ;
	[ plist setObject:[ [ engineRadioButtons selectedCell ] title ] forKey:kEnginePref ] ;
	[ plist setObject:[ NSNumber numberWithBool:( [ useGN2Checkbox state ] == NSOnState ) ] forKey:kGroundPref ] ;						//  v0.80
	if ( currentNC != nil ) {
		windowPos = [ currentNC windowPosition ] ;
		if ( windowPos != nil ) [ plist setObject:windowPos forKey:kWindowPosition ] ;
	}
	[ plist writeToFile:[ kPrefPath stringByExpandingTildeInPath ] atomically:YES ] ;

	return YES ;
}

- (NSColor**)colorForMagnitude
{
	return &currentMagnitude[0] ;
}

- (NSColor**)colorForMagnitudeAndPhase
{
	return &currentMagnitudeWithPhase[0] ;
}

//  enable menu items depending on the active mode
- (BOOL)validateMenuItem:(NSMenuItem*)item
{
	if ( item == saveMenuItem || item == saveAsMenuItem ) {
		//  disable Save Model if Hollerith card is currently active
		if ( selectedMode == kSpreadsheetMode ) return ( currentSpreadsheet != nil ) ;
		if ( selectedMode == kNCMode ) return ( currentNC != nil ) ;
		if ( selectedMode == kHollerithMode ) return ( currentHollerith != nil ) ;
		return NO ;
	}
	if ( item == writeDeckMenuItem ) return ( currentSpreadsheet != nil || currentNC != nil ) ;
	
	if ( [ item menu ] == outputMenu ) {
		return ( [ output hasModel ] ) ;
	}
	
	if ( [ item menu ] == modelMenu ) {
		//  model menu -- disable all items if we don't have an active spreadsheet
		if ( selectedMode != kSpreadsheetMode || currentSpreadsheet == nil ) return NO ;
	
		if ( item == viewAsNumbers )  {
			if ( selectedMode == kSpreadsheetMode && currentSpreadsheet != nil ) {
				if ( [ currentSpreadsheet viewAsFormulas ] ) {
					[ viewAsNumbers setTitle:kViewAsNumbers ] ;
					[ viewAsNumbers setTag:1 ] ;
				}
				else {
					[ viewAsNumbers setTitle:kViewAsFormulas ] ;
					[ viewAsNumbers setTag:0 ] ;
				}
				return YES ;
			}
			return NO ;
		}
	}
	if ( [ item menu ] == ncMenu ) {
		//  nc menu -- disable all items if we don't have an active nc program
		if ( selectedMode != kNCMode || currentNC == nil ) return NO ;
	}
	return YES ;
}

- (BOOL)application:(NSApplication*)application openFile:(NSString*)filename
{
	NSString *extension ;

	extension = [ filename pathExtension ] ;
	if ( [ extension isEqualToString:@"nc" ] ) {
		[ self openNCModelAtPath:filename ] ;
		return YES ;
	}
	if ( [ extension isEqualToString:@"nec" ] ) {
		[ self openModelAtPath:filename includeInRecent:YES ] ;
		[ self setSelectedMode:kSpreadsheetMode ] ;
	}
	return NO ;
}

//  help
- (void)openURLDoc:(NSString*)url
{
	[ [ NSWorkspace sharedWorkspace ] openURL:[ NSURL URLWithString:url ] ] ;
}

- (IBAction)ncFunctions:(id)sender
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/RefManual2/NCFunctions.html" ] ;	//  v0.72, v0.75
}

- (IBAction)ncExtensions:(id)sender
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/RefManual2/Extensions.html" ] ;	//  v81
}

- (IBAction)ncRefManual:(id)sender
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/RefManual2.html" ] ;				//  v0.72, v0.75
}

- (IBAction)ncTutorial:(id)sender ;
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/NC.html" ] ;						//  v0.72
}

- (IBAction)spreadsheetRefManual:(id)sender ;
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/RefManual3.html" ] ;				//  v0.72, v0.75
}

- (IBAction)spreadsheetTutorial:(id)sender ;
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/Tutorials/spreadsheet.html" ] ;	//  v0.72, v0.75
}

- (IBAction)openRefManual:(id)sender
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/RefManual.html" ] ;
}

//	v0.75d
- (IBAction)openIndex:(id)sender
{
	[ self openURLDoc:@"http://www.w7ay.net/site/Manuals/cocoaNEC/Manual/index.html" ] ;
}

- (IBAction)showPrefs:(id)sender
{
	[ prefWindow makeKeyAndOrderFront:self ] ;
}

//  v0.72
- (IBAction)checkForUpdate:(id)sender
{
	NSString *url, *version ;
	FILE *updateFile ;
	char line[129], *s, *app ;
    intType i, len ;
    NSInteger resultCode ;
	float latest, current ;

	app = "cocoaNEC 2.0" ;
	len = strlen( app ) ;
	url = @"curl -s -m10 -A \"Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)\" " ;
	url = [ url stringByAppendingString:@"\"http://www.w7ay.net/site/Downloads/updates.txt\"" ] ;
	updateFile = popen( [ url cStringUsingEncoding:NSASCIIStringEncoding ], "r" ) ;

	if ( updateFile == nil ) {
		[ AlertExtension modalAlert:NSLocalizedString( @"Update information error", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"Update file not found", nil ) ] ;
		return ;
	}
	for ( i = 0; i < 20; i++ ) {
		s = fgets( line, 128, updateFile ) ;
		if ( s == nil ) {
			[ AlertExtension modalAlert:NSLocalizedString( @"Update information error", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"No update info", nil ) ] ;
			break ;
		}
		if ( strncmp( s, app, len ) == 0 ) {
			sscanf( s+len, "%f", &latest ) ;
			version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
			sscanf( [ version cStringUsingEncoding:NSISOLatin1StringEncoding ], "%f", &current ) ;
			
			if ( ( latest - current ) > .0001 ) {
				//  v0.59
				resultCode = [ AlertExtension modalAlert:NSLocalizedString( @"New download available", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:NSLocalizedString( @"What's New", nil ) informativeTextWithFormat:NSLocalizedString( @"Update available info", nil ) ] ;

                if ( resultCode == NSAlertThirdButtonReturn ) {
					[ self openURLDoc:@"http://www.w7ay.net/site/Applications/cocoaNEC/Whats%20New/index.html" ] ;
				}
			}
			else {
				[ AlertExtension modalAlert:NSLocalizedString( @"Up to date", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"Up to date info", nil ) ] ;
			}
			break ;
		}
	}
	pclose( updateFile ) ;
}

- (int)intValueForObject:(NSObject*)object
{
	if ( currentSpreadsheet != nil ) return [ currentSpreadsheet intValueForObject:object ] ;
	return 0 ;
}

- (double)doubleValueForObject:(NSObject*)object
{
	if ( currentSpreadsheet != nil ) return [ currentSpreadsheet doubleValueForObject:object ] ;
	return 0 ;
}

- (NSArray*)transformStringsForTransform:(NSString*)name
{
	if ( currentSpreadsheet != nil ) return [ currentSpreadsheet transformStringsForTransform:name ] ;
	return [ NSArray arrayWithObjects:@"", @"", @"", @"", @"", @"", nil ] ;

}



@end
