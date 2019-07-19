//
//  NC.h
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


#import <Cocoa/Cocoa.h>
#import "NCBase.h"


@interface NC : NCBase <NSTableViewDataSource, NSWindowDelegate> {
	IBOutlet id window ;
	IBOutlet id textView ;
	IBOutlet id listView ;
	IBOutlet id outputView ;
	IBOutlet id cardsTable ;		// hollertith cards
	IBOutlet id ncTab ;
	
	IBOutlet id runButton ;
	IBOutlet id stopButton ;
	IBOutlet id progressIndicator ;
    
    NSString *sourceString ;        //  v0.92
	
	//  autoindent
	NSString *newstring ;
	
	Boolean untitled ;
	Boolean dirty ;
    
    NSArray *retainedNibObjects ;
}

- (id)initWithDocumentNumber:(int)number untitled:(Boolean)isUntitled ;
- (NSString*)windowPosition ;

- (IBAction)run:(id)sender ;	
- (void)stop ;	

- (void)updateFromPath:(NSString*)path ;
- (NSString*)save:(Boolean)ask ;

- (void)becomeKeyWindow ;
- (void)setWindowPosition:(NSString*)pos ;
- (Boolean)windowCanClose ;

- (NECInfo*)necResults ;

- (void)appendToOutputView:(NSString*)str ;
- (void)saveToHollerith ;

- (NSString*)title ;
- (void)setTitle:(NSString*)title ;

- (int)documentNumber ;
- (Boolean)untitled ;


@end
