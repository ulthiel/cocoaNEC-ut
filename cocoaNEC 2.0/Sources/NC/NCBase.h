//
//  NCBase.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/15/09.
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
#import "NCCompiler.h"
#import "NCSystem.h"
#import "NECTypes.h"


enum LockCondition {
	kThreadBusy,
	kThreadFree
} ;

#define	MAXLINES	4000


@interface NCBase : NSObject <NSTableViewDataSource> {

	RuntimeStack stack ;

	NCCompiler *compiler ;
	NSConditionLock *runLock ;
	int runModelCount ;					//  v0.81d
	
	NSString *inputPath, *outputPath ;
	NECRadials necRadials ;
	NECInfo necResults ;
	int documentNumber ;
	NSMutableArray *hollerithArray ;
	NSTableColumn *hollerithCardColumn ;
		
	Boolean sendCardToNEC ;
	RunInfo runResult ;
	NSLock *nec2ThreadLock ;
	
	NSTableView *cardsView ;
}

- (void)appendText:(NSString*)string toView:(NSTextView*)view ;
- (void)outputListing:(NC*)client ;
- (void)makeListingViewVisible ;

- (NCSystem*)system ;
- (NCCompiler*)compiler ;
- (NECRadials*)necRadials ;

- (void)setModelFunction:(NCFunctionObject*)model ;
- (void)setSourcePath:(NSString*)path ;

- (void)setProgress:(Boolean)state ;

- (void)copyDeck:(NSArray*)deckArray ;
- (Boolean)outputHollerithToFile:(NSString*)filePath ;			// v0.55

- (Boolean)runModel ;
- (int)runWorkFlowCompile:(Boolean)doCompile execute:(Boolean)doExecute allowLoops:(Boolean)allowLoops runNEC:(Boolean)doRun sourceString:(NSString*)sourceString ;
- (void)processNEC2Output ;

@end
