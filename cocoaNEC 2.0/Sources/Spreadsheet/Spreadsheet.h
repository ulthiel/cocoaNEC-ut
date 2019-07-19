//
//  Spreadsheet.h
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


#import "GlobalContext.h"
#import "OutputControl.h"
#import "RuntimeStack.h"
#import "Expression.h"
#import "Transforms.h"

@class ElementGeometry ;
@class WireGeometry ;
@class NCForSpreadsheet ;


@interface Spreadsheet : NSObject <NSComboBoxDataSource, NSTextDelegate, NSWindowDelegate> {
    
    IBOutlet id window ;
    IBOutlet id progressIndicator ;
    
    IBOutlet id networks ;
    IBOutlet id variables ;
    IBOutlet id transforms ;
    IBOutlet id environment ;
    IBOutlet id ncView ;
    IBOutlet id cardView ;
    IBOutlet id tabView ;

    IBOutlet id formulaTitle ;
    IBOutlet id formulaBar ;
    IBOutlet id table ;
    IBOutlet id conversionMenu ;
    IBOutlet id geometryMenu ;
            
    GlobalContext *globals ;
    int documentNumber ;
    Boolean untitled ;
    
    OutputControl *outputControl ;
    
    NSMutableArray *wireArray ;
    NSMutableArray *exceptions ;
    NSMutableArray *plist ;
    NSString *sourcePath ;

    NSText *formulaFieldEditor ;
    int selectedRow ;
    NSTableColumn *selectedColumn ;
    NSTableColumn *numberColumn ;
    NSTableColumn *x1Column ;
    NSTableColumn *y1Column ;
    NSTableColumn *z1Column ;
    NSTableColumn *x2Column ;
    NSTableColumn *y2Column ;
    NSTableColumn *z2Column ;
    NSTableColumn *diamColumn ;
    NSTableColumn *segmentsColumn ;
    NSTableColumn *transformColumn ;
    NSTableColumn *ignoreColumn ;
    NSTableColumn *nameColumn ;
    NSTableColumn *commentColumn ;
    
    //  v0.55
    NCForSpreadsheet *nc ; 
    RuntimeStack stack ;
    NSMutableString *code ;
    TransformStruct transformStruct ;
    
    //  metric, formula/eval etc
    intType conversionType ;
    Boolean viewAsFormulas ;
    
    NSString *errorString ;
    
    FILE *writefd ;
    int cards ;
    int hollerithState ;
    
    Boolean dirty ;
    NSArray *retainedNibObjects ;
}

- (id)initWithGlobals:(GlobalContext*)glob number:(int)num untitled:(Boolean)isUntitled ;

- (void)setSourcePath:(NSString*)path ;
- (Boolean)untitled ;

- (void)setDirty ;

- (void)outputCard:(NSString*)image ;

- (IBAction)addGeometryCard:(NSButton*)sender ;	
- (IBAction)removeGeometryCard:(id)sender ;

- (IBAction)openEnvironment:(id)sender ;
- (IBAction)openNetworksPanel:(id)sender ;
- (IBAction)openVariablesPanel:(id)sender ;
- (IBAction)openTransformsPanel:(id)sender ;
- (IBAction)openOutputControl:(id)sender ;
- (IBAction)openNC:(id)sender ;

- (IBAction)runButtonPushed:(id)sender ;

- (void)conversionSelected ;
- (void)dictionaryChanged ;

- (ElementGeometry*)wireForName:(NSString*)name ;

- (void)becomeKeyWindow ;
- (void)hideWindow ;
- (void)showWindow ;
- (Boolean)windowCanClose ;

- (void)inspectGeometryElement ;

- (Boolean)viewAsFormulas ;
- (void)setViewAsFormulas:(Boolean)state ;

- (Boolean)editTableColumn:(NSTableColumn*)tableColumn row:(int)row ;

//  speadsheet created from file
- (void)updateFromPlist:(NSDictionary*)plist name:(NSString*)name ;

- (NSString*)interpretSpreadsheetCell:(NSString*)formula conversion:(int)conversionMethod ;
- (EvalResult)evaluateFormula:(NSString*)formula ;
- (int)intValueForObject:(id)object ;
- (double)doubleValueForObject:(id)object ;

- (NSString*)save:(Boolean)ask ;
- (void)saveToPath:(NSString*)plistPath ;
- (void)saveToHollerith ;
- (NSString*)title ;
- (void)setTitle:(NSString*)title ;

//	v0.55
- (NSArray*)transformStringsForTransform:(NSString*)name ;
- (void)setProgress:(Boolean)state ;
    
#define	conversionMETRIC		0
#define	conversionENGLISH		1
#define	conversionMIXEDENGLISH	2
#define	conversionWAVELENGTH	3

#define	conversionNormal		0
#define	conversionInteger		1
#define	conversionReal			2			// v0.55

@end
