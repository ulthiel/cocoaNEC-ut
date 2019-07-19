//
//  NECOutput.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/21/07.
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
#import "GeometryContainer.h"
#import "LineprinterContainer.h"
#import "OutputTypes.h"
#import "Pattern3dContainer.h"
#import "PatternContainer.h"
#import "RunInfo.h"
#import "ScalarContainer.h"
#import "SummaryContainer.h"
#import "SWRContainer.h"
#import "WireCurrent.h"


@class OutputContext ;
@class AzimuthView ;
@class ElevationView ;
@class GeometryView ;
@class ScalarView ;

@interface NECOutput : NSObject <NSComboBoxDataSource> {

	IBOutlet id window ;
	IBOutlet NSSegmentedControl *segmentedMenu ;			//  v0.70
	IBOutlet id modelList ;									//  array of OutputContext
	IBOutlet id cardsTable ;								//  hollertith cards
	IBOutlet SWRView *swrView ;
	IBOutlet ScalarView *scalarView ;
	IBOutlet AzimuthView *azimuthView ;
	IBOutlet ElevationView *elevationView ;
	IBOutlet Pattern3dView *pattern3DView ;
	IBOutlet GeometryView *geometryView ;
	IBOutlet WireCurrent *wireCurrent ;						//  v0.81e
	IBOutlet AzimuthView *summaryAzimuth ;
	IBOutlet ElevationView *summaryElevation ;
	IBOutlet id listing ;
	IBOutlet id summary ;
	IBOutlet id summaryBox ;
	
	//  v0.70 separate wiew (with fixed text view)for printing
	IBOutlet SummaryContainer *summaryContainer ;
	IBOutlet Pattern3dContainer *pattern3dContainer ;
	IBOutlet PatternContainer *azimuthContainer ;
	IBOutlet PatternContainer *elevationContainer ;
	IBOutlet SWRContainer *swrContainer ;
	IBOutlet GeometryContainer *geometryContainer ;
	IBOutlet LineprinterContainer *lineprinterContainer ;
	IBOutlet ScalarContainer *scalarContainer ;
	NSDictionary *smallFontAttributes ;
	NSDictionary *mediumFontAttributes ;

	IBOutlet id tabMenu ;
	IBOutlet id referenceFlag ;
	//  geometry
	IBOutlet id currentsMenu ;
	IBOutlet id elevationField ;
	IBOutlet id elevationStepper ;
	IBOutlet id azimuthField ;
	IBOutlet id azimuthStepper ;
	IBOutlet id zoomSlider ;
	IBOutlet id centerButton ;
	//  3-d
	IBOutlet id azimuth3dField ;
	IBOutlet id azimuth3dStepper ;
	IBOutlet id contrast3dSlider ;
	IBOutlet id phongMatrix ;
	
	//  options drawer
	IBOutlet NSDrawer *optionsDrawer ;
	IBOutlet id gainScaleMatrix ;
	IBOutlet id gainPolarizationMatrix ;
	IBOutlet NSTextField *Z0 ;
	IBOutlet NSTextField *swrCircle ;
	IBOutlet id drawRadialsCheckbox ;
	IBOutlet id drawDistributedLoadsCheckbox ;		//  v0.81d
	IBOutlet id drawBordersCheckbox ;
	IBOutlet id drawBackgroundsCheckbox ;
	IBOutlet id drawFilenamesCheckbox ;
	
	//  v0.70 antenna pattern colors
	//  note: cannot make NSColorWell into NSMatrix
	IBOutlet NSWindow *colorWindow ;
	IBOutlet NSColorWell *colorWell0 ;
	IBOutlet NSColorWell *colorWell1 ;
	IBOutlet NSColorWell *colorWell2 ;
	IBOutlet NSColorWell *colorWell3 ;
	IBOutlet NSColorWell *colorWell4 ;
	IBOutlet NSColorWell *colorWell5 ;
	IBOutlet NSColorWell *colorWell6 ;
	IBOutlet NSColorWell *colorWell7 ;
	IBOutlet NSColorWell *colorWell8 ;
	IBOutlet NSColorWell *colorWell9 ;
	IBOutlet NSColorWell *colorWell10 ;
	IBOutlet NSColorWell *colorWell11 ;
	IBOutlet NSColorWell *colorWell12 ;
	IBOutlet NSColorWell *colorWell13 ;
	IBOutlet NSColorWell *colorWell14 ;
	IBOutlet NSColorWell *colorWell15 ;
	ColorWells colorWells ;
	
	//	v0.81d Drawing Options
	GeometryOptions geometryOptions ;

	//  output contexts
	NSMutableArray *contexts ;
	OutputContext *currentContext ;
	intType defaultContextIndex ;
	OutputContext *referenceContext ;
	Boolean usePreviousPatternAsReference ;
	NSTableColumn *hollerithCardColumn ;
	
	NSString *savedListing ;
    NSArray *retainedNibObjects ;
}

- (IBAction)removeContext:(id)sender ;	
- (IBAction)openOptions:(id)sender ;	
- (IBAction)openColorOptions:(id)sender ;	

- (void)openWindow ;

- (void)newOutputFor:(NSString*)name hollerith:(NSString*)hollerith lpt:(NSString*)lpt source:(NSString*)source exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result ;  //  v0.81d
- (void)newNEC4OutputFor:(NSString*)name lpt:(NSString*)lpt exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result ;	//  v0.81d
- (void)newNEC2COutputFor:(NSString*)name lpt:(NSString*)lpt exceptions:(NSArray*)exceptions resetContext:(Boolean)resetContext result:(RunInfo*)result ;	//  v0.81d

- (Boolean)hasModel ;
- (void)useAsReference ;
- (void)usePreviousRunAsReference ;
- (void)removeCurrentReference ;
- (void)refreshGeometry ;
- (void)showRecenterButton ;
- (void)polarizationChanged:(intType)mode ;

- (const char*)filename ;

- (IBAction)printView:sender ;

- (SWRView*)swrView ;
- (Pattern3dView*)pattern3dView ;
- (ScalarView*)scalarView ;
- (NSString*)savedListing ;

//	v0.70
- (void)savePrefsToPlist:(NSMutableDictionary*)plist ;
- (void)updatePrefsFromDict:(NSDictionary*)plist ;
- (Boolean)drawBorders ;
- (Boolean)drawBackgrounds ;
- (Boolean)drawFilenames ;
- (NSDictionary*)smallFontAttributes ;
- (NSDictionary*)mediumFontAttributes ;

//	v0.78
- (OutputContext*)currentContext ;	

#define	kAzimuthTab		1
#define	kElevationTab	2
#define	k3DTab			3
#define	kSWRTab			4
#define	kScalarTab		5
#define	kGeometryTab	6
#define	kSummaryID		7
#define	kCardsTab		8
#define	kNECListTab		9



@end
