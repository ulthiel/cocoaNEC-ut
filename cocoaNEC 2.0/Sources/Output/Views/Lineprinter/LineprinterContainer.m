//
//  LineprinterContainer.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/22/11.
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

#import "LineprinterContainer.h"
#import "NECOutput.h"

@implementation LineprinterContainer

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	NSTextContainer *container ;
	NSString *listing ;
	
	listing = [ output savedListing ] ;
	if ( textView == nil || listing == nil ) return NO ;
	
	[ printInfo setHorizontalPagination:NSFitPagination ] ;
	[ printInfo setHorizontallyCentered:NO ] ;
	[ printInfo setVerticallyCentered:NO ] ;
	
	[ textView setFont:[ NSFont fontWithName: @"Monaco" size:10.0 ] ] ;
	container = [ textView textContainer ] ;
	[ container setContainerSize:NSMakeSize( 700.0, 1e12 ) ] ;		//  multiple pages
 	[ container setHeightTracksTextView:NO ] ;
	[ textView sizeToFit ] ;
	[ textView setString:listing ] ;
	[ textView print:self ] ;			//  print text view, not the container
	return NO ;							//  no need to print from -printWithInfo:Output:
}

@end
