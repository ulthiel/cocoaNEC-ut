//
//  StructureImpedance.m
//  cocoaNEC
//
//  Created by Kok Chen on 4/16/08.
//	-----------------------------------------------------------------------------
//  Copyright 2008-2016 Kok Chen, W7AY. 
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

#import "StructureImpedance.h"


@implementation StructureImpedance

- (Boolean)parseStructure:(char*)string
{
	int tag, from, to ;
	char *types ;
	
	if ( strlen( string ) < 16 ) return NO ;
	tag = -1 ;
	sscanf( string, "%d %d %d", &tag, &from, &to ) ;
	if ( tag < 0 ) return NO ;
	
	g.tag = tag ;
	types = &string[91] ;
	g.segment = from ;
	if ( strncmp( types, "FIXED IMPEDANCE", 15 ) == 0 ) g.type = FIXEDIMPEDANCE ;
	else if ( strncmp( types, "  WIRE  ", 8 ) == 0 ) g.type = LOADEDWIRE ;
	else if ( strncmp( types, "PARALLEL (PER METER)", 20 ) == 0 ) g.type = DISTRIBUTEDPARALLEL ;
	else if ( strncmp( types, "PARALLEL", 8 ) == 0 ) g.type = PARALLEL ;
	else if ( strncmp( types, "SERIES (PER METER)", 18 ) == 0 ) g.type = DISTRIBUTEDSERIES ;
	else if ( strncmp( types, "SERIES", 6 ) == 0 ) g.type = SERIES ;
	
	return YES ;
}

- (id)initWithLine:(char*)string
{
	self = [ super init ] ;
	if ( self ) {
		if ( ![ self parseStructure:string ] ) {
			[ self autorelease ] ;
			return nil ;
		}
	}
	return self ;
}

- (LoadInfo*)info
{
	return &g ;
}

- (int)tag
{
	return g.tag ;
}

@end
