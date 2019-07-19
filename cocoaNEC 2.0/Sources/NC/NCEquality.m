//
//  NCEquality.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/19/07.
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

#import "NCEquality.h"
#import "NCRelational.h"


@implementation NCEquality

- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		nodeType = "Equality" ;
	}
	return self ;
}

- (Boolean)parse
{
	token = [ parser token ] ;
	line = [ parser line ] ;
	
	left = [ [ NCRelational alloc ]  initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ left parse ] ) {
		token = [ parser token ] ;
		while ( 1 ) {
			switch ( token ) {
			case LOGICALEQ:
			case LOGICALNE:
				op = token ;
				[ parser nextToken ] ;
				right = [ [ NCRelational alloc ]  initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
				if ( ![ right parse ] ) return NO ;
				type = INTTYPE ;
				break ;
			default:
				type = [ left type ] ;
				lvalue = [ left lvalue ] ;
				op = LOGICALLT ;			// delegate for relational Op
				return YES ;
			}
			token = [ parser token ] ;
			if ( token != LOGICALEQ && token != LOGICALNE ) return YES ;
			left = [ [ NCEquality alloc ] clone:self ] ;
		}
	}
	return NO ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	int leftType, rightType ;
	stack = inStack ;

	switch ( op ) {
	case LOGICALLT:
	case LOGICALLE:
	case LOGICALGT:
	case LOGICALGE:
		if ( left == nil ) return [ NCValue undefinedValue ] ;
		return [ left execute:stack asReference:asReference ] ;
	case LOGICALEQ:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		leftType = [ left type ] ;
		rightType = [ right type ] ;
		if ( leftType == REALTYPE || rightType == REALTYPE ) return [ NCValue valueWithInt:( [ [ left execute:stack asReference:NO ] doubleValue ] == [ [ right execute:stack asReference:NO ] doubleValue ] ) ? 1 : 0 ] ;
		return [ NCValue valueWithInt:( [ [ left execute:stack asReference:NO ] intValue ] == [ [ right execute:stack asReference:NO ] intValue ] ) ? 1 : 0 ] ;
	case LOGICALNE:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		leftType = [ left type ] ;
		rightType = [ right type ] ;
		if ( leftType == REALTYPE || rightType == REALTYPE ) return [ NCValue valueWithInt:( [ [ left execute:stack asReference:NO ] doubleValue ] != [ [ right execute:stack asReference:NO ] doubleValue ] ) ? 1 : 0 ] ;
		return [ NCValue valueWithInt:( [ [ left execute:stack asReference:NO ] intValue ] != [ [ right execute:stack asReference:NO ] intValue ] ) ? 1 : 0 ] ;
	default:
		printf( "NCEquality -execute with unknown op type 0x%x\n", op ) ;
		break ;
	}
	return nil ;
}

//	v0.53
- (NSString*)symbolName
{
	if ( left != nil ) return [ left symbolName ] ;
	return [ super symbolName ] ;
}


@end
