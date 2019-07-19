//
//  TransmissionLine.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/13/07.
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

#import "TransmissionLine.h"
#import "ElementGeometry.h"

@implementation TransmissionLine

- (const char*)admitString:(id)cell
{
	NSString *s ;
	
	s = [ cell stringValue ] ;
	if ( s == nil || [ s length ] == 0 ) return "0" ;
	return [ s UTF8String ] ;
}

- (Boolean)ncCode:(NSMutableString*)code eval:(Spreadsheet*)client networkRow:(int)row
{
	int seg1, seg2, index1, index2 ;
	Boolean crossed ;
	
	spreadsheet = client ;
	networkRow = row ;
	
	//  first get the two wire ends
	ElementGeometry *wire1 = [ self getElementGeometry:from row:row type:"Transmission line" ] ;
	if ( !wire1 ) return NO ;	
	seg1 = [ self segmentNumberForWire:wire1 matrix:ntLocation1Matrix segmentField:ntLocation1Segment ] ;
	index1 = [ wire1 elementIndex ] ;

	ElementGeometry *wire2 = [ self getElementGeometry:to row:row type:"Transmission line" ] ;
	if ( !wire2 ) return NO ;
	seg2 = [ self segmentNumberForWire:wire2 matrix:ntLocation2Matrix segmentField:ntLocation2Segment ] ;
	index2 = [ wire2 elementIndex ] ;
	
	crossed = ( [ tlCrossedButton state ] == NSOnState ) ;
	
	[ code appendFormat:@"transmissionLineAtSegments(_e%d,%d,_e%d,%d,", index1, seg1, index2, seg2 ] ;				// e1, seg1, e2, seg2,
	if ( crossed ) {
		[ code appendFormat:@"-(%s),", [ [ [ tlMatrix cellAtRow:0 column:0 ] stringValue ] UTF8String ] ] ;			// -z0
	}
	else {
		[ code appendFormat:@"%s,", [ [ [ tlMatrix cellAtRow:0 column:0 ] stringValue ] UTF8String ] ] ;			// z0
	}
	[ code appendFormat:@"%s) ;", [ [ [ tlMatrix cellAtRow:1 column:0 ] stringValue ] UTF8String ] ] ;				// length		terminate v0.85
	
	//	remove v0.85
	//for ( i = 0; i < 2; i++ ) {
	//	[ code appendFormat:@"%s,", [ self admitString:[ tlAdmittance1Matrix cellAtRow:i column:0 ] ] ] ;			// y1r, y1i
	//}	
	//[ code appendFormat:@"%s,", [ self admitString:[ tlAdmittance2Matrix cellAtRow:0 column:0 ] ] ] ;				// y2r
	//[ code appendFormat:@"%s);\n", [ self admitString:[ tlAdmittance2Matrix cellAtRow:1 column:0 ] ] ] ;			// y2r

	return YES ;
}

- (NSString*)networkCard:(Expression*)e spreadsheet:(Spreadsheet*)client networkRow:(int)row
{
	intType seg1, seg2, tag1, tag2 ;
	const char *mho1real, *mho1imag, *mho2real, *mho2imag, *z0, *length ;
	
		printf( "TransmissionLine: networkCard: called\n" ) ;

	spreadsheet = client ;
	networkRow = row ;
	
	//  first get the two wire ends
	ElementGeometry *wire1 = [ self getElementGeometry:from row:row type:"Transmission Line" ] ;
	if ( !wire1 ) return @"" ;
	tag1 = [ wire1 tag ] ;
	seg1 = [ self segmentNumberForWire:wire1 matrix:tlLocation1Matrix segmentField:tlLocation1Segment ] ;
	mho1real = [ self evalDoubleAsString:tlAdmittance1Matrix row:0 cellName:"transmission line port 1 admittance" ] ;
	mho1imag = [ self evalDoubleAsString:tlAdmittance1Matrix row:1 cellName:"transmission line port 1 admittance" ] ;

	ElementGeometry *wire2 = [ self getElementGeometry:to row:row type:"Transmission Line" ] ;
	if ( !wire2 ) return @"" ;
	tag2 = [ wire2 tag ] ;
	seg2 = [ self segmentNumberForWire:wire2 matrix:tlLocation2Matrix segmentField:tlLocation2Segment ] ;
	mho2real = [ self evalDoubleAsString:tlAdmittance2Matrix row:0 cellName:"transmission line port 2 admittance" ] ;
	mho2imag = [ self evalDoubleAsString:tlAdmittance2Matrix row:1 cellName:"transmission line port 2 admittance" ] ;
	
	z0 = [ self evalDoubleAsString:tlMatrix row:0 cellName:"transmission line Z0" negate:( [ tlCrossedButton state ] == NSOnState ) ] ;
	length = [ self evalDoubleAsString:tlMatrix row:1 cellName:"transmission line length" ] ;
	
	//  v0.86
    return [ NSString stringWithFormat:[ Config format:"TL%3d%5d%5d%5d%10s%10s%10s%10s%10s%10s" ],
            tag1, seg1, tag2, seg2, z0, length, mho1real, mho1imag, mho2real, mho2imag ] ;
}

- (NSMutableDictionary*)makePlistDictionary
{
	NSMutableDictionary *plist ;
	
	plist = [ [ NSMutableDictionary alloc ] init ] ;	
	[ plist setValue:@"TL" forKey:@"type" ] ;
	[ plist setValue:( from ) ? from : @"" forKey:@"from" ] ;
	[ plist setValue:( to ) ? to : @"" forKey:@"to" ] ;
	[ plist setValue:( comment ) ? comment : @"" forKey:@"comment" ] ;
	[ plist setValue:[ NSNumber numberWithLong:[ tlLocation1Matrix selectedRow ] ] forKey:@"matrix1" ] ;
	[ plist setValue:[ NSNumber numberWithLong:[ tlLocation2Matrix selectedRow ] ] forKey:@"matrix2" ] ;
	[ plist setValue:[ tlLocation1Segment stringValue ] forKey:@"segment1" ] ;
	[ plist setValue:[ tlLocation2Segment stringValue ] forKey:@"segment2" ] ;
	[ plist setValue:[ [ tlAdmittance1Matrix cellAtRow:0 column:0 ] stringValue ] forKey:@"admittance1real" ] ;
	[ plist setValue:[ [ tlAdmittance1Matrix cellAtRow:1 column:0 ] stringValue ] forKey:@"admittance1imag" ] ;
	[ plist setValue:[ [ tlAdmittance2Matrix cellAtRow:0 column:0 ] stringValue ] forKey:@"admittance2real" ] ;
	[ plist setValue:[ [ tlAdmittance2Matrix cellAtRow:1 column:0 ] stringValue ] forKey:@"admittance2imag" ] ;
	[ plist setValue:[ [ tlMatrix cellAtRow:0 column:0 ] stringValue ] forKey:@"z0" ] ;
	[ plist setValue:[ [ tlMatrix cellAtRow:1 column:0 ] stringValue ] forKey:@"length" ] ;
	[ plist setValue:[ NSNumber numberWithBool:( [ tlCrossedButton state ] == NSOnState ) ] forKey:@"crossed" ] ;
	return plist ;
}

- (void)restoreFromDictionary:(NSDictionary*)dict
{
	[ self setFrom:[ dict valueForKey:@"from" ] ] ;
	[ self setTo:[ dict valueForKey:@"to" ] ] ;
	[ self setComment:[ dict valueForKey:@"comment" ] ] ;
	
	[ tlLocation1Matrix selectCellAtRow:[ [ dict valueForKey:@"matrix1" ] intValue ] column:0 ] ;
	[ tlLocation2Matrix selectCellAtRow:[ [ dict valueForKey:@"matrix2" ] intValue ] column:0 ] ;
	
	[ tlLocation1Segment setStringValue:[ dict valueForKey:@"segment1" ] ] ;
	[ tlLocation2Segment setStringValue:[ dict valueForKey:@"segment2" ] ] ;
	
	[ [ tlAdmittance1Matrix cellAtRow:0 column:0 ] setStringValue:[ dict valueForKey:@"admittance1real" ] ] ;
	[ [ tlAdmittance1Matrix cellAtRow:1 column:0 ] setStringValue:[ dict valueForKey:@"admittance1imag" ] ] ;
	[ [ tlAdmittance2Matrix cellAtRow:0 column:0 ] setStringValue:[ dict valueForKey:@"admittance2real" ] ] ;
	[ [ tlAdmittance2Matrix cellAtRow:1 column:0 ] setStringValue:[ dict valueForKey:@"admittance2imag" ] ] ;
	[ [ tlMatrix cellAtRow:0 column:0 ] setStringValue:[ dict valueForKey:@"z0" ] ] ;
	[ [ tlMatrix cellAtRow:1 column:0 ] setStringValue:[ dict valueForKey:@"length" ] ] ;
	[ tlCrossedButton setState:( [ [ dict valueForKey:@"crossed" ] boolValue ] ) ? NSOnState : NSOffState ] ;
}

@end
