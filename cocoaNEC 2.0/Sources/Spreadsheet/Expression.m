//
//  Expression.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/1/07.
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

#import "Expression.h"
#import "ApplicationDelegate.h"
#import "tokens.h"
#import "Primary.h"
#import "awg.h"


@implementation Expression

static Boolean alpha( int a ) ;
static Boolean numer( int a ) ;


- (id)init
{
	int i, t ;
	
	self = [ super init ] ;
	if ( self ) {
		library = variable = parameter = nil ;
		errorString = [ [ NSString alloc ] initWithString:@"Unknown error" ] ;

		ptr = nil ;
		token = tok_SPACE ;
		
		for ( i = 0; i < 256; i++ ) {
			t = tok_ERR ;
			switch ( i ) {
			case ' ': t = tok_SPACE ; break ;
			case '\t': t = tok_SPACE ; break ;
			case '\n': t = tok_SPACE ; break ;
			case '\r': t = tok_SPACE ; break ;
			case ',': t = tok_COMMA ; break ;
			
			case '(': t = tok_LPAR ; break ;
			case ')': t = tok_RPAR ; break ;
			case '*': t = tok_MUL ; break ;
			case '%': t = tok_MOD ; break ;
			case '/': t = tok_DIV ; break ;
			case '+': t = tok_ADD ; break ;
			case '-': t = tok_SUB ; break ;
			case '!': t = tok_NOT ; break ;
			case '<': t = tok_LT ; break ;
			case '>': t = tok_GT ; break ;
			case '.': t = tok_NUMBER ; break ;
			case '#': t = tok_NUMBER ; break ;
			case '"': t = tok_INCH ; break ;
			case '\'': t = tok_FOOT ; break ;
			default:	
				if ( alpha( i ) ) {
					t = tok_IDENT ; 
					break ;
				}
				if ( numer( i ) ) {
					t = tok_NUMBER ; 
					break ;
				}
				if ( i == 0 || i == 255 ) t = tok_EOF ;
				break ;
			}
			lex[i] = t ;
		}
	}
	return self ;
}

- (id)initWithLibrary:(NSDictionary*)libDict parameters:(NSDictionary*)paramDict variables:(NSDictionary*)varDict
{
	[ self init ] ;
	library = libDict ;
	variable = varDict ;
	parameter = paramDict ;
	return self ;
}

/*
- (EvalResult)eval:(NSString*)string
{
    int errorCode = 0 ;
	EvalResult result ;

    errorCode = setjmp( gRecoverToConsole ) ;
    if ( errorCode == 0 ) {
		inputString = [ string retain ] ;
		ptr = begin = (unsigned char*)[ string UTF8String ] ;
		token = 'init' ; 
		[ self nextToken ];						// prime lexical analyzer, and
		result.value = [ self expression ] ;	//  evaluate expression

		if ( token != tok_EOF ) {
		
			char *code = (char*)&token ;
			printf( "*** bad expression with token %c%c%c%c\n", code[0], code[1], code[2], code[3] ) ;

			result.errorCode = tok_EXPR ;
			result.errorString = @"bad expression" ;
			result.errorOffset = ptr-begin ;
			[ inputString release ] ;
			return result ;
		}
		result.errorCode = 0 ;
		result.errorString = @"" ;
		result.errorOffset = 0 ;
		[ inputString release ] ;
		return result ;
    }
	result.errorCode = errorCode ;
	result.value = 0.0 ;
	result.errorOffset = ptr-begin ;
	result.errorString = errorString ;
	[ inputString release ] ;
    return result ;
}
*/

- (void)returnWithError:(int)errorNumber
{
	char *code ;

	switch ( errorNumber ) {
	case tok_IDENT:
		[ errorString autorelease ] ;
		errorString = [ NSString stringWithFormat:@"bad variable \"%s\"", [ symbol UTF8String ] ] ;
		break ;
	default:
		code = (char*)&errorNumber ;
		[ errorString autorelease ] ;
		errorString = [ NSString stringWithFormat:@"error with token %c%c%c%c", code[0], code[1], code[2], code[3] ] ;	
	}
	longjmp( gRecoverToConsole, errorNumber ) ;
}

- (NSString*)error
{
	return errorString ;
}

//  flush spaces and return lex
- (int)flushSpace
{
	while ( lex[*ptr] == tok_SPACE ) ptr++ ;
	if ( *ptr == 0 ) return ( token = tok_EOF ) ;
	return ( token = lex[*ptr++] ) ;
}

//  check for English units and convert to metric
- (double)checkEnglish:(double)num
{
	int c ;
	
	c = *ptr ;
	while ( lex[c] == tok_SPACE ) c = *++ptr ;
	
	if ( c == '"' ) {
		ptr++ ;
		return ( num*INCH ) ;
	}
	if ( c == '\'' ) {
		ptr++ ;
		return ( num*FEET ) ;
	}
	return num ;
}

//  parse number as an absolute or metric.  
//  look for # prefix as an AWG number, and ' and " postfix as English to metric conversion
- (double)parseNumber
{
	double pre, post, exponent, expsign, places ;
	unsigned char c ;
	Boolean isAWG ;
	
	c = *ptr ;
	isAWG = NO ;
	//  check prefix to see if it is an AWG number
	if ( c == '#' ) {
		c = *++ptr ;
		isAWG = YES ;
	}
	
	pre = 0 ;
	while ( lex[c] == tok_NUMBER && c != '.' ) {
		pre = pre*10 + ( c - '0' ) ;
		c = *++ptr ;
	}
	if ( c != '.' && c != 'e' && c != 'E' ) {
		if ( isAWG ) return awg[ (int)( pre+.01 ) ]*INCH*0.5 ;		// return AWG in metric
		return [ self checkEnglish:pre ] ;
	}
	
	//  iAWG does not permit a floating point representation
	if ( isAWG ) [ self returnWithError:tok_NUMBER ] ;
	
	post = exponent = 0 ;
	places = 1.0 ;
	if ( c == '.' ) {
		c = *++ptr ;
		while ( lex[c] == tok_NUMBER ) {
			post = post*10 + ( c - '0' ) ;
			c = *++ptr ;
			places *= 0.1 ;
		}	
		pre = pre + post*places ;
	}
	if ( c != 'e' && c != 'E' ) return [ self checkEnglish:pre ] ;	// float with decimal but no exponential
	
	//  e or E seen
	c = *++ptr ;
	expsign = 1 ;
	if ( c == '+' || c == '-' ) {
		if ( c == '-' ) expsign = -1 ;
		c = *++ptr ;
	}
	if ( lex[c] != tok_NUMBER ) [ self returnWithError:tok_NUMBER ] ;
	
	while ( lex[c] == tok_NUMBER ) {
		exponent = exponent*10 + ( c - '0' ) ;
		c = *++ptr ;
	}
	return [ self checkEnglish:( pre * pow( 10.0, exponent*expsign ) ) ] ;
}

- (NSString*)parseSymbol
{
	unsigned char c, local[128] ;
	int count ;
	
	count = 0 ;
	c = *ptr ;
	
	if ( lex[c] != tok_IDENT ) return @"" ;
	
	while ( lex[c] == tok_IDENT || lex[c] == tok_NUMBER ) {
		local[count++] = c ;
		if ( count >= 127 ) {
			[ self returnWithError:tok_IDENT ] ;
			return @"" ;
		}
		c = *++ptr ;
	}
	local[count] = 0 ;
	return [ NSString stringWithUTF8String:(char*)local ] ;
	
}

//  set the object variable token and also return it.
- (int)nextToken
{
	if ( token == tok_EOF || [ self flushSpace ] == tok_EOF ) return token ;
	
	if ( token == tok_NUMBER ) {
		ptr-- ;
		number = [ self parseNumber ] ;
		token = tok_NUMBER ;
		return token ;
	}
	if ( token == tok_IDENT ) {
		ptr-- ;
		symbol = [ self parseSymbol ] ;
		token = tok_IDENT ;
		return token ;
	}
	return token ;
}

//  get next token and call expression
- (double)expressionForNextToken
{
	[ self nextToken ] ;
	return [ self expression ] ;
}

//  primary expression: evaluates a variable or a function with zero, one or two arguments.
- (double)primaryExpression:(Primary*)primary
{
	double arg, arg2, p = 0 ;
	int argc, type ;
	
	type = [ primary type ] ;
	
	if ( type == primary_FUNC ) {
		//  look for left paren for function
		[ self nextToken ] ;
		if ( token != tok_LPAR ) [ self returnWithError:tok_LPAR ] ;	
		[ self nextToken ] ;
		argc =  [ primary arguments ] ;
		
		switch ( argc ) {
		case 0:
			p = [ primary doubleValue ] ;
			break ;
		case 1:
			arg = [ self expression ] ;
			p = [ primary doubleValue:arg ] ;
			break ;
		case 2:
			arg = [ self expression ] ;
			if ( token != tok_COMMA ) [ self returnWithError:tok_COMMA ] ;	
			arg2 = [ self expression ] ;
			p = [ primary doubleValue:arg with:arg2 ] ;
			break ;
		default:
			[ self returnWithError:tok_FUNC ] ;
		}
		//  look for right paren for function
		if ( token != tok_RPAR ) [ self returnWithError:tok_IDENT ] ;	
		return p ;
	}
	if ( type == primary_VAR ) return [ primary doubleValue ] ;

	[ self returnWithError:tok_IDENT ] ;
	return 0.0 ;
}

- (double)unaryExpression
{
	int op ;
	double p = 0 ;
	Primary *primary ;
	NSNumber *num ;
	
	if ( token == tok_ADD || token == tok_SUB ) {
		op = token ;
		return ( ( op == tok_SUB ) ? -1.0 : 1.0 ) * [ self nextUnaryExpression ] ;
	}
	switch ( token ) {
	case tok_LPAR:
		[ self nextToken ] ;
		p = [ self expression ] ;
		if ( token == tok_RPAR ) break ;
		[ self returnWithError:tok_RPAR ] ;
		break ;
	case tok_NUMBER:
		p = number ;
		break ;
	case tok_IDENT:
		//  check library
		primary = nil ;
		if ( library != nil ) primary = [ library objectForKey:symbol ] ;
		if ( primary == nil ) {
			num = nil ;
			if ( parameter != nil ) num = [ parameter objectForKey:symbol ] ;
			if ( num != nil ) {
				//  parameter value found, now create a primary for it (and autorelease it)
				primary = [ [ Primary alloc ] initWithDouble:[ num doubleValue ] ] ;
				if ( primary ) [ primary autorelease ] ;
			}
			else primary = [ variable objectForKey:symbol ] ;
		}
		if ( primary == nil ) [ self returnWithError:tok_IDENT ] ;
		p = [ self primaryExpression:primary ] ;
		break ;
	}
	[ self nextToken ] ;
	return p ;
}

- (double)nextUnaryExpression
{
	[ self nextToken ] ;
	return [ self unaryExpression ] ;
}

- (double)nextMultiplicativeExpression
{
	double p, q ;
	int op, n ;
	
	p = [ self nextUnaryExpression ] ;
	switch ( token ) {
	case tok_MUL:
	case tok_DIV:
	case tok_MOD:
		op = token ;
		q = [ self nextUnaryExpression ] ;
		switch ( op ) {
		case tok_MUL:
			return p*q ;
		case tok_DIV:
			if ( fabs( q ) < 1.0e-12 ) [ self returnWithError:op ] ;
			return ( p / q ) ;
		default:
			n = q + 1.0e-9 ;
			if ( n <= 0 ) [ self returnWithError:op ] ;
			return ( (int)p % n )*1.0 ;
		}
		break ;
	}
	return p ;
}

- (double)expression
{
	double p, q ;
	int n ;
	
	printf( "expression called\n" ) ;
	
	 p = [ self unaryExpression ] ;	
	 
	while ( 1 ) {
		switch ( token ) {
		default:
		case tok_EOF:
			return p ;
		case tok_ADD:
			p += [ self nextMultiplicativeExpression ] ;
			break ;
		case tok_SUB:
			p -= [ self nextMultiplicativeExpression ] ;
			break ;
		case tok_MUL:
			p *= [ self nextUnaryExpression ] ;
			break ;
		case tok_DIV:
			q = [ self nextUnaryExpression ] ;
			if ( fabs( q ) < 1.0e-12 ) [ self returnWithError:tok_DIV ] ;
			return( p / q ) ;
		case tok_MOD:
			n = [ self nextUnaryExpression ] + 1.0e-9 ;
			if ( n <= 0 ) [ self returnWithError:tok_MOD ] ;
			return ( (int)p % n )*1.0 ;
		}
	}
	return p ;
}

static Boolean alpha( int a )
{
	if ( a >= 'a' && a <= 'z' ) return true ;
	if ( a >= 'A' && a <= 'Z' ) return true ;
	return ( a == '_' ) ;
}

static Boolean numer( int a )
{
	return ( a >= '0' && a <= '9' ) ;
}

@end
