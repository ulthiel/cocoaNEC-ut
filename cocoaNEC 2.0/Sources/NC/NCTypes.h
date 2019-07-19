/*
 *  NCTypes.h
 *  cocoaNEC
 *
 *  Created by Kok Chen on 9/21/07.
 *
 */

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

	#define		ERRSTR			(-2)				//  unterminated string
	#define		ERRTOKEN		(-1)
	#define		LEXPREFIX		0x7fc0
	
	//  simple tokens
	#define		EOS				0
	#define		SPACE			1
	
	#define		TYPEP			0x40
	#define		ADDRESSP		0x80

	#define		INTTYPE			( TYPEP | 0x2 )
	#define		REALTYPE		( TYPEP | 0x3 )
	#define		STRINGTYPE		( TYPEP | 0x4 )
	#define		ELEMENTTYPE		( TYPEP | 0x5 )			//  e.g., "int segs ; element reflector" ;
	#define		VECTORTYPE		( TYPEP | 0x6 )
	#define		TRANSFORMTYPE	( TYPEP | 0x7 )
	#define		VOIDTYPE		( TYPEP | 0x8 )
	#define		ARRAYTYPE		( TYPEP | 0x9 )
	#define		CARDTYPE		( TYPEP | 0xa )
	#define		MODELBLOCK		( TYPEP | 0xb ) 
	#define		CONTROLBLOCK	( TYPEP | 0xc ) 
	#define		OBJECTTYPE		( TYPEP | 0xd )
	#define		COAXTYPE		( TYPEP | 0xe )			// v0.81b
	#define		VARARGS			( TYPEP | 0xf )
	

	//   primary object
	#define		PRIMARY			0x100

	#define		ALPHA			( PRIMARY | 0x1 )
	#define		NUM				( PRIMARY | 0x2 )
	#define		REAL			( PRIMARY | 0x3 )
	#define		POUND			( PRIMARY | 0x4 )
	#define		DOT				( PRIMARY | 0x5 )
	
	//  expression objects
	#define		EXPRS			0x200

	#define		LOGICALOR		( EXPRS | 0x1 )
	#define		LOGICALAND		( EXPRS | 0x2 )
	#define		LOGICALEQ		( EXPRS | 0x3 )
	#define		LOGICALNE		( EXPRS | 0x4 )
	#define		LOGICALLT		( EXPRS | 0x5 )
	#define		LOGICALLE		( EXPRS | 0x6 )
	#define		LOGICALGT		( EXPRS | 0x7 )
	#define		LOGICALGE		( EXPRS | 0x8 )
	#define		ADDITIVE		( EXPRS | 0x9 )
	#define		MULTIPLICATIVE	( EXPRS | 0xa )
	#define		UNARY			( EXPRS | 0xb )

	//  tokens
	#define		OTHERP			0x400
	
	#define		COMMA			( OTHERP | 0x1 )
	#define		SEMICOLON		( OTHERP | 0x2 )
	#define		LPAREN			( OTHERP | 0x3 )
	#define		RPAREN			( OTHERP | 0x4 )
	#define		DQUOTE			( OTHERP | 0x5 )
	#define		LBRACE			( OTHERP | 0x6 )
	#define		RBRACE			( OTHERP | 0x7 )
	#define		MINUS			( OTHERP | 0x8 )
	#define		PLUS			( OTHERP | 0x9 )
	#define		MULTIPLY		( OTHERP | 0xa )
	#define		DIVIDE			( OTHERP | 0xb )
	#define		MOD				( OTHERP | 0xc )
	#define		INCR			( OTHERP | 0xd )
	#define		DECR			( OTHERP | 0xe )
	#define		POSTINCR		( OTHERP | 0xf )
	#define		POSTDECR		( OTHERP | 0x10 )
	#define		FUNCTION		( OTHERP | 0x11 )
	#define		LBRACKET		( OTHERP | 0x12 )			//  v0.54
	#define		RBRACKET		( OTHERP | 0x13 )			//  v0.54
	#define		MEMBER			( OTHERP | 0x14 )			//  v0.53
	
	//  compound statements
	#define		STATEMENT		0x800
	
	#define		IFSTATEMENT		( STATEMENT | 0x1 )
	#define		ELSECLAUSE		( STATEMENT | 0x2 )
	#define		WHILESTATEMENT	( STATEMENT | 0x3 )
	#define		BREAKSTATEMENT	( STATEMENT | 0x4 )
	#define		REPEATSTATEMENT	( STATEMENT | 0x5 )
	#define		COMPOUND		( STATEMENT | 0x6 )
	#define		RETURNSTATEMENT	( STATEMENT | 0x7 )
	
	//  asignment statements
	#define		ASSIGN			0x1000
	
	#define		ASSIGNEQ		( ASSIGN | 0x1 ) 
