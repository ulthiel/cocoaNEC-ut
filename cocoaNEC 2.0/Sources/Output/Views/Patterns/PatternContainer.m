//
//  PatternContainer.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/19/11.
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

#import "PatternContainer.h"
#import "NECOutput.h"

@implementation PatternContainer

//	Container view that includes a PatternView and a PatternAuxView

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	AuxPatternView *auxView ;
	float viewOffset, auxHeight ;
	
	if ( patternView == nil || footer == nil ) return NO ;
	auxView = [ self auxView ] ;
	if ( auxView == nil ) return NO ;
	
	if ( [ output drawFilenames ] ) {
		viewOffset = FILENAMEOFFSET ;
		[ self setOutput:output ] ;		//  to get printFooter callback from view's drawRect
	}
	else {
		viewOffset = 2 ;
		[ self setOutput:nil ] ;
	}
	auxHeight = 52 ;
	[ self setFrame:NSMakeRect( 0, 0, 600., 600.+( auxHeight+1 )+viewOffset ) ] ;
	[ patternView setFrame:NSMakeRect( 0, ( auxHeight+1 )+viewOffset, 600., 600. ) ] ;
	[ auxView setFrame:NSMakeRect( 0, viewOffset, 600., auxHeight ) ] ;
	[ auxView setOffScreenType:YES ] ;
	[ footer setFrame:NSMakeRect( 0, 0, 600., viewOffset ) ] ;
	
	[ printInfo setHorizontalPagination:NSFitPagination ] ;
	[ printInfo setVerticalPagination:NSClipPagination ] ;
	return YES ;
}

- (PatternView*)patternView 
{
	return patternView ;
}

- (AuxPatternView*)auxView
{
	if ( patternView == nil ) return nil ;
	return [ patternView auxView ] ;
}

//	pass colors on to patternview
- (void)updateColorsFromColorWells:(ColorWells*)wells
{
	[ patternView updateColorsFromColorWells:wells ] ;
}

//	pass color on to patternview
- (void)changeColor:(NSColorWell*)well
{
	[ patternView changeColor:well ] ;
}

//	pass data on to patternview
- (void)updatePatternWithArray:(NSArray*)array refArray:(NSArray*)ref prevArray:(NSArray*)prev
{
	[ patternView updatePatternWithArray:array refArray:ref prevArray:prev ] ;
}

//  clear all pattern arrays
- (void)clearPatterns
{
	[ patternView updatePatternWithArray:nil refArray:nil prevArray:nil ] ;
}

@end
