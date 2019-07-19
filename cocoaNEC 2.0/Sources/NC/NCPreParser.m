//
//  NCPreParser.m	v0.52
//  cocoaNEC
//
//  Created by Kok Chen on 5/26/09.
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

#import "NCPreParser.h"
#import "NCForwardReference.h"
#import "NCError.h"

@implementation NCPreParser

//	Pre-parse looking for forward referenced functions

- (id)initWithSource:(NSString*)characterStream 
{
	self = [ super init ] ;
	if ( self ) {
		source = (const unsigned char*)[ characterStream UTF8String ] ;
		if ( source == nil ) return nil ;
		line = 1 ;
		pass = 1 ;
		needAdvance = NO ;
		code = nil ;
		errorList = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		[ self setupKeywords ] ;
	}
	return self ;
}

//  recursively walk through a { } block
- (Boolean)skipBlock
{
	// look for left brace
	while ( token != EOS ) {
		if ( token == LBRACE ) break ;
		[ self nextToken ] ;
	}
	if ( token == EOS ) return NO ;
	[ self nextToken ] ;
	while ( token != EOS ) {
		if ( token == LBRACE ) {
			[ self skipBlock ] ;
		}
		else {
			if ( token == RBRACE ) {
				[ self nextToken ] ;
				break ;
			}
			else {
				[ self nextToken ] ;
			}
		}
	}
	return ( token != EOS ) ;
}

//	(Private API)
- (void)parseFunctionDefinition:(char*)functionName type:(int)functionType globals:(NCSymbolTable*)globals
{
	int arg ;
	short argType[65] ;
	Boolean error ;
	
	//  token should be LPAREN when this function is called
	error = NO ;
	[ self nextToken ] ;	//  skip past LPAREN
	for ( arg = 0; arg < 64 && error == NO; arg++ ) {		//  sanity check - limit to 64 arguments
	
		if ( token == INTTYPE || token == REALTYPE || token == ELEMENTTYPE || token == COAXTYPE || token == VECTORTYPE || token == TRANSFORMTYPE ) {	//	v0.81b
			argType[arg] = token ;
			[ self nextToken ] ;
			
			if ( token == MULTIPLY ) {
				//  pointer
				argType[arg] |= ADDRESSP ;
				[ self nextToken ] ;
			}
			
			if ( token == ALPHA ) {
				[ self nextToken ] ;
				if ( token == COMMA ) {
					[ self nextToken ] ;
					continue ;
				}
				if ( token == RPAREN ) {
					arg++ ;
					break ;
				}
				[ errorList addObject:[ NCError errorWithPointer:ptr string:@"arguments should be separated by comma and end with right parenthesis" line:line ] ] ;
				error = YES ;
				break ;
			}
			else {
				[ errorList addObject:[ NCError errorWithPointer:ptr string:@"arguments should be an int, real or element variable identifier" line:line ] ] ;
				error = YES ;
				break ;
			}
		}
		else {
			if ( token != RPAREN ) {
				//  argument type is not int, real or element
				[ errorList addObject:[ NCError errorWithPointer:ptr string:@"missing type declaration for argument variable (should be int, real or element)" line:line ] ] ;
			}
			break ;
		}
	}
	if ( error == NO ) {
		NCForwardReference *function = [ [ NCForwardReference alloc ] initWithVariable:functionName type:functionType ] ;		//  create an NCFunction object for this function
		[ globals addFunctionObject:function ] ;
		//  now add argument prototypes
		argType[arg] = 0 ;
		[ function setArgPrototypes:&argType[0] ] ;
	}
}

- (void)parseForFunctionDefinitions:(NCSymbolTable*)globals
{
	int functionType ;
	char functionName[256] ;
	
	[ errorList removeAllObjects ] ;
	
	//  begin at start of stream and prime the token
	ptr = mark = source ;
	[ self nextToken ] ;
	while ( token != EOS ) {
		if ( token == MODELBLOCK ) {
			//  model
			if ( [ self skipBlock ] == NO ) break ;
		}
		else {
			if ( token == CONTROLBLOCK ) {
				//  control
				if ( [ self skipBlock ] == NO ) break ;
			}
			else {
				if ( token == INTTYPE || token == REALTYPE || token == ELEMENTTYPE || token == COAXTYPE || token == VOIDTYPE || token == VECTORTYPE || token == TRANSFORMTYPE ) {	//  v0.81b
					functionType = token ;
					[ self nextToken ] ;
					if ( token == ALPHA ) {
						strcpy( functionName, string ) ;
						[ self nextToken ] ;
						if ( token == LPAREN ) {
							[ self parseFunctionDefinition:functionName type:functionType globals:globals ] ;
							[ self skipBlock ] ;
						}
					}
				}
				else [ self nextToken ] ;		//  noise, as far as we are concerned
			}
		}
	}
}

@end
