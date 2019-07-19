//
//  NCPostfix.m
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

#import "NCPostfix.h"
#import "AlertExtension.h"
#import "ApplicationDelegate.h"
#import "NCElement.h"
#import "NCFunction.h"
#import "NCFunctionObject.h"
#import "NCSymbolTable.h"

@implementation NCPostfix


- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)symbolList enclosingFunction:(NCFunction*)function iterateLevel:(int)level
{
	self = [ super initWithParser:inParser symbols:symbolList enclosingFunction:function iterateLevel:iterateLevel ] ;
	if ( self ) {
		primary = nil ;
		arguments = nil ;
		nodeType = "Postfix" ;
		nsObject = nil ;
	}
	return self ;
}

- (void)dealloc
{
	if ( primary ) [ primary release ] ;
	if ( arguments ) [ arguments release ] ;
	[ super dealloc ] ;
}

static int shortlen( short *p )
{
	int count = 0, i ;
	
	for ( i = 0; i < 64; i++ ) {
		if ( *p++ == 0 ) return count ;
		count++ ;
	}
	return count ;
}

- (Boolean)parse
{
	NCFunctionObject *ncFunctionObject ;
	NCObject *ncObject ;
	NCExpression *expr ;
	intType argumentsUsedInFunction, argType ;
	short *functionArgPrototypes ;
	
	op = 0 ;
	token = [ parser token ] ;
	line = [ parser line ] ;

	primary = [ [ NCPrimary alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
	if ( primary && [ primary parse ] ) {
		token = [ parser token ] ;
		switch ( token ) {
		case LBRACKET:								//  v0.54
			op = LBRACKET ;							//  array dereferencing
			[ parser nextToken ] ;
			arrayIndex = [ [ NCExpression alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
			[ arrayIndex parse ] ;
			argType = [ arrayIndex type ] ;
			if ( argType != INTTYPE ) {
				[ parser setError:@"syntax error: array index needs to be an integer" flush:YES ] ;
				return NO ;
			}
			token = [ parser token ] ;
			if ( token != RBRACKET ) {
				[ parser setError:@"syntax error: closing bracket for array index not found?" flush:YES ] ;
				return NO ;
			}
			token = [ parser nextToken ] ;
			ncObject = [ primary ncObject ] ;
			type = [ ncObject arrayType ] ;
			lvalue = ( ( type == INTTYPE ) || ( type == REALTYPE ) || ( type == ELEMENTTYPE ) || ( type == COAXTYPE ) || ( type == VECTORTYPE ) || ( type == TRANSFORMTYPE ) ) ;	//  v0.81b
			return YES ;
		/*
		case INCR:
		case DECR:
			if ( [ primary lvalue ] ) {
				op = ( token == INCR ) ? POSTINCR : POSTDECR ;
				type = [ primary type ] ;
				[ parser nextToken ] ;
				return YES ;
			}
			primary = nil ;
			//  post increment or post decrement
			[ parser setError:@"syntax error:cannot increment/decrement a non-identifier" flush:YES ] ;
			return NO ;
		*/
		case LPAREN:
			//  function call
			ncFunctionObject = (NCFunctionObject*)[ primary ncObject ] ;
			if ( ncFunctionObject == nil || [ ncFunctionObject isFunction ] == NO ) {
				// primary is not an identifier
				[ parser setError:@"syntax error: function call being made to a non-function" flush:YES ] ;
				return NO ;
			}
			op = FUNCTION ;
			arguments = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
			while ( 1 ) {
				token = [ parser nextToken ] ;
				if ( token != RPAREN ) {
					// there are arguments
					expr = [ [ NCExpression alloc ] initWithParser:parser symbols:symbols enclosingFunction:enclosingFunction iterateLevel:iterateLevel ] ;
					if ( ![ expr parse ] ) {
						[ parser setError:@"syntax error in error list" flush:YES ] ;
						[ arguments release ] ;
						arguments = nil ;
						return NO ;
					}
					[ arguments addObject:expr ] ;
					[ expr release ] ;						//  v0.64q
					token = [ parser token ] ;
				}
				if ( token == RPAREN ) {
					//  done with arguments of function
					token = [ parser nextToken ] ;
					argumentsUsedInFunction = [ arguments count ] ;
					functionArgPrototypes = [ ncFunctionObject argPrototypes ] ;
					//  check if number of arguments is correct, or function takes a VARARG
					if ( functionArgPrototypes[0] != VARARGS && argumentsUsedInFunction != shortlen( functionArgPrototypes ) ) {
						[ parser setError:[ NSString stringWithFormat:@"function '%s' is called with incorrect number of arguments", [ [ ncFunctionObject name ] UTF8String ] ] flush:YES ] ;
						return NO ;
					}
					type = [ ncFunctionObject type ] ;
					return YES ;
				}
				if ( token != COMMA ) break ;
				//  more items in argument list.  Note thatthe beginning of this while look will flush the comma
			}
			[ parser setError:[ NSString stringWithFormat:@"syntax error in argument list of function, token = %s", [ parser tokenType:token ] ] flush:YES ] ;
			return NO ;
		default:
			//  is just a simple primary -- inherit properties
			lvalue = [ primary lvalue ] ;
			type = [ primary type ] ;
			return YES ;
 		}
	}
	primary = nil ;
	return NO ;
}

- (NSString*)symbolName
{
	if ( primary ) return [ primary symbolName ] ;
	return [ super symbolName ] ;
}

- (NCObject*)ncObject
{
	if ( op != 0 ) return nil ;
	if ( op == LBRACKET ) return nsObject ;
	if ( primary ) return [ primary ncObject ] ;
	return nil ;
}

//  (Private API)
- (NCObject*)getArrayReference:(RuntimeStack*)inStack	
{
	NCValue *exprValue, *argValue ;
	int index ;
	
	exprValue = [ primary execute:inStack asReference:YES ] ;					//  array ptr
	argValue = [ arrayIndex execute:inStack asReference:NO ] ;					//  array index
	
	if ( [ exprValue type ] != ARRAYTYPE || [ argValue type ] != INTTYPE ) {
		return [ NCValue undefinedValue ] ;
	}
	index = [ argValue intValue ] ;
	if ( index < 0 || index >= [ exprValue arrayDimension ] ) {
        NSString *info = [ NSString stringWithFormat:@"\nThe array '%s' is deferenced with an out of bounds index %d.\n\nUsing array[0].\n\n", [ [ [ primary ncObject ] name ] UTF8String ], index ] ;
        
        [ AlertExtension modalAlert:@"Runtime error." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
		return [ exprValue elementAtIndex:0 ] ;
	}
	return [ exprValue elementAtIndex:index ] ;
}

- (NCValue*)execute:(RuntimeStack*)inStack asReference:(Boolean)asReference
{
	NCFunctionObject *ncFunctionObject ;
	NSMutableArray *argList ;
	NSArray *stackFrame ;
	NCElement *element ;
	NCCoax *coax ;
	NCVector *vector ;
	NCTransform *transform ;
	NC *nc ;
	NCNode *node ;
	NCValue *exprValue ;
	NCSystem *system ;
	Boolean isRunModelFunction ;	//  v0.76
	int i, callResult ;
    intType count ;
	double dv ;
	char order[24] ;

	stack = inStack ;
	argList = nil ;
	
	switch ( op ) {
	case 0:
		return [ primary execute:stack asReference:asReference ] ;	
	case LBRACKET:											//  v0.54 
		nsObject = [ self getArrayReference:inStack ] ;
		if ( asReference == YES ) {
			return [ NCValue valueWithNCObject:nsObject ] ;
		}
		//  dereference nsObject
		return [ nsObject value ] ;
	case FUNCTION:
		ncFunctionObject = (NCFunctionObject*)[ primary ncObject ] ;
		if ( [ ncFunctionObject isFunction ] == NO ) {
			//  sanity check
			[ self runtimeMessage:[ NSString stringWithFormat:@"Internal error -- trying to call '%s' as a function", [ [ ncFunctionObject name ] UTF8String ] ] ] ;
			return [ NCValue undefinedValue ] ;
		}
		count = [ arguments count ] ;
		
		argList = [ [ NSMutableArray alloc ] initWithCapacity:count ] ;
		for ( i = 0; i < count; i++ ) {
			node = [ arguments objectAtIndex:i ] ;
			exprValue = [ node execute:stack asReference:NO ] ;		//  get value of each argument
			if ( exprValue == nil ) {
				switch ( i+1 ) {
				case 1:
					sprintf( order, "first" ) ; 
					break ;
				case 2:
					sprintf( order, "2nd" ) ; 
					break ;
				case 3:
					sprintf( order, "3rd" ) ; 
					break ;
				default:
					sprintf( order, "%dth", i ) ; 
					break ;
				}
                NSString *info = [ NSString stringWithFormat:@"\nThe value of the %s argument that is passed into function '%s' at line %d has not been previously defined.\n\n", order, [ [ ncFunctionObject name ] UTF8String ], line ] ;
                
				[ AlertExtension modalAlert:@"Runtime error." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:info ] ;
				exprValue = [ NCValue valueWithInt:0 ] ;
				[ stack->errors addObject:@"Bad function arguments" ] ;
			}
			[ argList addObject:exprValue ] ;
		}
		if ( type == INTTYPE ) {
			isRunModelFunction = [ ncFunctionObject isRunModelFunction ] ;
			if ( isRunModelFunction ) {
				//  initialize NEC variables
				[ symbols setDouble:0.0 forIdentifier:@"directivity" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"maxGain" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"averageGain" ] ;			//  v0.62
				[ symbols setDouble:100.0 forIdentifier:@"efficiency" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"azimuthAngleAtMaxGain" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"elevationAngleAtMaxGain" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"frontToBackRatio" ] ;
				[ symbols setDouble:0.0 forIdentifier:@"frontToRearRatio" ] ;
			}
			stackFrame = [ enclosingFunction saveStackFrame ] ;	//  v0.76
			callResult = [ ncFunctionObject evalFunctionAsInt:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			exprValue = [ NCValue valueWithInt:callResult ] ;
			
			if ( isRunModelFunction && callResult != 0 ) {
				nc = [ (ApplicationDelegate*)[ NSApp delegate ] currentNC ] ;
				if ( nc ) {
					NECInfo *nec = [ nc necResults ] ;
					//  collect results 
					[ symbols setDouble:nec->directivity forIdentifier:@"directivity" ] ;
					[ symbols setDouble:nec->efficiency forIdentifier:@"efficiency" ] ;
					[ symbols setDouble:nec->maxGain forIdentifier:@"maxGain" ] ;
					[ symbols setDouble:nec->averageGain forIdentifier:@"averageGain" ] ;	//  v0.62
					[ symbols setDouble:nec->azimuthAngleAtMaxGain forIdentifier:@"azimuthAngleAtMaxGain" ] ;
					[ symbols setDouble:nec->elevationAngleAtMaxGain forIdentifier:@"elevationAngleAtMaxGain" ] ;
					[ symbols setDouble:nec->frontToBackRatio forIdentifier:@"frontToBackRatio" ] ;
					[ symbols setDouble:nec->frontToRearRatio forIdentifier:@"frontToRearRatio" ] ;
				}
			}
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return exprValue ; 
		}
		if ( type == REALTYPE ) {
			system = [ (ApplicationDelegate*)[ NSApp delegate ] currentNCSystem ] ;
			if ( system ) {
				stackFrame = [ enclosingFunction saveStackFrame ] ;	//  v0.76
				dv = [ ncFunctionObject evalFunctionAsReal:stack args:argList system:system ] ;
				[ enclosingFunction restoreStackFrame:stackFrame ] ;
			}
			else dv = 00 ;
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return [ NCValue valueWithDouble:dv ] ;
		}
		if ( type == ELEMENTTYPE ) {
			stackFrame = [ enclosingFunction saveStackFrame ] ;		//  v0.76
			element = [ ncFunctionObject evalFunctionAsElement:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			//  add geometry to array
			//  NOTE: do not generate element when user defined element function ([ symbol function ] != nil ) is executed
			if ( element && [ ncFunctionObject function ] == nil ) {
				[ stack->geometryElements addObject:element ] ;
				[ element release ] ;								//  v0.64 (retained by stack)
			}
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return [ NCValue valueWithElement:element ] ;
		}
		if ( type == COAXTYPE ) {									//  v0.81b
			stackFrame = [ enclosingFunction saveStackFrame ] ;		
			coax = [ ncFunctionObject evalFunctionAsCoax:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			if ( argList != nil ) [ argList release ] ;
			return [ NCValue valueWithCoax:coax ] ;
		}
		if ( type == VECTORTYPE ) {
			stackFrame = [ enclosingFunction saveStackFrame ] ;		//  v0.76
			vector = [ ncFunctionObject evalFunctionAsVector:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			exprValue = [ NCValue valueWithVector:vector ] ;
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return exprValue ;
		}
		if ( type == TRANSFORMTYPE ) {
			stackFrame = [ enclosingFunction saveStackFrame ] ;		//  v0.76
			transform = [ ncFunctionObject evalFunctionAsTransform:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return [ NCValue valueWithTransform:transform ] ;
		}
		if ( type == CARDTYPE ) {
			stackFrame = [ enclosingFunction saveStackFrame ] ;		//  v0.76
			element = [ ncFunctionObject evalFunctionAsCard:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			//  add geometry to array
			if ( element ) {
				[ stack->geometryElements addObject:element ] ;
			}
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return [ NCValue valueWithInt:0 ] ;
		}
		if ( type == VOIDTYPE ) {
			stackFrame = [ enclosingFunction saveStackFrame ] ;		//  v0.76
			[ ncFunctionObject evalFunctionAsVoid:stack args:argList ] ;
			[ enclosingFunction restoreStackFrame:stackFrame ] ;
			if ( argList != nil ) [ argList release ] ;				//  v0.64
			return [ NCValue valueWithInt:0 ] ;
		}
		break ;
	default:
		printf( "NCPostFix evaluate needs to implement op %x\n", op ) ;
	}
	return [ NCValue undefinedValue ] ;
}


@end
