//
//  NCFunction.h
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

#import <Cocoa/Cocoa.h>
#import "NCNode.h"
#import "NCFunctionObject.h"

@class NCCompound ;

@interface NCFunction : NCNode {
    NCFunctionObject *functionObject ;
    NCFunctionObject *forwardReference ;
    NSMutableArray *arguments ;				// v0.76 array of NCObjects (was static NCObjects)
    Boolean isModel, isControl ;		
    NCCompound *body ;		
    //  for model
    char modelName[256] ;
    NSString *functionName ;
}

- (id)initWithParser:(NCParser*)inParser type:(int)type globals:(NCSymbolTable*)globals iterateLevel:(int)level ;
- (NCObject*)functionObject ;
- (char*)modelName ;
- (NSString*)functionName ;
//  v0.76: save into and restore from NSArray of NCValues
//  These two methods should be used in pairs, surround a function call, to save the enclosing functions's stack values.
//	restoreStackFrame releases the NSArray after restoring the values.
- (NSArray*)saveStackFrame ;
- (void)restoreStackFrame:(NSArray*)savedStackFrame ;

@end
