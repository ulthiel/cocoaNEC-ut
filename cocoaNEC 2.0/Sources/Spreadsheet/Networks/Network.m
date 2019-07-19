//
//  Network.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/15/07.
//	-----------------------------------------------------------------------------
//  Copyright 2007-2016 Kok Chen, W7AY. 
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

#import "Network.h"
#import "ElementGeometry.h"

@implementation Network

- (Boolean)ncCode:(NSMutableString*)code eval:(Spreadsheet*)client networkRow:(int)row
{
	int i, seg1, seg2, index1, index2 ;
	
	spreadsheet = client ;
	networkRow = row ;
	
	//  first get the two wire ends
	ElementGeometry *wire1 = [ self getElementGeometry:from row:row type:"Two Port Network" ] ;
	if ( !wire1 ) return NO ;	
	seg1 = [ self segmentNumberForWire:wire1 matrix:ntLocation1Matrix segmentField:ntLocation1Segment ] ;
	index1 = [ wire1 elementIndex ] ;

	ElementGeometry *wire2 = [ self getElementGeometry:to row:row type:"Two Port Network" ] ;
	if ( !wire2 ) return NO ;
	seg2 = [ self segmentNumberForWire:wire2 matrix:ntLocation2Matrix segmentField:ntLocation2Segment ] ;
	index2 = [ wire2 elementIndex ] ;
	
	[ code appendFormat:@"networkAtSegments(_e%d,%d,_e%d,%d,", index1, seg1, index2, seg2 ] ;
	for ( i = 0; i < 5; i++ ) {
		[ code appendFormat:@"%s,", [ [ [ ntAdmittanceMatrix cellAtRow:i column:0 ] stringValue ] UTF8String ] ] ;
	}
	[ code appendFormat:@"%s);\n", [ [ [ ntAdmittanceMatrix cellAtRow:5 column:0 ] stringValue ] UTF8String ]  ] ;
	return YES ;
}


- (NSString*)networkCard:(Expression*)e spreadsheet:(Spreadsheet*)client networkRow:(int)row
{
	intType seg1, seg2, tag1, tag2 ;
	const char *y11r, *y11i, *y12r, *y12i, *y22r, *y22i ;
	
	spreadsheet = client ;
	networkRow = row ;
	
	//  first get the two wire ends
	ElementGeometry *wire1 = [ self getElementGeometry:from row:row type:"Two Port Network" ] ;
	if ( !wire1 ) return @"" ;
	tag1 = [ wire1 tag ] ;
	seg1 = [ self segmentNumberForWire:wire1 matrix:ntLocation1Matrix segmentField:ntLocation1Segment ] ;

	ElementGeometry *wire2 = [ self getElementGeometry:to row:row type:"Two Port Network" ] ;
	if ( !wire2 ) return @"" ;
	tag2 = [ wire2 tag ] ;
	seg2 = [ self segmentNumberForWire:wire2 matrix:ntLocation2Matrix segmentField:ntLocation2Segment ] ;
	
	y11r = [ self evalDoubleAsString:ntAdmittanceMatrix row:0 cellName:"Network Y11 (real)" ] ;
	y11i = [ self evalDoubleAsString:ntAdmittanceMatrix row:1 cellName:"Network Y11 (imag)" ] ;
	y12r = [ self evalDoubleAsString:ntAdmittanceMatrix row:2 cellName:"Network Y12 (real)" ] ;
	y12i = [ self evalDoubleAsString:ntAdmittanceMatrix row:3 cellName:"Network Y12 (imag)" ] ;
	y22r = [ self evalDoubleAsString:ntAdmittanceMatrix row:4 cellName:"Network Y22 (real)" ] ;
	y22i = [ self evalDoubleAsString:ntAdmittanceMatrix row:5 cellName:"Network Y22 (imag)" ] ;
	
	//	v0.86
    //  v0.88
    return [ NSString stringWithFormat:[ Config format:"NT%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
            tag1, seg1, tag2, seg2, y11r, y11i, y12r, y12i, y22r, y22i ] ;
}

- (NSMutableDictionary*)makePlistDictionary
{
	NSMutableDictionary *plist ;
	
	plist = [ [ NSMutableDictionary alloc ] init ] ;	
	[ plist setValue:@"NT" forKey:@"type" ] ;
	[ plist setValue:( from ) ? from : @"" forKey:@"from" ] ;
	[ plist setValue:( to ) ? to : @"" forKey:@"to" ] ;
	[ plist setValue:( comment ) ? comment : @"" forKey:@"comment" ] ;
	[ plist setValue:[ NSNumber numberWithLong:[ ntLocation1Matrix selectedRow ] ] forKey:@"matrix1" ] ;
	[ plist setValue:[ NSNumber numberWithLong:[ ntLocation2Matrix selectedRow ] ] forKey:@"matrix2" ] ;
	[ plist setValue:[ ntLocation1Segment stringValue ] forKey:@"segment1" ] ;
	[ plist setValue:[ ntLocation2Segment stringValue ] forKey:@"segment2" ] ;	
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:0 column:0 ] stringValue ] forKey:@"y11r" ] ;
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:1 column:0 ] stringValue ] forKey:@"y11i" ] ;
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:2 column:0 ] stringValue ] forKey:@"y12r" ] ;
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:3 column:0 ] stringValue ] forKey:@"y12i" ] ;
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:4 column:0 ] stringValue ] forKey:@"y22r" ] ;
	[ plist setValue:[ [ ntAdmittanceMatrix cellAtRow:5 column:0 ] stringValue ] forKey:@"y22i" ] ;
	return plist ;
}

- (void)restoreFromDictionary:(NSDictionary*)dict
{
	[ self setFrom:[ dict valueForKey:@"from" ] ] ;
	to = [ dict valueForKey:@"to" ] ;
	comment = [ dict valueForKey:@"comment" ] ;
	
	[ ntLocation1Matrix selectCellAtRow:[ [ dict valueForKey:@"matrix1" ] intValue ] column:0 ] ;
	[ ntLocation2Matrix selectCellAtRow:[ [ dict valueForKey:@"matrix2" ] intValue ] column:0 ] ;

	[ ntLocation1Segment setStringValue:[ dict valueForKey:@"segment1" ] ] ;
	[ ntLocation2Segment setStringValue:[ dict valueForKey:@"segment2" ] ] ;
	
	[ [ ntAdmittanceMatrix cellAtRow:0 column:0 ] setStringValue:[ dict valueForKey:@"y11r" ] ] ;
	[ [ ntAdmittanceMatrix cellAtRow:1 column:0 ] setStringValue:[ dict valueForKey:@"y11i" ] ] ;
	[ [ ntAdmittanceMatrix cellAtRow:2 column:0 ] setStringValue:[ dict valueForKey:@"y12r" ] ] ;
	[ [ ntAdmittanceMatrix cellAtRow:3 column:0 ] setStringValue:[ dict valueForKey:@"y12i" ] ] ;
	[ [ ntAdmittanceMatrix cellAtRow:4 column:0 ] setStringValue:[ dict valueForKey:@"y22r" ] ] ;
	[ [ ntAdmittanceMatrix cellAtRow:5 column:0 ] setStringValue:[ dict valueForKey:@"y22i" ] ] ;
	
	
	
}

@end
