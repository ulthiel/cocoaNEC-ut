//
//  TwoPort.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/12/07.
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
#import "Config.h"
	
@class Expression ;
@class ElementGeometry ;
@class Spreadsheet ;

@interface TwoPort : NSObject <NSFileManagerDelegate> {
    IBOutlet id window ;
    IBOutlet id typeTab ;
    
    //  Transmission line
    IBOutlet id tlLocation1Matrix ;
    IBOutlet id tlLocation1Segment ;
    IBOutlet id tlAdmittance1Matrix ;
    IBOutlet id tlLocation2Matrix ;
    IBOutlet id tlLocation2Segment ;
    IBOutlet id tlAdmittance2Matrix ;
    IBOutlet id tlMatrix ;
    IBOutlet id tlCrossedButton ;
    
    //  Network
    IBOutlet id ntLocation1Matrix ;
    IBOutlet id ntLocation1Segment ;
    IBOutlet id ntLocation2Matrix ;
    IBOutlet id ntLocation2Segment ;
    IBOutlet id ntAdmittanceMatrix ;
    
    id delegate ;
    intType selectedType ;
    Boolean opened ;					// to distingished between closed and hidden
    Boolean ignore ;
    
    Spreadsheet *spreadsheet ;
    int networkRow ;
    NSString *card ;		
    NSString *from, *to, *comment ;
    
    NSArray *retainedNibObjects ;
}

- (id)initWithDelegate:(id)client type:(intType)type ;
- (id)initFromDict:(NSDictionary*)dict delegate:(id)client type:(int)type ;

- (void)openInspector:(id)client ;
- (void)bringToFront ;
- (void)hideWindow ;
- (void)showWindow ;
- (Boolean)opened ;
- (Boolean)ignoreCard ;

- (ElementGeometry*)getElementGeometry:(NSString*)str row:(int)row type:(char*)type ;

- (Boolean)ncCode:(NSMutableString*)code eval:(Spreadsheet*)spreadsheet networkRow:(int)row ;
- (NSString*)networkCard:(Expression*)e spreadsheet:(Spreadsheet*)spreadsheet networkRow:(int)row ;		//  deprecated

- (NSString*)fromField ;
- (void)setFrom:(NSString*)str ;
- (NSString*)typeField ;
- (NSString*)toField ;
- (void)setTo:(NSString*)str ;
- (NSString*)commentField ;
- (void)setComment:(NSString*)str ;
- (NSString*)ignoreField ;
- (void)setIgnore:(NSString*)str ;

- (const char*)evalDoubleAsString:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName ;
- (const char*)evalDoubleAsString:(NSMatrix*)matrix row:(int)row cellName:(char*)cellName negate:(Boolean)negate ;
- (int)segmentNumberForWire:(ElementGeometry*)wire matrix:(NSMatrix*)locationMatrix segmentField:(NSTextField*)segment ;

- (NSMutableDictionary*)makePlistDictionary ;
- (void)restoreFromDictionary:(NSDictionary*)dict ;

#define	NETWORKTYPE				0
#define	TRANSMISSIONLINETYPE	1
#define	OTHERTYPE				2


@end
