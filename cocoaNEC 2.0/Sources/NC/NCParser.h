//
//  NCParser.h
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

	#import <Cocoa/Cocoa.h>
	#import "NCTypes.h"

	@class NCSymbolTable ;
	@class NCCompiler ;
	
	@interface NCParser : NSObject {
		NCCompiler *compiler ;						//  v0.70
		const unsigned char *source, *ptr, *mark ;
		int line ;
		NSMutableArray *errorList ;
		NSMutableArray *code ;
		NSMutableDictionary *keywords ;
		int token ;
		//  token properties
		char string[256] ;
		Boolean needAdvance ;
		int tokenType ;								// INTTYPE, REALTYPE, etc
		int intValue ;
		double realValue ;
		int pass ;									//  pass 1 = preParse, 2 = parse
	}
	
	- (id)initWithSource:(NSString*)characterStream compiler:(NCCompiler*)controllingCompiler ;
	- (void)setupKeywords ;
	
	- (NCCompiler*)compiler ;						//  v0.70
	- (int)newCompile ;
	- (const char*)tokenString ;
	- (void)printToken ;
	- (int)tokenInt ;
	- (double)tokenReal ;
	
	- (int)pass ;
	
	- (int)nextToken ;
	- (int)token ;
	- (int)line ;
	- (int)currentCharacter ;						//  v0.54
	- (int)currentLine ;							//  v0.54
	
	- (void)setMark ;
	- (int)popMark ;
	
	- (int)setError:(NSString*)errorString flush:(Boolean)flush ;
	- (int)setErrorInPreviousLine:(NSString*)errorString flush:(Boolean)flush ;
	- (int)setPass2Error:(NSString*)errorString flush:(Boolean)flush ;		//  v0.53
	- (const char*)tokenType:(int)tok ;
	- (void)setComment:(NSString*)errorString ;
	- (NSArray*)errors ;
	- (void)mergeErrors:(NSArray*)otherErrors ;
	- (int)flushline ;

	@end
