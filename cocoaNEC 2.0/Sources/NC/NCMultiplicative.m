//
//  NCMultiplicative.m
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

#import "NCMultiplicative.h"
#import "AlertExtension.h"
#import "NCCompiler.h"
#import "NCUnary.h"


@implementation NCMultiplicative

- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		nodeType = "Multiplicative" ;
	}
	return self ;
}

//	(Private API)
- (int)typeForMultiplyOp:(NCNode*)inLeft right:(NCNode*)inRight
{
	int leftType = [ inLeft type ] ;
	int rightType = [ inRight type ] ;
	
	switch ( leftType ) {
	case INTTYPE:
		if ( rightType == REALTYPE ) return REALTYPE ;
		if ( rightType == INTTYPE ) return INTTYPE ;
		if ( rightType == VECTORTYPE ) return VECTORTYPE ;
		if ( rightType == TRANSFORMTYPE ) return TRANSFORMTYPE ;
		return 0 ;
	case REALTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return REALTYPE ;
		if ( rightType == VECTORTYPE ) return VECTORTYPE ;
		if ( rightType == TRANSFORMTYPE ) return TRANSFORMTYPE ;
		return 0 ;
	case VECTORTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return VECTORTYPE ;
		if ( rightType == VECTORTYPE ) return REALTYPE ;	/* dot product */
		return 0 ;
	case TRANSFORMTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return TRANSFORMTYPE ;
		if ( rightType == VECTORTYPE ) return VECTORTYPE ;
		if ( rightType == TRANSFORMTYPE ) return TRANSFORMTYPE ;
		return 0 ;
	default:
		return 0 ;
	}
}

//	(Private API)
- (int)typeForDivideOp:(NCNode*)inLeft right:(NCNode*)inRight
{
	int leftType = [ inLeft type ] ;
	int rightType = [ inRight type ] ;
	
	switch ( leftType ) {
	case INTTYPE:
		if ( rightType == REALTYPE ) return REALTYPE ;
		if ( rightType == INTTYPE ) return INTTYPE ;
		return 0 ;
	case REALTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return REALTYPE ;
		return 0 ;
	case VECTORTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return VECTORTYPE ;
		return 0 ;
	case TRANSFORMTYPE:
		if ( rightType == REALTYPE || rightType == INTTYPE ) return TRANSFORMTYPE ;
		return 0 ;
	default:
		return 0 ;
	}
}

- (Boolean)parse
{
	line = [ parser line ] ;
	left = [ [ NCUnary alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ left parse ] ) {
		token = [ parser token ] ;
		while ( 1 ) {
			switch ( token ) {
			case MULTIPLY:
			case DIVIDE:
			case MOD:
				op = token ;
				[ parser nextToken ] ;
				right = [ [ NCUnary alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;	//  v0.45
				if ( ![ right parse ] ) return NO ;
				switch ( op ) {
				case MULTIPLY:
					type = [ self typeForMultiplyOp:left right:right ] ;
					break ;
				case DIVIDE:
					type = [ self typeForDivideOp:left right:right ] ;
					break ;
				default:
					type = [ self typeForBinaryOp:left right:right ] ;
					break ;
				}
				break ;
			default:
				op = UNARY ;
				token = [ parser token ] ;
				lvalue = [ left lvalue ] ;
				type = [ left type ] ;
				return YES ;
			}
			token = [ parser token ] ;
			if ( token != MULTIPLY && token != DIVIDE && token != MOD ) return YES ;
			left = [ [ NCMultiplicative alloc ] clone:self ] ;
		}
	}
	return NO ;
}

- (NCValue*)divideByZero
{
	NCSystem *system ;
	NCCompiler *compiler ;
    NSString *fmt ;

    fmt = [ NSString stringWithFormat:@"Divide by zero at line %d", line ] ;
	if ( stack != nil ) [ stack->errors addObject:fmt ] ;
    else {
        //  v0.88
        [ AlertExtension modalAlert:@"Divide by zero seen!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:fmt ] ;
    }
	//  v0.70
	compiler = [ parser compiler ] ;
	if ( compiler ) {
		system = [ compiler system ] ;
		if ( system ) [ system setAbort ] ;
	}	
	return  [ NCValue undefinedValue ] ;
}

- (NCValue*)executeMultiply
{
	Boolean leftIsScalar, rightIsScalar ;
	int leftType, rightType ;
	float leftScalarValue = 0, rightScalarValue = 0 ;
	NCTransform *leftTransform = nil, *rightTransform = nil ;
	NCVector *leftVector = nil, *rightVector = nil ;
	
	//  evaluate left leg of graph
	leftType = [ left type ] ;
	leftIsScalar = ( leftType == INTTYPE ) || ( leftType == REALTYPE ) ;
	if ( leftIsScalar ) leftScalarValue = [ [ left execute:stack asReference:NO ] doubleValue ] ;
	if ( leftType == TRANSFORMTYPE ) leftTransform = [ [ left execute:stack asReference:NO ] transformValue ] ;
	if ( leftType == VECTORTYPE ) leftVector = [ [ left execute:stack asReference:NO ] vectorValue ] ;
	
	//  evaluate right leg of graph
	rightType = [ right type ] ;
	rightIsScalar = ( rightType == INTTYPE ) || ( rightType == REALTYPE ) ;
	if ( rightIsScalar ) rightScalarValue = [ [ right execute:stack asReference:NO ] doubleValue ] ;
	if ( rightType == TRANSFORMTYPE ) rightTransform = [ [ right execute:stack asReference:NO ] transformValue ] ;
	if ( rightType == VECTORTYPE ) rightVector = [ [ right execute:stack asReference:NO ] vectorValue ] ;
	
	if ( leftIsScalar ) {
		if ( rightIsScalar ) {
			//  scalar multiplication
			//  v0.82b (was alwys returning double)
			if ( [ left type ] == INTTYPE &&  [ right type ] == INTTYPE ) {
				int intval = leftScalarValue*rightScalarValue + 1e-12 ;
				return [ NCValue valueWithInt:intval ] ;
			}
			return [ NCValue valueWithDouble:leftScalarValue * rightScalarValue ] ;
		}
		if ( rightType == TRANSFORMTYPE ) {
			// return scaled matrix
			return [ NCValue valueWithTransform:[ NCTransform transformWithTransform:rightTransform scale:leftScalarValue ] ] ;
		}
		if ( rightType == VECTORTYPE ) {
			// return scaled vector
			return [ NCValue valueWithVector:[ NCVector vectorWithVector:rightVector scale:leftScalarValue ] ] ;
		}
	}
	if ( leftType == TRANSFORMTYPE ) {
		if ( rightIsScalar ) {
			// return scaled matrix
			return [ NCValue valueWithTransform:[ NCTransform transformWithTransform:leftTransform scale:rightScalarValue ] ] ;
		}
		if ( rightType == VECTORTYPE ) {
			//  transform vector into vector
			return [ NCValue valueWithVector:[ leftTransform applyTransform:rightVector ] ] ;
		}
		if ( rightType == TRANSFORMTYPE ) {
			// concat matrix
			return [ NCValue valueWithTransform:[ NCTransform transformByConcatenating:rightTransform toTransform:leftTransform ] ] ;
		}
	}
	if ( leftType == VECTORTYPE ) {
		if ( rightIsScalar ) {
			// return scaled vector
			return [ NCValue valueWithVector:[ NCVector vectorWithVector:leftVector scale:rightScalarValue ] ] ;
		}
	}
	
	return [ NCValue valueWithDouble:1.0 ] ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	double realDenom ;
	int intDenom ;
	
	stack = inStack ;

	switch ( op ) {
	case UNARY:
		if ( left == nil ) return [ NCValue undefinedValue ] ;
		return [ left execute:stack asReference:asReference ] ;
	case MULTIPLY:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		return [ self executeMultiply ] ;
	case DIVIDE:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		if ( type == INTTYPE ) {
			intDenom = [ [ right execute:stack asReference:NO ] intValue ] ;
			if ( intDenom == 0 ) return [ self divideByZero ] ;
			return  [ NCValue valueWithInt:[ [ left execute:stack asReference:asReference ] intValue ] / intDenom ] ;
		}
		realDenom = [ [ right execute:stack asReference:NO ] doubleValue ] ;
		if ( fabs( realDenom ) < 1e-12 ) return [ self divideByZero ] ;
		return [ NCValue valueWithDouble:[ [ left execute:stack asReference:NO ] doubleValue ] / realDenom ] ;
	case MOD:
		if ( left == nil || right == nil ) return [ NCValue undefinedValue ] ;
		intDenom = [ [ right execute:stack asReference:NO ] intValue ] ;
		if ( intDenom == 0 ) return [ self divideByZero ] ;
		return  [ NCValue valueWithInt:[ [ left execute:stack asReference:NO ] intValue ] % intDenom ] ;
	default:
		printf( "NCMultiplicative -execute with unknown op type 0x%x\n", op ) ;
		break ;
	}
	return  [ NCValue undefinedValue ] ;
}

//	v0.53
- (NSString*)symbolName
{
	if ( left != nil ) return [ left symbolName ] ;
	return [ super symbolName ] ;
}

@end
