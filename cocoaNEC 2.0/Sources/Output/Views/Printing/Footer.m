//
//  Footer.m
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

#import "Footer.h"
#import "DateFormat.h"
#import "NECOutput.h"

@implementation Footer

- (id)initWithFrame:(NSRect)inFrame
{
	self = [ super initWithFrame:inFrame ] ;
	if ( self ) {
		output = nil ;
	}
	return self ;
}

- (void)setOutput:(NECOutput*)obj
{
	output = obj ;
}

- (void)drawRect:(NSRect)rect
{
	NSMutableDictionary *printAttributes ;
	NSFont *font = [ NSFont fontWithName: @"Helvetica" size:10 ] ;
	float height ;

	if ( output && [ output drawFilenames ] && font != nil ) {
		height = [ self bounds ].size.height ;
		printAttributes = [ [ NSMutableDictionary alloc ] init ] ;
		[ printAttributes setObject:font forKey:NSFontAttributeName ] ;
		[ printAttributes setObject:[ NSColor blackColor ] forKey:NSForegroundColorAttributeName ] ;
		[ [ NSString stringWithFormat:@"%s", [ output filename ] ] drawAtPoint:NSMakePoint( 5, height-20 ) withAttributes:printAttributes ] ;
        
        NSString *dateString = [ DateFormat descriptionWithCalendarFormat:@"EEEE d MMMM YYYY HH:mm" ] ;
        
		[ [ NSString stringWithFormat:@"%s", [ dateString UTF8String ] ] drawAtPoint:NSMakePoint( 5, height-35 ) withAttributes:printAttributes ] ;
		[ printAttributes release ] ;
	}
}

@end
