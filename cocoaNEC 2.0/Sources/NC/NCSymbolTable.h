//
//  NCSymbolTable.h
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
#import "NCParser.h"
#import "Config.h"


@class NCObject ;
@class NCFunctionObject ;

@interface NCSymbolTable : NSObject {
    NCParser *parser ;
    NSMutableArray *actualArray ;
}

- (id)initWithCapacity:(int)capacity parser:(NCParser*)inParser ;
- (id)initWithSymbolTable:(NCSymbolTable*)globals parser:(NCParser*)inParser ;

- (NCObject*)addObject:(NCObject*)symbol ;
- (NCObject*)addFunctionObject:(NCFunctionObject*)symbol ;
    
- (NCObject*)containsObject:(NCObject*)object ;
- (NCObject*)containsIdent:(NSString*)ident ;

- (void)setDouble:(double)value forIdentifier:(NSString*)ident ;
    
- (intType)count ;
- (NCObject*)symbolAtIndex:(int)index ;
- (void)getObjects:(id*)aBuffer range:(NSRange)aRange ;

- (NSArray*)actualArray ;

//  debugging
- (void)dumpSymbols ;

	@end
