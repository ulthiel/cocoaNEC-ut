//
//  NCParser.m
//  cocoaNEC
//
//  Created by Kok Chen on 9/16/07.
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

#import "NCParser.h"
#import "awg.h"
#import "NCError.h"
#import "NCSymbolTable.h"


static int lexeme[] = {
	//					0			1			2			3			4			5			6			7			8			9			a			b			c			d			e			f
	/*  0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,		SPACE,		SPACE,			0,			0,		SPACE,			0,			0,		
	/* 10 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* 20 */		SPACE,	LOGICALNE,	   DQUOTE,		POUND,			0,		  MOD, LOGICALAND,			0,	   LPAREN,	   RPAREN,	 MULTIPLY,		 PLUS,		COMMA,		MINUS,		  DOT,	   DIVIDE,		
	/* 30 */		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,		  NUM,			0,	SEMICOLON,	LOGICALLT,	 ASSIGNEQ,	LOGICALGT,			0,		
	/* 40 */			0,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		
	/* 50 */		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,	 LBRACKET,			0,	 RBRACKET,			0,		ALPHA,		
	/* 60 */			0,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		
	/* 70 */		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,		ALPHA,	   LBRACE,	LOGICALOR,	   RBRACE,			0,			0,		
	/* 80 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* 90 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* a0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* b0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* c0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* d0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* e0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
	/* f0 */			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,			0,		
} ;

#define	lexi	lexeme[*ptr] 

@implementation NCParser


- (void)setupKeywords
{
	//  create keywords
	keywords = [ [ NSMutableDictionary alloc ] initWithCapacity:20 ] ;
	[ keywords setObject:[ NSNumber numberWithInt:MODELBLOCK ] forKey:@"model" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:CONTROLBLOCK ] forKey:@"control" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:INTTYPE ] forKey:@"int" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:REALTYPE ]  forKey:@"real" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:REALTYPE ]  forKey:@"float" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:STRINGTYPE ] forKey:@"string" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:ELEMENTTYPE ] forKey:@"element" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:COAXTYPE ] forKey:@"coaxtype" ] ;			//  v0.81b
	[ keywords setObject:[ NSNumber numberWithInt:VECTORTYPE ] forKey:@"vector" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:TRANSFORMTYPE ] forKey:@"transform" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:VOIDTYPE ] forKey:@"void" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:IFSTATEMENT ] forKey:@"if" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:ELSECLAUSE ] forKey:@"else" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:WHILESTATEMENT ] forKey:@"while" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:REPEATSTATEMENT ] forKey:@"repeat" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:BREAKSTATEMENT ] forKey:@"break" ] ;
	[ keywords setObject:[ NSNumber numberWithInt:RETURNSTATEMENT ] forKey:@"return" ] ;
}

- (id)initWithSource:(NSString*)characterStream compiler:(NCCompiler*)controllingCompiler
{
	self = [ super init ] ;
	if ( self ) {
		source = (const unsigned char*)[ characterStream UTF8String ] ;
		if ( source == nil ) return nil ;
		compiler = controllingCompiler ;
		line = 1 ;
		pass = 2 ;
		needAdvance = NO ;
		code = [ [ NSMutableArray alloc ] initWithCapacity:256 ] ;
		errorList = [ [ NSMutableArray alloc ] initWithCapacity:16 ] ;
		[ self setupKeywords ] ;
	}
	return self ;
}

//	v0.70 
- (NCCompiler*)compiler 
{
	return compiler ;
}

- (void)dealloc
{
	if ( code ) [ code release ] ;
	if ( errorList ) [ errorList release ] ;
	if ( keywords ) [ keywords release ] ;
	[ super dealloc ] ;
}

- (int)pass
{
	return pass ;
}

//  set up for a clean compile and return starting token
- (int)newCompile
{
	//  clear all errors from errorList array
	//  each object is an autoreleased NCError object
	[ errorList removeAllObjects ] ;
	//  remove code
	[ code removeAllObjects ] ;
	
	//  begin at start of stream and prime the token
	ptr = mark = source ;
	if ( *ptr == '\n' ) line++ ;		// count first newline
	
	return [ self nextToken ] ;
}

- (const char*)tokenString
{
	return (const char*)string ;
}

- (int)tokenInt
{
	return intValue ;
}

- (double)tokenReal
{
	return realValue ;
}

- (void)setMark
{
	mark = ptr ;
}

//  pop the mark and return next token
- (int)popMark
{
	ptr = mark ;
	return [ self nextToken ] ;
}

//  advance character
- (void)advance
{
	needAdvance = NO ;
	ptr++ ;
	if ( *ptr == '\n' ) line++ ;
}

//  parse for a symbol
- (int)parseSymbol
{
	NSNumber *keyword ;
	char *s = string ;
	int i ;
	
	for ( i = 0; i < 127; i++ ) {
		*s++ = *ptr ;
		[ self advance ] ;
		if ( lexi != ALPHA && lexi != NUM ) break ;
	}
	*s = 0 ;
	
	//  keyword search
	keyword = [ keywords objectForKey:[ NSString stringWithUTF8String:string ] ] ;
	if ( keyword != nil ) {
		token = [ keyword intValue ] ;
		return token ;
	}
	token = ALPHA ;

	return token ;
}

//  parse for a string (characters between double quotes)
- (int)parseString
{
	char *s = string ;
	int i ;
	
	[ self advance ] ;		// advance past left quote
	
	for ( i = 0; i < 250; i++ ) {
		if ( *ptr == '"' ) break ;
		if ( *ptr == '\r' || *ptr == '\n' ) {
			[ self setPass2Error:@"unterminated string (missing ending double quote)" flush:YES ] ;
			return ( token = ERRSTR ) ;
		}
		*s++ = *ptr++ ;
	}
	*s = 0 ;
	[ self advance ] ;
	return ( token = DQUOTE ) ;
}

//	v0.74 this used to be checkIntEnglish
//	added u, n and p suffixes
- (int)checkIntScaleSuffix:(long)num
{
	int c ;
	
	c = *ptr ;
	while ( c == SPACE ) c = *++ptr ;
	
	ptr++ ;
	tokenType = REALTYPE ;
	
	switch ( c ) {
	case '"':
		realValue = ( num*0.0254 ) ;
		return REAL ;
	case '\'':
		realValue = ( num*0.3048 ) ;
		return REAL ;
	case 'u':
		realValue = ( num*1e-6 ) ;
		return REAL ;
	case 'n':
		realValue = ( num*1e-9 ) ;
		return REAL ;
	case 'p':
		realValue = ( num*0.3048 ) ;
		return REAL ;
	}
	ptr-- ;
	tokenType = INTTYPE ;
	intValue = (int)num ;
	return NUM ;
}

//	v0.74 this used to be checkRealEnglish
//	added µ, n and p suffixes
- (int)checkRealScaleSuffix:(double)num
{
	int c ;
	
	c = *ptr ;
	while ( c == SPACE ) c = *++ptr ;
	
	tokenType = REALTYPE ;
	ptr++ ;		//  increment pointer in case we have suffix
	
	switch ( c ) {
	case '"':
		num *= 0.0254 ;
		break ;
	case '\'':
		num *= 0.3048 ;
		break ;
	case 'u':
		num *= 1e-6 ;
		break ;
	case 0xc2:
		if ( *ptr == 0xb5 ) {
			ptr++ ;
			num *= 1e-6 ;
			break ;
		}
		ptr -= 2 ;
		break ;
	case 'n':
		num *= 1e-9 ;
		break ;
	case 'p':
		num *= 1e-12 ;
		break ;
	default:
		ptr-- ;		//  no suffix, decrement pointer back
	}
	realValue = num ;		// return AWG radius in metric
	return REAL ;
}

//  v0.52
//  return token
- (int)parseNumberAsAWG:(Boolean)isAWG
{
	long prefix ;
	double result, post, exponent, expsign, places ;
	unsigned char c ;
	
	prefix = 0 ;
	c = *ptr ;
	while ( lexeme[c] == NUM && c != '.' ) {
		prefix = prefix*10 + ( c - '0' ) ;
		c = *++ptr ;
	}
	if ( c != '.' && c != 'e' && c != 'E' ) {
		//  end of number and not floating point
		if ( isAWG ) {
			tokenType = REALTYPE ;
			realValue = awg[ prefix ]*0.0254*0.5 ;		// return AWG radius in metric
			return ( token = REAL ) ;
		}
		else {
			token = [ self checkIntScaleSuffix:prefix ] ;
			return token ;
		}
	}	
	//  isAWG does not permit a floating point representation
	if ( isAWG ) {
		[ self setPass2Error:@"AWG number cannot have a decimal point" flush:YES ] ;
		return ERRTOKEN ;
	}

	post = exponent = 0 ;
	places = 1.0 ;
	result = prefix ;
	if ( c == '.' ) {
		c = *++ptr ;
		while ( lexeme[c] == NUM ) {
			post = post*10 + ( c - '0' ) ;
			c = *++ptr ;
			places *= 0.1 ;
		}	
		result = result + post*places ;
	}
	if ( c != 'e' && c != 'E' ) {
		token = [ self checkRealScaleSuffix:result ] ;
		return token ;
	}	
	//  e or E seen
	c = *++ptr ;
	expsign = 1 ;
	if ( c == '+' || c == '-' ) {
		if ( c == '-' ) expsign = -1 ;
		c = *++ptr ;
	}
	if ( lexeme[c] != NUM ) {
		[ self setPass2Error:@"Missing exponent after E in real number" flush:YES ] ;
		return ERRTOKEN ;
	}
	
	while ( lexeme[c] == NUM ) {
		exponent = exponent*10 + ( c - '0' ) ;
		c = *++ptr ;
	}
	ptr-- ;			//  v0.57
	token = [ self checkRealScaleSuffix:( result * pow( 10.0, exponent*expsign ) ) ] ;
	[ self advance ] ;
	return token ;
}

- (int)parseNumber
{
	return [ self parseNumberAsAWG:NO ] ;
}

- (int)parsePoundNumber
{
	unsigned char c ;
	Boolean isAWG ;
	
	c = *ptr ;
	isAWG = NO ;
	//  check prefix to see if it is an AWG number
	if ( c == '#' ) {
		c = *++ptr ;
		isAWG = YES ;
	}
	while ( lexeme[c] == SPACE ) c = *ptr++ ;
	if ( lexeme[c] != NUM ) {
		[ self setPass2Error:@"# not used for AWG wire size or #include" flush:YES ] ;
		return ERRTOKEN ;
	}
	return [ self parseNumberAsAWG:isAWG ] ;
}

- (int)currentLine
{
	return line ;
}

- (int)nextToken
{
	if ( needAdvance ) [ self advance ] ;

	while ( lexi == SPACE ) [ self advance ] ;
	
	switch ( lexi ) {
	case 0:
		needAdvance = YES ;
		return ( token = EOS ) ;
	case ALPHA:
		return [ self parseSymbol ] ;
	case NUM:
		return [ self parseNumber ] ;
	case POUND:
		return [ self parsePoundNumber ] ;
	case DOT:
		if ( lexeme[ *( ptr+1 ) ] == NUM ) return [ self parseNumber ] ;
		ptr++ ;
		token = DOT ;
		return token ;
	case DQUOTE:
		return [ self parseString ] ;
	case COMMA:
	case SEMICOLON:
	case LPAREN:
	case RPAREN:
	case LBRACE:
	case RBRACE:
	case LBRACKET:
	case RBRACKET:
	case MULTIPLY:
	case LOGICALOR:
	case LOGICALAND:
		// single character tokens
		needAdvance = YES ;
		token = lexi ;
		return token ;
	case ASSIGNEQ:
		token = lexi ;
		if ( *( ptr+1 ) == '=' ) {
			ptr++ ;
			token = LOGICALEQ ;
		}
		needAdvance = YES ;
		return token ;
	case LOGICALNE:
		token = lexi ;
		if ( *( ptr+1 ) == '=' ) {
			ptr++ ;
			needAdvance = YES ;
			return token ;
		}
		[ self advance ] ;
		break ;
	case LOGICALLT:
		token = lexi ;
		if ( *( ptr+1 ) == '=' ) {
			ptr++ ;
			token = LOGICALLE ;
		}
		needAdvance = YES ;
		return token ;
	case LOGICALGT:
		token = lexi ;
		if ( *( ptr+1 ) == '=' ) {
			ptr++ ;
			token = LOGICALGE ;
		}
		needAdvance = YES ;
		return token ;
	case DIVIDE:
		//  check for comments
		if ( *( ptr+1 ) == '/' ) return [ self flushline ] ;
		token = lexi ;
		needAdvance = YES ;
		return token ;
	case MOD:
		token = lexi ;
		needAdvance = YES ;
		return token ;
	case MINUS:
		token = lexi ;
		if ( *( ptr+1 ) == '-' ) {
			ptr++ ;
			token = DECR ;
		}
		needAdvance = YES ;
		return token ;
	case PLUS:
		token = lexi ;
		if ( *( ptr+1 ) == '+' ) {
			ptr++ ;
			token = INCR ;
		}
		needAdvance = YES ;
		return token ;
	default:
		printf( "*** unknown lex %x, need to enter into nextToken!\n", lexi ) ;
		[ self advance ] ;
		break ;
	}
	token = ERRTOKEN ;
	return token ;
}

- (int)currentCharacter
{
	return *ptr ;
}

- (int)token
{
	return token ;
}

//  return token after flushing
- (int)flushline
{
	while ( *ptr != '\n' ) ptr++ ;
	line++ ;
	return [ self nextToken ] ;
}

//  return token after flushing
- (int)setError:(NSString*)errorString flush:(Boolean)flush
{
	[ errorList addObject:[ NCError errorWithPointer:ptr string:errorString line:line ] ] ;
	if ( flush ) return [ self flushline ] ;
	return token ;
}

//	v0.53	don't emit error on preParse
- (int)setPass2Error:(NSString*)errorString flush:(Boolean)flush
{
	if ( pass != 2 ) return token ;
	return [ self setError:errorString flush:flush ] ;
}

- (int)setErrorInPreviousLine:(NSString*)errorString flush:(Boolean)flush
{
	[ errorList addObject:[ NCError errorWithPointer:ptr string:errorString line:line-2 ] ] ;
	if ( flush ) return [ self flushline ] ;
	return token ;
}

//  v0.52  merge preParser errors
- (void)mergeErrors:(NSArray*)otherErrors
{
	intType otherCount, errCount, i, j, otherLine ;
	NCError *other, *err ;
	
	otherCount = [ otherErrors count ] ;
	if ( otherCount <= 0 ) return ;
	
	errCount = [ errorList count ] ;
	if ( errCount <= 0 ) {
		[ errorList addObjectsFromArray:otherErrors ] ;
		return ;
	}
	
	//  inore otherErrors that already has a line in errList
	for ( i = 0; i < otherCount; i++ ) {
		other = [ otherErrors objectAtIndex:i ] ;
		otherLine = [ other line ] ;
		for ( j = 0; j < errCount; j++ ) {
			err = [ errorList objectAtIndex:j ] ;
			if ( otherLine == [ err line ] ) break ;	//  potentially duplicate error
		}
		if ( j >= errCount ) [ errorList addObject:other ] ;
	}
}

//  set a comment (for debugging)
- (void)setComment:(NSString*)errorString
{
	[ errorList addObject:[ NCError errorWithPointer:ptr string:errorString line:line ] ] ;
}

- (NSArray*)errors
{
	return errorList ;
}

- (int)lex
{
	return lexeme[*ptr] ;
}

- (const char*)tokenType:(int)tok
{
	switch ( tok ) {
	case VOIDTYPE:		//  v0.52
		return [ [ NSString stringWithFormat:@"void type definition" ] UTF8String ] ;
	case MODELBLOCK:
		return [ [ NSString stringWithFormat:@"model()" ] UTF8String ] ;
	case CONTROLBLOCK:
		return [ [ NSString stringWithFormat:@"control()" ] UTF8String ] ;
	case ALPHA:
		return [ [ NSString stringWithFormat:@"identifier %s", string ] UTF8String ] ;
	case NUM:
		return [ [ NSString stringWithFormat:@"integer constant %d", intValue ] UTF8String ] ;
	case REAL:
		return [ [ NSString stringWithFormat:@"real constant %f", realValue ] UTF8String ] ;
	case SEMICOLON:
		return [ [ NSString stringWithFormat:@"semicolon" ] UTF8String ] ;
	case COMMA:
		return [ [ NSString stringWithFormat:@"comma" ] UTF8String ] ;
	case DOT:
		return [ [ NSString stringWithFormat:@"dot" ] UTF8String ] ;
	case LPAREN:
		return [ [ NSString stringWithFormat:@"left parenthesis" ] UTF8String ] ;
	case RPAREN:
		return [ [ NSString stringWithFormat:@"right parenthesis" ] UTF8String ] ;
	case LBRACKET:
		return [ [ NSString stringWithFormat:@"left bracket" ] UTF8String ] ;
	case RBRACKET:
		return [ [ NSString stringWithFormat:@"right bracket" ] UTF8String ] ;
	case LBRACE:
		return [ [ NSString stringWithFormat:@"left brace" ] UTF8String ] ;
	case RBRACE:
		return [ [ NSString stringWithFormat:@"right brace" ] UTF8String ] ;
	case MINUS:
		return [ [ NSString stringWithFormat:@"minus" ] UTF8String ] ;
	case PLUS:
		return [ [ NSString stringWithFormat:@"plus" ] UTF8String ] ;
	case DECR:
		return [ [ NSString stringWithFormat:@"decrement" ] UTF8String ] ;
	case INCR:
		return [ [ NSString stringWithFormat:@"increment" ] UTF8String ] ;
	case ASSIGNEQ:
		return [ [ NSString stringWithFormat:@"assignment" ] UTF8String ] ;
	case LOGICALOR:
		return [ [ NSString stringWithFormat:@"logical OR" ] UTF8String ] ;
	case LOGICALAND:
		return [ [ NSString stringWithFormat:@"logical AND" ] UTF8String ] ;
	case LOGICALEQ:
		return [ [ NSString stringWithFormat:@"logical EQ" ] UTF8String ] ;
	case LOGICALNE:
		return [ [ NSString stringWithFormat:@"logical NE" ] UTF8String ] ;
	default:
		break ;
	}
	return [ [ NSString stringWithFormat:@"token 0x%x", tok ] UTF8String ] ;
}

- (void)printToken
{
	printf( "%s\n", [ self tokenType:token ] ) ;
}

- (int)line
{
	return line ;
}

@end
