//
//  PrintScalarView.m
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

#import "PrintScalarView.h"


@implementation PrintScalarView


- (id)initWithFrame:(NSRect)rect
{
	self = [ super initWithFrame:rect ] ;
	if ( self ) {
		isScreen = NO ;
	}
	return self ;
}

- (void)awakeFromNib
{
	[ plotTypeMenu selectItemAtIndex:0 ] ;		//  choose RX
	scalarType = 0 ;
	[ self setRXScaleMenu ] ;
	[ self setScrollOffset:scalarScrollerLocation[ scalarType ] ] ;
}



@end
