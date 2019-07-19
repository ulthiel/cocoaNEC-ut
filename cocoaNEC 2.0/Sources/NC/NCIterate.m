//
//  NCIterate.m
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

#import "NCIterate.h"
#import "NCExpression.h"
#import "NCStatement.h"
#import "NCSystem.h"

@implementation NCIterate

- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList  enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		whileClause = nil ;
		expr = nil ;
	}
	return self ;
}

- (void)dealloc
{
	if ( whileClause ) [ whileClause release ] ;
	if ( expr ) [ expr release ] ;
	[ super dealloc ] ;
}

- (Boolean)parse
{
	token = [ parser nextToken ] ;		// step past "while"
	line = [ parser line ] ;
	
	//  expect LPAREN
	if ( token != LPAREN ) {
		[ parser setError:@"left parenthesis expected after 'while'" flush:YES ] ;
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
		[ parser setError:@"right parenthesis expected after expression in 'while'" flush:YES ] ;
		if ( expr ) [ expr release ] ;
		expr = nil ;
		return NO ;
	}
	token = [ parser nextToken ] ;	//  scan past RPAREN
	
	whileClause = [ [ NCStatement alloc ]  initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( [ whileClause parse ] == NO ) {
		[ expr release ] ;
		expr = nil ;
		[ whileClause release ] ;
		whileClause = nil ;
		return NO ;
	}
	return YES ;	
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	int exprValue ;
	NCValue *checkBreak ;
	
	stack = inStack ;
	if ( expr == nil || whileClause == nil ) return [ NCValue undefinedValue ] ;
	
	while ( 1 ) {
		exprValue = [ [ expr execute:stack asReference:asReference ] intValue ] ;
		if ( exprValue == 0 ) break ;
		//  check if break statement seen
		checkBreak = [ whileClause execute:stack asReference:asReference ] ;
		if ( [ checkBreak returnFlag ] == YES ) return checkBreak ;
		if ( checkBreak && [ checkBreak isBreakValue ] ) break ;
		if ( [ stack->system abort ] ) break ;
	}
	return [ NCValue undefinedValue ] ;
}

@end
