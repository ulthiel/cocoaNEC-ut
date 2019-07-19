//
//  ApplicationDelegate.h
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

#import <Cocoa/Cocoa.h>
#import "About.h"
#import "Hollerith.h"
#import "NC.h"
#import "NECEngines.h"
#import "NECOutput.h"
#import "GlobalContext.h"
#import "RunInfo.h"
#import "Spreadsheet.h"

@interface ApplicationDelegate : NSObject <NSFileManagerDelegate> {
    
    IBOutlet id sharedGlobals ;
    IBOutlet id errorView ;
    
    IBOutlet id saveMenuItem ;
    IBOutlet id saveAsMenuItem ;
    IBOutlet id writeDeckMenuItem ;
    IBOutlet id printViewMenuItem ;
    
    IBOutlet id recentModel ;
    IBOutlet id recentHollerith ;
    IBOutlet id recentNC ;

    //  Model Menu Items
    IBOutlet id modelMenu ;
    IBOutlet id viewAsNumbers ;
    
    //  NC Menu Items
    IBOutlet id ncMenu ;
    
    //	Output Polarization Menu Items
    IBOutlet id polMenu1 ;
    IBOutlet id polMenu2 ;
    IBOutlet id polMenu3 ;
    IBOutlet id polMenu4 ;
    IBOutlet id polMenu5 ;
    IBOutlet id polMenu6 ;
    IBOutlet id polMenu7 ;
    
    //  Output Menu Items
    IBOutlet id outputMenu ;
    IBOutlet id animateMenuItem ;
    
    //  0.92 splash screen
    IBOutlet NSPanel *splashWindow ;
    IBOutlet NSTextField *splashVersion ;
    
    
    //	Output viewer
    NECOutput *output ;

    //  Preferences
    //IBOutlet id prefWindow ;
    IBOutlet id engineRadioButtons ;
    IBOutlet NSButton *useGN2Checkbox ;		//  v0.80
    NSMutableDictionary *plist ;
    int engineType ;
    NSString *windowPosition ;
    
    About *about ;
    int documentNumber ;

    int selectedMode ;						// kSpreadsheetMode, kHollerithMode, kNC
    
    Boolean enabled3d ;						// v0.61
    
    NSMutableArray *spreadsheets ;
    Spreadsheet *currentSpreadsheet ;

    NSMutableArray *hollerithDecks ;
    Hollerith *currentHollerith ;

    NSMutableArray *ncFiles ;
    NC *currentNC ;
    NCSystem *currentNCSystem ;
    
    RunInfo runInfo ;						//  note: this value is transcient. Data should be saved if needed before the next run.
            
    NSMutableArray *visitedFiles ;
    Boolean hasError ;
    NSString *defaultDirectory ;
    
    NSColor *currentMagnitude[256], *currentMagnitudeWithPhase[256*64] ;
    
}

@property (strong) IBOutlet NSWindow *prefWindow ;
@property (strong) IBOutlet NSPanel *errorPanel ;


- (RunInfo*)runNECEngine:(NSString*)inputPath output:(NSString*)outputPath sourcePath:(NSString*)sourcePath useQuad:(Boolean)useQuad ;
- (void)displayNECOutput:(NSString*)name hollerith:(NSString*)hollerith lpt:(NSString*)lpt source:(NSString*)source exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result ;  //  v0.81d

- (IBAction)showAbout:(id)sender ;
- (IBAction)showPrefs:(id)sender ;

- (IBAction)newModel:(id)sender ;
- (IBAction)openModel:(id)sender ;
- (IBAction)save:(id)sender ;
- (IBAction)saveAs:(id)sender ;
- (IBAction)duplicateModel:(id)sender ;
- (IBAction)runModel:(id)sender ;

- (IBAction)openNEC4output:(id)sender ;
- (IBAction)openNEC2Coutput:(id)sender ;

- (IBAction)openHollerith:(id)sender ;
- (IBAction)saveHollerith:(id)sender ;

- (IBAction)newNCModel:(id)sender ;
- (IBAction)openNCModel:(id)sender ;
- (IBAction)openNCWindows:(id)sender ;
- (IBAction)executeNC:(id)sender ;

- (IBAction)viewAsFormula:(NSMenuItem*)sender ;

- (IBAction)importEZ:(id)sender ;

- (IBAction)setAsReference:(id)sender ;
- (IBAction)setRunAsReference:(id)sender ;
- (IBAction)removeReference:(id)sender ;
- (IBAction)enable3D:(id)sender ;
- (IBAction)polarizationChanged:(NSMenuItem*)sender ;

- (IBAction)print:(id)sender ;

- (IBAction)openOutputViewer:(id)sender ;
- (IBAction)openElementInspector:(id)sender ;
- (NECOutput*)output ;
- (void)setPolarizationMenu:(intType)pol ;

- (NSString*)defaultDirectory ;
- (void)setDefaultDirectory:(NSString*)str ;

- (void)openModelAtPath:(NSString*)path includeInRecent:(Boolean)include ;
- (void)openHollerithAtPath:(NSString*)path ;
- (void)openNCModelAtPath:(NSString*)path ;

- (void)hollerithBecameKey:(Hollerith*)which ;
- (void)hollerithClosing:(Hollerith*)which ;

- (void)spreadsheetBecameKey:(Spreadsheet*)which ;
- (void)spreadsheetClosing:(Spreadsheet*)which ;

- (void)ncBecameKey:(NC*)which ;
- (void)ncClosing:(NC*)which ;

- (void)clearError ;
- (void)insertError:(NSString*)errString ;
- (Boolean)hasError ;
- (Boolean)showError ;

- (NSColor**)colorForMagnitude ;
- (NSColor**)colorForMagnitudeAndPhase ;

- (Boolean)enabled3d ;						//  v0.61

//  v0.55
- (Spreadsheet*)currentSpreadsheet ;
- (NSArray*)transformStringsForTransform:(NSString*)name ;
- (int)intValueForObject:(NSObject*)object ;
- (double)doubleValueForObject:(NSObject*)object ;

- (NC*)currentNC ;
- (void)setCurrentNC:(NC*)nc ;

- (NCSystem*)currentNCSystem ;
- (void)setCurrentNCSystem:(NCSystem*)sys ;

//  Prefs
- (int)engine ;			// 	knec2cEngine, kNEC4Engine, ...

//  window positions
- (NSString*)windowPosition ;
- (void)setWindowPosition:(NSString*)position ;

- (RunInfo*)runInfo ;
- (void)setDirectivity:(double)value ;

//  helps
- (IBAction)ncFunctions:(id)sender ;
- (IBAction)ncExtensions:(id)sender ;
- (IBAction)ncRefManual:(id)sender ;
- (IBAction)ncTutorial:(id)sender ;
- (IBAction)spreadsheetRefManual:(id)sender ;
- (IBAction)spreadsheetTutorial:(id)sender ;
- (IBAction)openRefManual:(id)sender ;
- (IBAction)openIndex:(id)sender ;					//	v0.75d
- (IBAction)checkForUpdate:(id)sender ;				//  v0.55



- (void)updatePrefs ;

#define	kHollerithMode			0
#define	kSpreadsheetMode		1
#define	kNCMode					2

#define	kEngineNotFound			( -43 ) 

    
#define	RUNNCINSEPARATETHREAD

@end
