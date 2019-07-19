//
//  OutputGeometryElement.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/1/07.
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


#import "OutputGeometryElement.h"


@implementation OutputGeometryElement

- (Boolean)parseGeometry:(char*)string
{
	int seg ;
	
	if ( strlen( string ) < 16 ) return NO ;
	
	seg = 0 ;
	sscanf( string, "%d %d %f %f %f %f %f %f %f %f", &seg, &g.tag, &g.coord.x, &g.coord.y, &g.coord.z, &g.length, &g.real, &g.imag, &g.mag, &g.phase ) ;
	if ( seg == 0 ) return NO ;
	g.segment = seg ;
	g.length = fabs( g.length ) ;

	return YES ;
}


- (id)initWithLine:(char*)string
{
	self = [ super init ] ;
	if ( self ) {
		if ( ![ self parseGeometry:string ] ) {
			[ self autorelease ] ;
			return nil ;
		}
	}
	return self ;
}

//  Mutable
- (GeometryInfo*)info
{
	return &g ;
}

- (int)tag
{
	return g.tag ;
}

- (NSComparisonResult)compareZ:(OutputGeometryElement*)cpr
{
	GeometryInfo *info ;
	
	info = [ cpr info ] ;
	if ( g.coord.w < info->coord.w ) return NSOrderedAscending ;
	if ( g.coord.w == info->coord.w ) return NSOrderedSame ;
	return NSOrderedDescending ;
}

@end
