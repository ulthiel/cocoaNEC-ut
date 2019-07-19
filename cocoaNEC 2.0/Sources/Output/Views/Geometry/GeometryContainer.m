//
//  GeometryContainer.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/21/11.
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

#import "GeometryContainer.h"
#import "GeometryView.h"
#import "NECOutput.h"


@implementation GeometryContainer

//	Container view that includes a GeometryView
//  Print header is added here

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	float viewOffset ;
	
	if ( geometryView == nil || footer == nil ) return NO ;
	
	if ( [ output drawFilenames ] ) {
		viewOffset = FILENAMEOFFSET ;
		[ self setOutput:output ] ;		//  to get printFooter callback from view's drawRect
	}
	else {
		viewOffset = 2 ;
		[ self setOutput:nil ] ;
	}
	[ self setFrame:NSMakeRect( 0, 0, 600., 601.0+viewOffset ) ] ;
	[ footer setFrame:NSMakeRect( 0, 0, 600., viewOffset ) ] ;
	
	[ printInfo setHorizontalPagination:NSFitPagination ] ;
	[ printInfo setVerticalPagination:NSClipPagination ] ;
	return YES ;
}

- (GeometryView*)geometryView
{
	return geometryView ;
}

@end
