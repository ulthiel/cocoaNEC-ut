//
//  CallStringForNC.m
//  cocoaNEC
//
//  Created by Kok Chen on 6/17/09.
//	-----------------------------------------------------------------------------
//  Copyright 2009-2016 Kok Chen, W7AY. 
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

#import "CallStringForNC.h"
#import "ApplicationDelegate.h"

//	v0.55  NSMutableString with addition of "vect(*,*,*)" and "arg1,arg2,..."

@implementation NSMutableString (CallStringForNC)

- (void)addVect:(NSMatrix*)matrix addition:(NSString*)tail
{
	int i ;
	
	[ self appendString:@"vect(" ] ;
	for ( i = 0; i < 3; i++ ) {
		[ self appendString:[ [ matrix cellAtRow:i column:0 ] stringValue ] ] ;
		if ( i < 2 ) [ self appendString:@"," ] ;
	}
	[ self appendString:@")" ] ;
	if ( tail ) [ self appendString:tail ] ;
}

- (void)appendTransform:(NSString*)transformName addition:(NSString*)tail
{
	int i ;
	NSArray *transformStrings ;

	transformStrings = [ [ NSApp delegate ] transformStringsForTransform:transformName ] ;
	for ( i = 0; i < 6; i++ ) {
		[ self appendString:[ transformStrings objectAtIndex:i ] ] ;
		if ( i < 5 ) [ self appendString:@"," ] ;
	}
	if ( tail ) [ self appendString:tail ] ;
}

- (void)appendArguments:(NSMatrix*)matrix count:(int)args addition:(NSString*)tail
{
	int i ;
	NSString *string ;
	
	for ( i = 0; i < args; i++ ) {
		string = [ [ matrix cellAtRow:i column:0 ] stringValue ] ;
		if ( string == nil || [ string isEqualToString:@"" ] ) string = @"0.0" ;
		[ self appendString:string ] ;
		if ( i < args-1 ) [ self appendString:@"," ] ;
	}
	if ( tail ) [ self appendString:tail ] ;
}

//	argument has a -stringValue method
- (void)appendArgument:(id)field addition:(NSString*)tail
{
	[ self appendString:[ field stringValue ] ] ;
	if ( tail ) [ self appendString:tail ] ;
}

@end
