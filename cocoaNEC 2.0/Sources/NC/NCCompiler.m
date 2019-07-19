//
//  NCCompiler.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/15/07.
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

#import "NCCompiler.h"
#import "AlertExtension.h"
#import "NC.h"
#import "NCError.h"
#import "NCFunction.h"
#import "ApplicationDelegate.h"

@implementation NCCompiler

//	v0.52 preprocessor
//  includeArray detects nested loops of includes.
- (NSString*)preprocess:(NSString*)input includes:(NSMutableArray*)inArray
{
	NSMutableArray *includeArray ;
	NSString *replaced, *included, *remainder, *pathName, *expanded, *result ;
	NSRange range ;
	int i, j, index, c = 0, mark ;
	Boolean foundComment ;
	char includeFile[257] ;
	
	if ( input != nil ) {
		includeArray = [ NSMutableArray arrayWithCapacity:32 ] ;
		[ includeArray addObjectsFromArray:inArray ] ;
		replaced = nil ;
		remainder = input ;
		while ( [ remainder length ] > 0 ) {
			range = [ remainder rangeOfString:@"#include" ] ;
			if ( range.location == NSNotFound ) {
				//  no more #include
				if ( replaced == nil ) return remainder ;		//  did not find any #includes
				//  copy the remainder into replaced
				result = [ NSString stringWithString:[ replaced stringByAppendingString:remainder ] ] ;
				return result ;
			}
			index = (int)range.location ;
			//  check if it has been commented away
			foundComment = NO ;
			
			for ( i = index; i > 0; i-- ) {
				c = [ remainder characterAtIndex:i ] ;
				if ( c == '\n' || c == '\r' ) break ;
				if ( c == '/' ) {
					if ( [ remainder characterAtIndex:i-1 ] == '/' ) {
						foundComment = YES ;
						break ;
					}
				}
			}
			if ( foundComment ) {
				//  found a comment, don't process as include, skip one character past #
				if ( replaced == nil ) {
					// have not created a replacement string yet
					replaced = [ remainder substringToIndex:index+1 ] ;
				}
				else {
					replaced = [ replaced stringByAppendingString:[ remainder substringToIndex:index+1 ] ] ;
				}
				remainder = [ remainder substringFromIndex:index+2 ] ;
				continue ;
			}
			
			//  first gather all string up to the #include 
			if ( replaced == nil ) {
				// have not created a replacement string yet
				replaced = [ remainder substringToIndex:index ] ;
			}
			else {
				replaced = [ replaced stringByAppendingString:[ remainder substringToIndex:index ] ] ;
			}
			//  now scan past the #include
			for ( i = index; i < index+16; i++ ) {
				if ( i >= [ remainder length ] ) break ;
				c = [ remainder characterAtIndex:i ] ;
				if ( c == ' ' || c == '\t' || c == '\r' || c == '\n' ) break ;
			}
			//  #include problem
			if ( i >= [ remainder length ] ) return nil ;
			
			mark = i ;
			for ( i = mark; i < mark+32; i++ ) {
				if ( i >= [ remainder length ] ) break ;
				c = [ remainder characterAtIndex:i ] ;
				if ( !( c == ' ' || c == '\t' || c == '\r' || c == '\n' ) ) break ;
			}
			//  #include problem
			if ( i >= [ remainder length ] ) return nil ;
			
			mark = i ;
			if ( [ remainder characterAtIndex:mark ] == '"' ) {
				mark++ ;
				for ( i = 0; i < 256; i++ ) {
					c = [ remainder characterAtIndex:mark+i ] ;
					if ( c == '\n' || c == '\r' || c == '"' ) break ;
					includeFile[i] = c ;
				}
				if ( i >= 256 || c != '"' ) return nil ;
				includeFile[i] = 0 ;
				pathName = [ [ NSString stringWithUTF8String:includeFile ] stringByExpandingTildeInPath ] ;
				if ( [ includeArray count ] > 256 ) {
                    
                    //  v0.88
					[ AlertExtension modalAlert:@"Include file nesting too deep!." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Include files nesting exceeded 256 (do you really mean to do this?)." ] ;
 
					return nil ;
				}
				for ( j = 0; j < [ includeArray count ]; j++ ) {
					if ( [ pathName isEqualToString:[ includeArray objectAtIndex:j ] ] ) {
                        //  v0.88
                        [ AlertExtension modalAlert:@"Include file nesting loops!." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Include files are including each other in an infinite loop." ] ;

						return nil ;
					}
				}
				[ includeArray addObject:pathName ] ;
				included = [ NSString stringWithContentsOfFile:pathName encoding:NSASCIIStringEncoding error:nil ] ;
				if ( included == nil ) {
                    //  v0.88
                    [ AlertExtension modalAlert:@"Included file not found." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"" ] ;
                    
					return nil ;
				}
				remainder = [ remainder substringFromIndex:mark+i+1 ] ;
				expanded = [ self preprocess:included includes:includeArray ] ;
				replaced = [ replaced stringByAppendingString:expanded ] ;
			}
			else {
				//  #include error
				return nil ;
			}
		}
		if ( replaced != nil ) return [ NSString stringWithString:replaced ] ;
	}
	return nil ; 
}

- (id)initWithString:(NSString*)str documentNumber:(int)inDocumentNumber
{
	NSMutableArray *includeArray ;	//  array of NSString
	
	self = [ super init ] ;
	if ( self ) {
		includeArray = [ [ NSMutableArray alloc ] init ] ;
		
		preprocessed = [ self preprocess:str includes:includeArray ] ;
		[ includeArray release ] ;
		
		if ( preprocessed != nil && preprocessed != str ) str = [ preprocessed retain ] ;
		documentNumber = inDocumentNumber ;
		parser = [ [ NCParser alloc ] initWithSource:str compiler:self ] ;

		globals = [ [ NCSymbolTable alloc ] initWithCapacity:64 parser:parser ] ;
        preParser = [ [ NCPreParser alloc ] initWithSource:str compiler:self ] ;
		system =  [ [ NCSystem alloc ] initIntoGlobals:globals documentNumber:inDocumentNumber ] ;
	}
	return self ;
}

//	v0.55	This is used by the spreadsheet interface
- (id)initWithString:(NSString*)str
{
	NSMutableArray *includeArray ;	//  array of NSString
	
	self = [ super init ] ;
	if ( self ) {
		includeArray = [ [ NSMutableArray alloc ] init ] ;
		
		preprocessed = [ self preprocess:str includes:includeArray ] ;
		[ includeArray release ] ;
		
		if ( preprocessed != nil && preprocessed != str ) str = [ preprocessed retain ] ;
		documentNumber = 0 ;
		parser = [ [ NCParser alloc ] initWithSource:str compiler:self ] ;
		globals = [ [ NCSymbolTable alloc ] initWithCapacity:64 parser:parser ] ;
        preParser = [ [ NCPreParser alloc ] initWithSource:str compiler:self ] ;
		system =  [ [ NCSystem alloc ] initIntoSpreadsheetGlobals:globals ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ globals release ] ;
	[ preParser release ] ;
	[ parser release ] ;
	[ system release ] ;
	[ super dealloc ] ;
}

- (NCSystem*)system
{
	return system ;
}

- (Boolean)parseFunction:(int)type
{
	NCFunction *function ;
	Boolean result = NO ;
	
	function = [ [ NCFunction alloc ] initWithParser:parser type:type globals:globals iterateLevel:0 ] ;
	
	if ( function ) {
		if ( [ globals containsObject:[ function functionObject ] ] ) {
			[ parser setError:[ NSString stringWithFormat:@"function name '%s' previously defined", [ [ [ function functionObject ] name ] UTF8String ] ] flush:YES ] ;
			return NO ;
		}
		[ globals addObject:[ function functionObject ] ] ;
		result = [ function parse ] ;
	}
	token = [ parser token ] ;
	return result ;
}

//  expect identifier (,identifierlist )
- (Boolean)identifierlist:(int)type
{
	NCObject *sym ;
	char saved[128] ;
	int dimension ;
	
	while ( 1 ) {
		if ( token != ALPHA )  {
			token = [ parser setError:@"identifier expected in declaration list" flush:NO ] ;			
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
			sym = [ globals addObject:[ [ NCObject alloc ] initWithArray:saved dimension:dimension type:type ] ] ;
			token = [ parser nextToken ] ;
		}
		else {
			sym = [ globals addObject:[ [ NCObject alloc ] initWithVariable:saved type:type ] ] ;
		}
		
		if ( token == SEMICOLON ) {
			token = [ parser nextToken ] ;
			return YES ;
		}
		if ( token != COMMA ) {			
			[ parser setError:@"comma or semicolon expected" flush:YES ] ;
			return NO ;
		}
		token = [ parser nextToken ] ;
	}
	return NO ;
}

//  return NO to stop compile
- (Boolean)externalDeclaration
{
	int type ;
	
	token = [ parser token ] ;
	if ( token == EOS ) return NO ;
	
	//  external declaration is 
	//		type identifierlist ;
	//		identifier( argumentlist ) { function body } 
	
	switch ( token ) {
	case MODELBLOCK:
		return [ self parseFunction:MODELBLOCK ] ;
	case CONTROLBLOCK:
		return [ self parseFunction:CONTROLBLOCK ] ;
	default:
		break ;
	}
	if ( ( token & LEXPREFIX ) == TYPEP ) {
		type = token ;
		//  look forward to find if there is a LPAREN for a function
		[ parser setMark ] ;
		token = [ parser nextToken ] ;		//  look for identifier
		if ( token != ALPHA )  {
			token = [ parser setError:[ NSString stringWithFormat:@"syntax error, token = %s", [ parser tokenType:token ] ] flush:YES ] ;			
			return NO ;
		}
		token = [ parser nextToken ] ;
		if ( token == LPAREN ) {
			token = [ parser popMark ] ;
			return [ self parseFunction:type ] ;
		}
		token = [ parser popMark ] ;
		return [ self identifierlist:type ] ;
	}
	token = [ parser setError:[ NSString stringWithFormat:@"syntax error in external declaration: %s", [ parser tokenType:token ] ] flush:YES ] ;
	return NO ;
}

- (Boolean)precompile
{
	[ system resetFarFieldDisplacement ] ;	// v0.81
	[ preParser parseForFunctionDefinitions:globals ] ;	
	return YES ;
}

- (Boolean)compile
{
	NSArray *errors ;
	intType count ;
	
	[ system setHasFrequencyDependentNetwork:NO ] ;	//  v0.81
	
	token = [ parser newCompile ] ;

	//  NC program is a list of external declarations
	while ( 1 ) {
		if ( ![ self externalDeclaration ] ) break ;
	}
	
	//  merge in preparser errors
	[ parser mergeErrors:[ preParser errors ] ] ;
	
	//  now check for errors
	errors = [ parser errors ] ;
	count = [ errors count ] ;
	
	return ( count == 0 ) ;
}

- (NSArray*)parseErrors
{
	return [ parser errors ] ;
}

- (NCSymbolTable*)symbolTable
{
	return globals ;
}

@end
