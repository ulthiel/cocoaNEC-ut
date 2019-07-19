//
//  NCSelection.m
//  cocoaNEC
//
//  Created by Kok Chen on 10/4/07.
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

#import "NCSelection.h"
#import "NCExpression.h"
#import "NCStatement.h"


@implementation NCSelection

//	v0.70 added function pointer so return statment in if and else clase will work
- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		ifClause = nil ;
		elseClause = nil ;
		expr = nil ;
		enclosingFunction = function ;
	}
	return self ;
}

- (void)dealloc
{
	if ( ifClause ) [ ifClause release ] ;
	if ( elseClause ) [ elseClause release ] ;
	if ( expr ) [ expr release ] ;
	[ super dealloc ] ;
}

- (Boolean)parse
{
	token = [ parser nextToken ] ;		// step past "if"
	line = [ parser line ] ;
	
	//  expect LPAREN
	if ( token != LPAREN ) {
		[ parser setError:@"left parenthesis expected after 'if'" flush:YES ] ;
		return NO ;
	}
	token = [ parser nextToken ] ;
	
	expr = [ [ NCExpression alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ expr parse ] == NO ) {
		[ expr release ] ;
		expr = nil ;
		return NO ;
	}
	
	token = [ parser token ] ;
	if ( token != RPAREN ) {
		[ parser setError:@"right parenthesis expected after expression in 'if'" flush:YES ] ;
		if ( expr ) [ expr release ] ;
		expr = nil ;
		return NO ;
	}
	token = [ parser nextToken ] ;	//  scan past RPAREN
	
	ifClause = [ [ NCStatement alloc ]  initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	
	if ( [ ifClause parse ] == NO ) {
		[ expr release ] ;
		expr = nil ;
		[ ifClause release ] ;
		ifClause = nil ;
		return NO ;
	}
	//  else clause
	token = [ parser token ] ;	
	if ( token == ELSECLAUSE ) {
		token = [ parser nextToken ] ;	//  scan past "else"
		elseClause = [ [ NCStatement alloc ]  initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
		if ( [ elseClause parse ] == NO ) {
			[ expr release ] ;
			expr = nil ;
			[ ifClause release ] ;
			[ elseClause release ] ;
			ifClause = elseClause = nil ;
			return NO ;
		}
	}
	return YES ;	
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	int exprValue ;
	NCValue *value ;
	
	stack = inStack ;
	exprValue = [ [ expr execute:stack asReference:asReference ] intValue ] ;
	
	if ( exprValue == 0 ) {
		//  false, execute else branch if there is one
		if ( elseClause ) {
			value = [ elseClause execute:stack asReference:asReference ] ;
			if ( [ value returnFlag ] == YES ) return value ;
			if ( value && [ value isBreakValue ] ) return [ NCValue breakValue ] ;
		}
		return [ NCValue valueWithInt:0 ] ;
	}	
	if ( ifClause ) {
		value = [ ifClause execute:stack asReference:asReference ] ;
		if ( [ value returnFlag ] == YES ) return value ;
		if ( value && [ value isBreakValue ] ) return [ NCValue breakValue ] ;
		return [ NCValue valueWithInt:1 ] ;
	}
	return [ NCValue undefinedValue ] ;
}

@end
