//
//  SummaryContainer.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/20/11.
//	-----------------------------------------------------------------------------
//  Copyright 2011-2016 Kok Chen, W7AY. 
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

#import "PrintContainer.h"
#import "AzimuthView.h"
#import "ElevationView.h"


@interface SummaryContainer : PrintContainer {
	IBOutlet NSTextView *textView ;
	IBOutlet AzimuthView *azimuth ;				//  embedded
	IBOutlet ElevationView *elevation ;			//  embedded
}

- (PatternView*)azimuthPattern ;
- (PatternView*)elevationPattern ;
- (NSTextView*)textView ;

- (void)clearText ;
- (void)appendText:(NSString*)string ;

- (void)updateAzimuthPatternWithArray:(NSArray*)array refArray:(NSArray*)ref prevArray:(NSArray*)prev ;
- (void)updateElevationPatternWithArray:(NSArray*)array refArray:(NSArray*)ref prevArray:(NSArray*)prev ;

@end
