//
//  NCUnary.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/18/07.
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

#import "NCUnary.h"


@implementation NCUnary


- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:level ] ;
	if ( self ) {
		primary = nil ;
		postfix = nil ;
		left = right = nil ;
		nodeType = "Unary" ;
	}
	return self ;
}

- (void)dealloc
{
	if ( primary ) [ primary release ] ;
	if ( postfix ) [ postfix release ] ;
	[ super dealloc ] ;
}

static int component( const char *ident )
{
	int v ;
	
	if ( ident[1] != 0 ) return -1 ;
	v = ident[0] ;
	if ( v == 'x' || v == 'X' ) return 0 ; 
	if ( v == 'y' || v == 'Y' ) return 1 ; 
	if ( v == 'z' || v == 'Z' ) return 2 ; 
	return -1 ; 
}

- (Boolean)parse
{
	token = [ parser token ] ;
	line = [ parser line ] ;
	
	switch ( token ) {
	case MINUS:
		op = MINUS ;
		token = [ parser nextToken ] ;
		postfix =  [ [ NCPostfix alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;		// v0.53 change to postfix to do -function()
		if ( postfix && [ postfix parse ] ) {
			lvalue = [ postfix lvalue ] ;
			type = [ postfix type ] ;
			return YES ;
		}
		[ postfix release ] ;
		postfix = nil ;
		return NO ;
	case INCR:
	case DECR:
		op = token ;
		token = [ parser nextToken ] ;
		primary = [ [ NCPrimary alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
		if ( primary && [ primary parse ] ) {
			type = [ primary type ] ;
			if ( [ primary lvalue ] && ( type == INTTYPE || type == REALTYPE ) ) {
				return YES ;
			}
			[ parser setError:@"syntax error: cannot increment/decrement a non-scalar variable" flush:YES ] ;
			return NO ;
		}
		primary = nil ;
		return NO ;
	default:
		op = 0 ;
		postfix =  [ [ NCPostfix alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
		if ( postfix && [ postfix parse ] ) {
			lvalue = [ postfix lvalue ] ;
			type = [ postfix type ] ;
			
			//  now check if for vector.x 
			token = [ parser token ] ;
			if ( token == DOT ) {
				if ( type == VECTORTYPE ) {			//  v0.54 moved here from v0.53
					//  vector member
					op = MEMBER ;							
					type = REALTYPE ;
					token = [ parser nextToken ] ;			//  scan past DOT
					if ( token == ALPHA ) {
						vectorComponent = component( [ parser tokenString ] ) ;
						if ( vectorComponent >= 0 ) {
							[ parser nextToken ] ;
							return YES ;
						}
						vectorComponent = 0 ;	//  sanity set
					}
				}
				[ parser setError:@"syntax error: dot operator can only be used to get an (x, y or z) component of a vector" flush:YES ] ;
				return NO ;
			}
			return YES ;
		}
		[ postfix release ] ;
		postfix = nil ;
		return NO ;
	}	
	return NO ;
}

- (NCObject*)ncObject
{
	if ( primary ) return [ primary ncObject ] ;
	if ( postfix ) return [ postfix ncObject ] ;
	return [ super ncObject ] ;
}

- (NSString*)symbolName
{
	if ( primary ) return [ primary symbolName ] ;
	if ( postfix ) return [ postfix symbolName ] ;
	return [ super symbolName ] ;
}

- (NCObject*)symbol
{
	if ( primary ) return [ primary ncObject ] ;
	if ( postfix ) return [ postfix ncObject ] ;
	return nil ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	stack = inStack ;
	NCValue *value = nil ;
	
	if ( primary ) {
		switch ( op ) {
		case MINUS:
			value = [ primary execute:stack asReference:NO ] ;
			return [ NCValue valueWithNegatedValue:value ] ;
		case INCR:
			value = [ primary incrementValue:stack ] ;
			return value ;
		case DECR:
			value = [ primary decrementValue:stack ] ;
			return value ;
		default:
			printf( "NCUnary execute:need to implement missing op %x\n", op ) ;
			break ;
		}
		return value ;
	}
	if ( postfix ) {
	
		if ( op == MEMBER ) {
			NCVector *vector ;
			
			//  v0.54 moved here from NCPostfix
			value = [ postfix execute:stack asReference:NO ] ;
			if ( [ value type ] != VECTORTYPE ) return [ NCValue valueWithDouble:0 ] ;

			vector = [ value vectorValue ] ;
			return [ NCValue valueWithDouble:[ vector component:vectorComponent ] ] ;
		}

		value = [ postfix execute:stack asReference:asReference ] ;
		if ( op == MINUS ) return [ NCValue valueWithNegatedValue:value ] ;		//  v0.53
		return value ;
	}
	return [ NCValue undefinedValue ] ;
}

@end
