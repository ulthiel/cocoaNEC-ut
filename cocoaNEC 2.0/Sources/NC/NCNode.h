//
//  NCNode.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/17/07.
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
	#import "NCObject.h"
	#import "NCParser.h"
	#import "NCValue.h"
	#import "RuntimeStack.h"
	
	@interface NCNode : NSObject {
		char *nodeType ;
		NCSymbolTable *symbols ;
		NCParser *parser ;
		int token ;
		int line ;						//  line of source code where this object resides
		Boolean lvalue ;
		int type ;
		int op ;
		NCNode *left ;
		NCNode *right ;
		NCFunction *enclosingFunction ;
		RuntimeStack *stack ;
		int iterateLevel ;
	}

	- (id)initWithParser:(NCParser*)inParser symbols:(NCSymbolTable*)globals enclosingFunction:(NCFunction*)inFunction iterateLevel:(int)level ;
	- (id)clone:(NCNode*)clone ;
	
	- (Boolean)parse ;
	- (NCValue*)execute:(RuntimeStack*)stack asReference:(Boolean)asReference ;
	- (NCValue*)execute:(RuntimeStack*)stack initArguments:(NSArray*)args ;
	- (Boolean)lvalue ;
	- (int)type ;
	- (int)typeForBinaryOp:(NCNode*)left right:(NCNode*)right ;
	
	- (void)runtimeMessage:(NSString*)err ;
	
	- (NSString*)symbolName ;			//  name of underlying primary, if it makes sense
	
	- (NCObject*)ncObject ;
	
	- (const char*)nodeType ;
	
	//  for cloning
	- (NCSymbolTable*)symbols ;
	- (NCParser*)parser ;
	- (NCNode*)left ;
	- (NCNode*)right ;
	- (int)op ;
	- (int)line ;
	- (RuntimeStack*)stack ;
	- (int)iterateLevel ;
	
		

	@end
