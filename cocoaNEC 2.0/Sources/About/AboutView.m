//
//  AboutView.m
//	-----------------------------------------------------------------------------
//  Copyright 2004-2016 Kok Chen, W7AY. 
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


#import "AboutView.h"
#import "Config.h"

@implementation AboutView

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *background ;
	NSString *version ;
	
	if ( [ self lockFocusIfCanDraw ] ) {
		[ [ NSColor whiteColor ] set ] ;
		background = [ NSBezierPath bezierPathWithRect:[ self bounds ] ] ;
		[ background fill ] ;
		[ self unlockFocus ] ;
	}

	[ super drawRect:rect ] ;
	
	if ( [ self lockFocusIfCanDraw ] ) {
		//  set version string in About panel
		version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
		if ( version ) {
            [ versionString setStringValue:[ NSString stringWithFormat:@"Version %s", [ version UTF8String ] ] ] ;
		}
		[ self unlockFocus ] ;
	}
}

@end
