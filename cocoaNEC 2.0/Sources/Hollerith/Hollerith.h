//
//  Hollerith.h
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


#import <Cocoa/Cocoa.h>
#import "OutputControl.h"

@interface Hollerith : NSObject <NSComboBoxDataSource, NSWindowDelegate> {

    IBOutlet id window ;
    IBOutlet id editField ;
    IBOutlet id table ;
    IBOutlet id metricField ;
    IBOutlet id scale ;
    IBOutlet id positionText ;
    
    OutputControl *outputControl ;
    
    id delegate ;
    intType rows, selectedRow ;
    NSTableColumn *indexColumn, *cardColumn, *ignoreColumn, *noteColumn ;
    NSMutableArray *cards ;

    int documentNumber ;		//  unique document fumber
    NSString *sourcePath ;
    Boolean dirty ;
    
    NSRect origin ;
    float advanceWidth ;
    
    NSArray *retainedNibObjects ;
}

- (id)initWithDocumentNumber:(int)number ;

- (void)setSourcePath:(NSString*)path ;
- (void)updateFromFile:(FILE*)deck name:(NSString*)name ;

- (IBAction)addHollerithCard:(id)sender ;	
- (IBAction)removeHollerithCard:(id)sender ;

- (IBAction)runButtonPushed:(id)sender ;
- (IBAction)openOutputControl:(id)sender ;

- (NSString*)save:(Boolean)ask ;

- (void)hideWindow ;
- (void)showWindow ;
- (void)becomeKeyWindow ;
- (Boolean)windowCanClose ;

- (void)selecting:(int)index ;

@end
