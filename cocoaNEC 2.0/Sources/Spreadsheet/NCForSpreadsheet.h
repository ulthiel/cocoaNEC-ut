//
//  NCForSpreadsheet.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/16/09.
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

@interface NCForSpreadsheet : NCBase <NSTableViewDataSource> {

	NSString *sourceString ;
	NSTextView *listView ;
	int runStatus ;
}

- (id)initWithListView:(NSTextView*)view cardView:(NSTableView*)cards ;
- (void)runSource:(NSString*)source ;
- (void)createDeck:(NSString*)source ;

@end
