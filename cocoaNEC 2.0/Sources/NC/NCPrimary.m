//
//  NCPrimary.m
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

#import "NCPrimary.h"
#import "NCSymbolTable.h"

@implementation NCPrimary

- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		expression = nil ;
		stringVal = nil ;
		nodeType = "Primary" ;
	}
	return self ;
}

- (void)dealloc
{
	if ( stringVal ) free( stringVal ) ;
	if ( expression ) [ expression release ] ;
	[ super dealloc ] ;
}

- (Boolean)parse
{
	const char *ident ;
	
	token = [ parser token ] ;
	line = [ parser line ] ;
	
	if ( token == LPAREN ) {
		token = [ parser nextToken ] ;
		expression = [ [ NCExpression alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
		if ( [ expression parse ] ) {
			token = [ parser token ] ;
			if ( token == RPAREN ) {
				op = LPAREN ;
				//  inherit properties from expression
				lvalue = [ expression lvalue ] ;
				type = [  expression type ] ;
				[ parser nextToken ] ;
				return YES ;
			}
			[ expression release ] ;
			expression = nil ;
			[ parser setError:@"missing right parenthesis" flush:YES ] ;
			return NO ;
		}
		[ expression release ] ;
		expression = nil ;
		[ parser setError:@"syntax error inside parenthesis" flush:YES ] ;
		return NO ;
	}
	
	op = token ;
	switch ( token ) {
	case ALPHA:
		ident = [ parser tokenString ] ;
		ncObject = [ symbols containsIdent:[ NSString stringWithUTF8String:ident ] ] ;
		if ( !ncObject ) [ parser setError:[ NSString stringWithFormat:@"error: undeclared symbol '%s'", ident ] flush:NO ] ;
		type = [ ncObject type ] ;
		lvalue = YES ;
		token = [ parser nextToken ] ;
		return YES ;
	case NUM:
		intVal = [ parser tokenInt ] ;
		type = INTTYPE ;
		break ;
	case REAL:
		realVal = [ parser tokenReal ] ;
		type = REALTYPE ;
		break ;
	case DQUOTE:
		ident = [ parser tokenString ] ;
		stringVal = (char*)malloc( strlen(ident)+1 ) ;
		strcpy( stringVal, ident ) ;
		type = STRINGTYPE ;
		break ;
	default:
		op = 0 ;
		[ parser setError:[ NSString stringWithFormat:@"syntax error - unrecognized %s in primary expression ", [ parser tokenType:token ] ] flush:YES ] ;
		return NO ;
	}
	token = [ parser nextToken ] ;
	return YES ;
}

- (NCObject*)ncObject
{
	return ncObject ;
}

- (NSString*)symbolName
{
	NSString *s ;
	
	if ( ncObject == nil ) return [ super symbolName ] ;
	s = [ ncObject name ] ;
	if ( s == nil )  return [ super symbolName ] ;
	return s ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	stack = inStack ;
	
	switch ( op ) {
	case LPAREN:
		return [ expression execute:stack asReference:asReference ] ;
	case NUM:
		return [ NCValue valueWithInt:intVal ] ;
	case REAL:
		return [ NCValue valueWithDouble:realVal ] ;
	case DQUOTE:
		return [ NCValue valueWithString:stringVal ] ;
	case ALPHA:
		if ( ncObject == nil ) {
			[ self runtimeMessage:@"Internal error: symbol disappeared during the execution phase?" ] ;
			return  [ NCValue undefinedValue ] ;
		}
		return [ ncObject get:stack line:line ] ;
	default:
		printf( "primary execute: op %x\n", op ) ;
	}
	return nil ;
}

- (NCValue*)incrementValue:(RuntimeStack*)inStack
{
	NCValue *value ;
	stack = inStack ;
	
	if ( op == ALPHA && ncObject != nil ) {
		value = [ ncObject get:stack line:line ] ;
		value = [ NCValue valueWithIncrementValue:value ] ;
		[ ncObject put:value stack:stack line:line ] ;
		return value ;
	}
	return [ NCValue undefinedValue ] ; ;
}

- (NCValue*)decrementValue:(RuntimeStack*)inStack
{
	NCValue *value ;
	stack = inStack ;
	
	if ( op == ALPHA && ncObject != nil ) {
		value = [ ncObject get:stack line:line ] ;
		value = [ NCValue valueWithDecrementValue:value ] ;
		[ ncObject put:value stack:stack line:line ] ;
		return value ;
	}
	return [ NCValue undefinedValue ] ; ;
}

@end
