//
//  ScalarContainer.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/23/11.
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

#import "ScalarContainer.h"
#import "ScalarView.h"


@implementation ScalarContainer

//	Container view that includes a PatternView and a PatternAuxView

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	AuxScalarView *auxView ;
	ScalarView *base ;
	NSRect bounds ;
	float viewOffset, auxHeight, scrollHeight, aspect ;

	if ( view == nil || footer == nil ) return NO ;
	auxView = [ self auxView ] ;
	if ( auxView == nil ) return NO ;
	
	scrollHeight = 514 ;
	base = [ output scalarView ] ;
	if ( base ) {
		bounds = [[  base enclosingScrollView ] bounds ] ;
		aspect = bounds.size.height/bounds.size.width ;
		scrollHeight = (int)( 598*aspect+0.4 ) ;
	}
	if ( [ output drawFilenames ] ) {
		viewOffset = FILENAMEOFFSET ;
		[ self setOutput:output ] ;		//  to get printFooter callback from view's drawRect
	}
	else {
		viewOffset = 2 ;
		[ self setOutput:nil ] ;
	}
	auxHeight = 70 ;
	[ self setFrame:NSMakeRect( 0, 0, 598, scrollHeight+( auxHeight+1 )+viewOffset ) ] ;
	[ [ view enclosingScrollView ] setFrame:NSMakeRect( 0, auxHeight+viewOffset, 598, scrollHeight ) ] ;
	[ auxView setFrame:NSMakeRect( 0, viewOffset, 598, auxHeight ) ] ;
	[ auxView setOffScreenType:YES ] ;
	[ footer setFrame:NSMakeRect( 0, 0, 598, viewOffset ) ] ;
	
	[ printInfo setHorizontalPagination:NSFitPagination ] ;
	[ printInfo setVerticalPagination:NSClipPagination ] ;
	return YES ;
}

- (ScalarView*)scalarView
{
	return view ;
}

- (AuxScalarView*)auxView
{
	if ( view == nil ) return nil ;
	return [ view auxView ] ;
}


@end
