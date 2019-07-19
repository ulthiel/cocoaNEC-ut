//
//  NCCompound.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/14/07.
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

#import "NCCompound.h"
#import "NCFunction.h"
#import "NCSymbolTable.h"
#import "NCSystem.h"

//		Compound statement
//
//		{ declaration-list ; statement_list }

@implementation NCCompound

- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)globals enclosingFunction:(NCFunction*)fn iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:(NCSymbolTable*)globals enclosingFunction:fn iterateLevel:level ] ;
	if ( self ) {
		//  symbol table can be appended.  Starts with the input symbol table
		symbols = [ [ NCSymbolTable alloc ] initWithSymbolTable:globals parser:parser ] ; 
		statementList = [ [ NSMutableArray alloc ] initWithCapacity:32 ] ;
		localVariables = [ [ NSMutableArray alloc ] init ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ symbols release ] ;
	[ statementList release ] ;
	[ localVariables release ] ;
	[ super dealloc ] ;
}

//  v0.76
- (NSArray*)localVariables
{
	return localVariables ;
}

// list of local variables
//	v0.76 symbol list to local variables
- (Boolean)identifierlist:(int)inType
{
	NCObject *sym ;
	char saved[128] ;
	int dimension ;
	
	while ( 1 ) {
		if ( token != ALPHA )  {
			token = [ parser setError:@"identifier expected in declaration list" flush:YES ] ;			
			return NO ;
		}
		strcpy( saved, [ parser tokenString ] ) ;
		token = [ parser nextToken ] ;
		
		if ( token == LBRACKET ) {
			token = [ parser nextToken ] ;
			if ( token != NUM ) {
				[ parser setError:@"need integer constant as array dimension" flush:YES ] ;
				return NO ;
			}
			dimension = [ parser tokenInt ] ;
			token = [ parser nextToken ] ;
			if ( token != RBRACKET ) {
				[ parser setError:@"array dimension requires an ending right bracket" flush:YES ] ;
				return NO ;
			}
			sym = [ symbols addObject:[ [ NCObject alloc ] initWithArray:saved dimension:dimension type:type ] ] ;
			[ localVariables addObject:sym ] ;
			token = [ parser nextToken ] ;
		}
		else {
			sym = [ symbols addObject:[ [ NCObject alloc ] initWithVariable:saved type:type ] ] ;
			[ localVariables addObject:sym ] ;
		}
		if ( token == SEMICOLON ) {
			token = [ parser nextToken ] ;
			return YES ;
		}
		if ( token != COMMA ) {
			[ parser setError:@"comma or semicolon expected" flush:YES ] ;
			token = [ parser flushline ] ;
			return NO ;
		}
		token = [ parser nextToken ] ;
	}
	return NO ;
}

- (Boolean)parse
{
	int errors ;
	NCStatement *statement ;
	
	if ( token != LBRACE ) return NO ;
	
	errors = 0 ;
	token = [ parser nextToken ] ;
	line = [ parser line ] ;
	[ localVariables removeAllObjects ] ;		//  v0.76, v0.81c moved here from identiferList since v0.76 cleared the list per declartion line
	
	while ( ( token & LEXPREFIX ) == TYPEP ) {
		type = token ;
		token = [ parser nextToken ] ;
		errors += ( [ self identifierlist:type ] ? 0 : 1 ) ;
	}
	if ( errors == 0 ) {
		while ( token != RBRACE ) {
			token = [ parser token ] ;
			//  parse statements
			statement = [ [ NCStatement alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
			if ( [ statement parse ] == NO ) {
				[ statement release ] ;				//  quit compund statement if there is an error
				errors++ ;
				break ;
			}
			token = [ parser token ] ;
			[ statementList addObject:statement ] ;
		}
		token = [ parser nextToken ] ;		//  scan past right brace
	}
	[ symbols dumpSymbols ] ;

	return ( errors == 0 ) ;
}

//  find last op in a compound statement(used for checking RETURNSTATEMENT)
- (NCStatement*)lastOp
{
	intType i, count ;
	NCStatement *p ;

	count = [ statementList count ] ;
	p = nil ;
	for ( i = 0; i < count; i++ ) {
		p = [ statementList objectAtIndex:i ] ;
	}
	return p ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	intType i, count ;
	NCValue *p ;
	
	stack = inStack ;
	count = [ statementList count ] ;
	for ( i = 0; i < count; i++ ) {	
		if ( [ stack->system abort ] ) break ;		
		p = [ [ statementList objectAtIndex:i ] execute:stack asReference:asReference ] ;
		if ( p == nil ) return [ NCValue undefinedValue ] ;
		if ( [ p returnFlag ] == YES ) return p ;
		if ( [ p isBreakValue ] ) return [ NCValue breakValue ] ;
	}
	return [ NCValue undefinedValue ] ;
}


@end
