//
//  NCFunction.m
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

#import "NCFunction.h"
#import "NCBasicValue.h"
#import "NCParser.h"
#import "NCCompound.h"
#import "NCSymbolTable.h"
#import "NCStatement.h"
#import "NCSystem.h"

@implementation NCFunction

- (id)initWithParser:(NCParser*)inParser type:(int)inType globals:(NCSymbolTable*)globals iterateLevel:(int)level
{
	char *str ;
	short noPrototype[] = { 0 } ;
	short intPrototype[] = { INTTYPE, 0 } ;
	NCObject *obj ;
	
	self = [ super initWithParser:inParser symbols:globals enclosingFunction:nil iterateLevel:level ] ;
	if ( self ) {
		type = inType ;
		forwardReference = nil ;
		str = (char*)[ parser tokenString ] ;
		functionName = [ NSString stringWithUTF8String:str ] ;
		arguments = [ [ NSMutableArray alloc ] init ] ;
		obj = [ globals containsIdent:functionName ] ;
		if ( obj != nil ) {
			//  first check to see if it was a forward reference
			if ( [ obj symClass ] == NCFUNCTION && [ obj isForwardReference ] == YES  ) {
				forwardReference = ( NCFunctionObject* )obj ;	
				//  if forward reference, change the function body name to <name>_FORWARD_ and point the forward reference to us
				functionName = [ functionName stringByAppendingString:@"_FORWARD_" ] ; 
				[ obj setFunction:self ] ;
			}
			else {
				[ parser setError:[ NSString stringWithFormat:@"function name '%s' previously defined", str ] flush:NO ] ;
				return nil ;
			}
		}
		isModel = ( strcmp( str, "model" ) == 0 ) ;
		isControl = ( strcmp( str, "control" ) == 0 ) ;
		modelName[0] = 0 ;
		body = nil ;
		
		//  symbol table starts with globals
		symbols = [ [ NCSymbolTable alloc ] initWithSymbolTable:globals parser:parser ] ;
		
		if ( isControl ) {
			//  add control symbols to control block
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"directivity" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"maxGain" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"averageGain" value:0 ] ] ;		//  v0.62
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"efficiency" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"azimuthAngleAtMaxGain" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"elevationAngleAtMaxGain" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"frontToBackRatio" value:0 ] ] ;
			[ symbols addObject:[ [ NCObject alloc ] initWithRealVariable:"frontToRearRatio" value:0 ] ] ;
			
			//  moved to system context v0.44 [ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"useQuadPrecision" type:INTTYPE selector:@selector(useQuadPrecision:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"vswr" type:REALTYPE selector:@selector(vswr:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointImpedanceReal" type:REALTYPE selector:@selector(feedpointImpedanceReal:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointImpedanceImaginary" type:REALTYPE selector:@selector(feedpointImpedanceImaginary:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointVoltageReal" type:REALTYPE selector:@selector(feedpointVoltageReal:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointVoltageImaginary" type:REALTYPE selector:@selector(feedpointVoltageImaginary:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointCurrentReal" type:REALTYPE selector:@selector(feedpointCurrentReal:prototype:) argPrototypes:intPrototype ] ] ;
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"feedpointCurrentImaginary" type:REALTYPE selector:@selector(feedpointCurrentImaginary:prototype:) argPrototypes:intPrototype ] ] ;
		
			[ symbols addObject:[ [ NCFunctionObject alloc ] initWithSystem:"runModel" type:INTTYPE selector:@selector(runModel:prototype:) argPrototypes:noPrototype ] ] ;
		}
		functionObject = [ [ NCFunctionObject alloc ] initWithVariable:[ functionName UTF8String ] type:inType ] ;		//  v0.52 changed name for forward reference
		[ symbols addFunctionObject:functionObject ] ;
		token = [ parser nextToken ] ;
	}
	return self ;
}

- (void)dealloc
{
	if ( functionObject ) [ functionObject release ] ;
	if ( symbols ) [ symbols release ] ;
	[ arguments release ] ;
	[ super dealloc ] ;
}

- (NCObject*)functionObject
{
	return functionObject ;
}

- (Boolean)declarationList
{
	int typeOfArg ;
	Boolean success, isReference ;

	if ( isModel ) {
		//  parse model header
		if ( token != LPAREN ) {
			token = [ parser setError:[ NSString stringWithFormat:@"left parenthesis expected after keyword 'model', saw token %x", token ] flush:YES ] ;
			return NO ;
		}
		token = [ parser nextToken ] ;
		if ( token == ERRSTR ) return NO ;
		if ( token != DQUOTE ) {
			token = [ parser setError:@"expecting name for 'model' in double quotes" flush:YES ] ;
			return NO ;
		}
		strcpy( modelName, [ parser tokenString ] ) ;
		token = [ parser nextToken ] ;
		if ( token != RPAREN ) {
			token = [ parser setError:@"right parenthesis expected after model name" flush:YES ] ;
			return NO ;
		}
	}
	else {
		if ( isControl ) {
			//  parse model header
			if ( token != LPAREN ) {
				token = [ parser setError:[ NSString stringWithFormat:@"control block expects a '()' after it, saw token %x instead", token ] flush:YES ] ;
				return NO ;
			}
			token = [ parser nextToken ] ;
			if ( token != RPAREN ) {
				token = [ parser setError:[ NSString stringWithFormat:@"control block expects a '()' after it, but saw token %x instead", token ] flush:YES ] ;
				return NO ;
			}
		}
		else {
			//  parse regular function header
			if ( token != LPAREN ) {
				token = [ parser setError:[ NSString stringWithFormat:@"function definition expects an argument list between parentheses, but saw token %x instead", token ] flush:YES ] ;
				return NO ;
			}
			[ arguments removeAllObjects ] ;
			token = [ parser nextToken ] ;
			if ( token != RPAREN ) {
				//  collect function arguments
				while ( 1 ) {
					if ( token != INTTYPE && token != REALTYPE && token != ELEMENTTYPE && token != COAXTYPE && token != VECTORTYPE && token != TRANSFORMTYPE ) {	//  v0.81b
						token = [ parser setError:@"missing type declaration for argument variable (should be int, real or element)" flush:YES ] ;
						return NO ;
					}
					typeOfArg = token ;
					isReference = NO ;
					token = [ parser nextToken ] ;
					if ( token == MULTIPLY ) {
						isReference = YES ;
						token = [ parser nextToken ] ;
					}
					if ( token != ALPHA ) {
						token = [ parser setError:@"bad identifier in argument list" flush:YES ] ;
						return NO ;
					}
					//  found argument type and identifier, add it (an NCObject) to local symbol table
					if ( isReference ) {
						[ arguments addObject:[ symbols addObject:[ [ NCObject alloc ] initWithPointer:[ parser tokenString ] type:typeOfArg ] ] ] ;
					}
					else {
						[ arguments addObject:[ symbols addObject:[ [ NCObject alloc ] initWithVariable:[ parser tokenString ] type:typeOfArg ] ] ] ;
					}
					token = [ parser nextToken ] ;
					if ( token == RPAREN ) break ;	//  finish parsing argument list
					if ( token != COMMA ) {
						token = [ parser setError:@"expect arguments that are separated by commas" flush:YES ] ;
						return NO ;
					}
					token = [ parser nextToken ] ;
				}
			}
		}
	}
	//  skip past right parenthesis
	token = [ parser nextToken ] ;
	
	if ( token != LBRACE ) {
		body = nil ;
		token = [ parser setError:@"left brace expected for function body" flush:YES ] ;
		return NO ;
	}
	body = [ [ NCCompound alloc ] initWithParser:parser symbols:symbols enclosingFunction:self iterateLevel:0 ] ;
	success = [ body parse ] ;
	//  check for return statements
	NCStatement *p = [ body lastOp ] ;	
	if ( p == nil || [ p op ] != RETURNSTATEMENT ) {
		if ( !( type == MODELBLOCK || type == CONTROLBLOCK || type == VOIDTYPE ) ) {
			token = [ parser setErrorInPreviousLine:@"missing return statement" flush:NO ] ;
			return NO ;
		}
	}
	return success ;
}

- (Boolean)parse
{
	line = [ parser line ] ;
	if ( ![ self declarationList ] ) return NO ;
	[ functionObject setFunction:self ] ;
	return YES ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	NCValue *v ;
	
	stack = inStack ;
	if ( !body ) return nil ;
	
	v = [ body execute:stack asReference:asReference ] ;
	return v ;
}

//	v0.52 -- initialize local variables which are arguments (NSArray of NCValue)
- (NCValue*)execute:(RuntimeStack*)inStack initArguments:(NSArray*)args
{
	intType i, count ;
	NCValue *value ;
	
	count = [ args count ] ;
	//  sanity check (v0.76)
	if ( count > [ arguments count ] ) {
		NSLog( @"Internal error: function called with incorrect arguments?" ) ;
		count = [ arguments count ] ;
	}
	for ( i = 0; i < count; i++ ) {	
		value = [ args objectAtIndex:i ] ;
		[ [ arguments objectAtIndex:i ] put:value stack:inStack line:line ] ;
	}
	value = [ self execute:inStack asReference:NO ] ;	
	return value ;
}

- (char*)modelName
{
	return modelName ;
}

- (NSString*)functionName
{
	return functionName ;
}

//	v0.76 save stack frame to allow recursion
- (NSArray*)saveStackFrame
{
	intType i, argCount, localVariablesCount ;
	NSMutableArray *saved ;
	NSArray *localVariables ;
	NCObject *object ;
	
	argCount = [ arguments count ] ;
	localVariables = [ body localVariables ] ;
	localVariablesCount = ( localVariables == nil ) ? 0 : [ localVariables count ] ;
	
	saved = ( argCount > 0 || localVariablesCount > 0 ) ? [ [ NSMutableArray alloc ] init ] : nil ;	
	for ( i = 0; i < argCount; i++ ) {
		object = [ arguments objectAtIndex:i ] ;
		[ saved addObject:[ NCBasicValue basicValueWithValue:[ object value ] ] ] ;
	}
	for ( i = 0; i < localVariablesCount; i++ ) {
		object = [ localVariables objectAtIndex:i ] ;
		[ saved addObject:[ NCBasicValue basicValueWithValue:[ object value ] ] ] ;
	}
	return saved ;
}

//	v0.76 restore stack frame to allow recursion, and release the stackFrame NSArray
- (void)restoreStackFrame:(NSArray*)savedStackFrame
{
	intType i, argCount, localVariablesCount ;
	NSArray *localVariables ;
	NCObject *object ;
	
	if ( savedStackFrame != nil ) {
		argCount = [ arguments count ] ;
		for ( i = 0; i < argCount; i++ ) {
			object = [ arguments objectAtIndex:i ] ;
			[ [ object value ] setFromBasicValue:[ savedStackFrame objectAtIndex:i ] ] ;
		}
		localVariables = [ body localVariables ] ;
		localVariablesCount = ( localVariables == nil ) ? 0 : [ localVariables count ] ;

		for ( i = 0; i < localVariablesCount; i++ ) {
			object = [ localVariables objectAtIndex:i ] ;
			[ [ object value ] setFromBasicValue:[ savedStackFrame objectAtIndex:i+argCount ] ] ;
		}
		[ savedStackFrame release ] ;
	}
}


@end
