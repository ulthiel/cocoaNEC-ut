//
//  NCAdditive.m
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

#import "NCAdditive.h"
#import "NCMultiplicative.h"


@implementation NCAdditive


- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		nodeType = "Additive" ;
	}
	return self ;
}

- (Boolean)parse
{
	line = [ parser line ] ;
	left = [ [ NCMultiplicative alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ left parse ] ) {
		token = [ parser token ] ;
		while ( 1 ) {
			switch ( token ) {
			case PLUS:
			case MINUS:
				op = token ;
				[ parser nextToken ] ;
				right = [ [ NCMultiplicative alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
				if ( ![ right parse ] ) return NO ;
				type = [ self typeForBinaryOp:left right:right ] ;
				if ( type == 0 ) [ parser setError:@"cannot add or subtract this data type" flush:YES ] ;
				break ;
			default:
				op = MULTIPLICATIVE ;
				token = [ parser token ] ;
				lvalue = [ left lvalue ] ;
				type = [ left type ] ;
				return YES ;
			}
			token = [ parser token ] ;
			if ( token != PLUS && token != MINUS ) return YES ;
			left = [ [ NCAdditive alloc ] clone:self ] ;
		}
	}
	return NO ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	stack = inStack ;

	switch ( op ) {
	case MULTIPLICATIVE:
		if ( left == nil ) return [ NCValue undefinedValue ] ;
		return [ left execute:stack asReference:asReference ] ;
	case PLUS:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		if ( type == VECTORTYPE ) {
			return [ NCValue valueWithVectorAdd:[ right execute:stack asReference:NO ] toVector:[ left execute:stack asReference:NO ] ] ;
		}
		//  v0.82b (was alwys returning double
		if ( [ left type ] == INTTYPE &&  [ right type ] == INTTYPE ) {
			return [ NCValue valueWithInt:[ [ left execute:stack asReference:NO ] intValue ] + [ [ right execute:stack asReference:NO ] intValue ] ] ;
		}
		return [ NCValue valueWithDouble:[ [ left execute:stack asReference:NO ] doubleValue ] + [ [ right execute:stack asReference:NO ] doubleValue ] ] ;
	case MINUS:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		if ( type == VECTORTYPE ) {
			return [ NCValue valueWithVectorSubtract:[ right execute:stack asReference:NO ] fromVector:[ left execute:stack asReference:NO ] ] ;
		}
		//  v0.82b (was alwys returning double
		if ( [ left type ] == INTTYPE &&  [ right type ] == INTTYPE ) {
			return [ NCValue valueWithInt:[ [ left execute:stack asReference:NO ] intValue ] - [ [ right execute:stack asReference:NO ] intValue ] ] ;
		}
		return [ NCValue valueWithDouble:[ [ left execute:stack asReference:NO ] doubleValue ] - [ [ right execute:stack asReference:NO ] doubleValue ] ] ;
	default:
		printf( "NCAdditive -execute with unknown op type 0x%x\n", op ) ;
		break ;
	}
	return [ NCValue undefinedValue ] ;
}

//	v0.53
- (NSString*)symbolName
{
	if ( left != nil ) return [ left symbolName ] ;
	return [ super symbolName ] ;
}

@end
