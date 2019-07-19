//
//  Networks.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/13/07.
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

@class Spreadsheet ;
@class Expression ;


@interface Networks : NSObject <NSTableViewDataSource, NSComboBoxDataSource> { 

    IBOutlet id table ;		// table view
    //IBOutlet id window ;

    NSMutableArray *networkArray ;
    NSTableColumn *numberColumn ;
    NSTableColumn *fromColumn ;
    NSTableColumn *typeColumn ;
    NSTableColumn *toColumn ;
    NSTableColumn *commentColumn ;

    NSWindow *controllingWindow ;
}

@property (strong) IBOutlet NSWindow *window ;

- (IBAction)addNetworkElement:(id)sender ;
- (IBAction)removeNetworkElement:(id)sender ;	

- (void)ncCode:(NSMutableString*)code eval:(Spreadsheet*)client ;
- (void)outputCards:(Spreadsheet*)client expression:(Expression*)e ;		//  deprecated

- (IBAction)closeSheet:(id)sender ;
- (void)showSheet:(NSWindow*)controllingWindow ;	

//  save networks
- (NSMutableArray*)makePlistArray ;
- (void)restoreFromArray:(NSArray*)items ;

@end
