//
//  NCExpression.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/17/07.
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

#import "NCExpression.h"
#import "NCObject.h"
#import "NCLogicalOr.h"


@implementation NCExpression


- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		nodeType = "Expression" ;
	}
	return self ;
}

- (Boolean)assignmentExpression:(NCLogicalOr*)lexpr
{
	NCExpression *expr ;
	NSString *str ;
	int leftType, rightType ;
	
	if ( ![ lexpr lvalue ] ) {
		[ lexpr release ] ;
		lexpr = nil ;
		[ parser setError:@"syntax error: operation only legal with int or real variable)" flush:YES ] ;
		return NO ;
	}
	op = token ;
	token = [ parser nextToken ] ;
	left = lexpr ;
	expr = [ [ NCExpression alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ expr parse ] ) {
		right = expr ;
		leftType = [ left type ] ;
		rightType = [ right type ] ;
		switch ( leftType ) {
		case INTTYPE:
		case REALTYPE:
			if ( rightType == INTTYPE || rightType == REALTYPE ) break ;
			[ parser setError:[ NSString stringWithFormat:@"error: assigning a non-numerical value to '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
			return NO ;
		case STRINGTYPE:
			if ( rightType != STRINGTYPE ) {
				[ parser setError:[ NSString stringWithFormat:@"error: assigning a non-string value to '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
				return NO ;
			}
			break ;
		case ELEMENTTYPE:
			if ( rightType != ELEMENTTYPE ) {
				[ parser setPass2Error:[ NSString stringWithFormat:@"error: assigning a non-geometry element to '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
				return NO ;
			}
			break ;
		case COAXTYPE:	//  v0.81b
			if ( rightType != COAXTYPE ) {
				[ parser setPass2Error:[ NSString stringWithFormat:@"error: assigning a variable/constant that is not a coaxtype to '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
				return NO ;
			}
			break ;
		case VECTORTYPE:
			if ( rightType != VECTORTYPE ) {			
				if ( rightType == 0 ) return NO ;
				str = [ lexpr symbolName ] ;
				[ parser setPass2Error:[ NSString stringWithFormat:@"error: assigning a value that is not a vector to variable '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
				return NO ;
			}
			break ;
		case TRANSFORMTYPE:
			if ( rightType != TRANSFORMTYPE ) {
				[ parser setPass2Error:[ NSString stringWithFormat:@"error: assigning a value that is not a transform to variable '%s'", [ [ lexpr symbolName ] UTF8String ] ] flush:YES ] ;
				return NO ;
			}
			break ;
		default:
			[ parser setError:@"error: type mismatch or improper assigment statement" flush:YES ] ;
			return NO ;
		}
		type = leftType ;
		return YES ;
	}
	[ expr release ] ;
	left = nil ;
	return NO ;
}

- (Boolean)parse
{
	NCLogicalOr *expr ;

	line = [ parser line ] ;
	expr = [ [ NCLogicalOr alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ expr parse ] ) {
		token = [ parser token ] ;
		op = LOGICALOR ;
		if ( ( token & LEXPREFIX ) == ASSIGN ) return [ self assignmentExpression:expr ] ;
		//  return as expression
		lvalue = [ expr lvalue ] ;
		type = [ expr type ] ;
		left = expr ;
		if ( left == nil ) {
			[ parser setError:@"Compiler error: assigment to nil object?" flush:YES ] ;
		}
		return YES ;
	}
	[ expr release ] ;
	return NO ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	NCValue *p, *q ;
	NCObject *obj ;
	
	stack = inStack ;

	switch ( op ) {
	case ASSIGNEQ:
		p = [ right execute:stack asReference:(Boolean)asReference ] ;
		if ( !p || left == nil ) return nil ;
		
		//  see if it is an int or real scalar
		obj = [ left ncObject ] ;
		
		if ( obj == nil ) {
			//  not a simple scalar, execute left hand side
			q = [ left execute:stack asReference:YES ] ;
			if ( q ) {
				obj = [ q ncObject ] ;
			}
		}
		if ( obj == nil ) {
			printf( "compiler error, bad lval\n" ) ;
			return nil ;
		}
		[ obj put:p stack:stack line:line ] ;
		return [ obj value ] ;
	case LOGICALOR:
		if ( left == nil ) return [ NCValue undefinedValue ] ;
		return [ left execute:stack asReference:asReference ] ;
	default:
		printf( "NCExpression -execute with unknown op type 0x%x\n", op ) ;
		break ;
	}
	return nil ;
}

@end
