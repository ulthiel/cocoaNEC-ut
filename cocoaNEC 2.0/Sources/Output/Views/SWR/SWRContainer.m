//
//  SWRContainer.m
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

#import "SWRContainer.h"
#import "AuxSWRView.h"
#import "SWRView.h"
#import "NECOutput.h"

@implementation SWRContainer

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	int i ;
	SWRView *baseSWRView ;
	AuxSWRView *aux ;
	float auxHeight, viewOffset ;
	
	baseSWRView = [ output swrView ] ;
	aux = [ self auxView ] ;
	if ( swrView == nil || aux == nil || footer == nil ) return NO ;
	
	auxHeight = [ aux bounds ].size.height ;
	
	if ( [ output drawFilenames ] ) {
		viewOffset = FILENAMEOFFSET ;
		[ self setOutput:output ] ;		//  to get printFooter callback from view's drawRect
	}
	else {
		viewOffset = 0 ;
		[ self setOutput:nil ] ;
	}
	[ self setFrame:NSMakeRect( 0, 0, 600., 600.+( auxHeight+1 )+viewOffset ) ] ;
	[ swrView setFrame:NSMakeRect( 0, ( auxHeight+1 )+viewOffset, 600., 600. ) ] ;
	[ [ self auxView ] setFrame:NSMakeRect( 0, viewOffset, 600., auxHeight ) ] ;
	[ footer setFrame:NSMakeRect( 0, 0, 600., viewOffset ) ] ;

	//  copy needed data from GUI SWRView to the printing SWRView
	[ swrView setFeedpointForOffscreenView:[ baseSWRView selectedFeedpointFromMenu ] ] ;
	for ( i = 0; i < 16; i++ ) [ swrView setColorWell:i fromColorWell:[ baseSWRView colorWell:i ] ] ;
	[ printInfo setHorizontalPagination:NSFitPagination ] ;
	return YES ;
}

- (SWRView*)swrView
{
	return swrView ;
}

- (AuxSWRView*)auxView
{
	if ( swrView == nil ) return nil ;
	return [ swrView auxView ] ;
}

@end
