//
//  PrintContainer.m
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
#import "NECOutput.h"

@implementation PrintContainer

- (Boolean)setUpWithPrintInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	return NO ;
}

- (void)printWithInfo:(NSPrintInfo*)printInfo output:(NECOutput*)output
{
	if ( [ self setUpWithPrintInfo:printInfo output:output ] ) [ self print:self ] ;
}

- (Footer*)footer
{
	return footer ;
}

- (void)setOutput:(NECOutput*)control
{
	if ( footer ) [ footer setOutput:control ] ;
}

//	pass colors on to subviews
- (void)updateColorsFromColorWells:(ColorWells*)wells
{
	//  e.g. [ patternView updateColorsFromColorWells:wells ] ;
}

//	pass color on to subviews
- (void)changeColor:(NSColorWell*)well
{
	//  e.g. [ patternView changeColor:well ] ;
}

//  clear all pattern arrays
- (void)clearPatterns
{
}

- (id)initWithFrame:(NSRect)inFrame
{
	self = [ super initWithFrame:inFrame ] ;
	if ( self ) {
		footer = nil ;
	}
	return self ;
}

@end
