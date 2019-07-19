//
//  Expression.h
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


#import <Cocoa/Cocoa.h>
#include <setjmp.h>

#import "Config.h"

typedef struct {
    int errorCode ;
    double value ;
    int errorOffset ;
    NSString *errorString ;
} EvalResult ;

@class Primary ;

@interface Expression : NSObject {

    NSDictionary *library ;
    NSDictionary *parameter ;
    NSDictionary *variable ;
    
    jmp_buf gRecoverToConsole ;
    //  lexical analyzer
    NSString *inputString ;
    int lex[256] ;
    const unsigned char *ptr, *begin ;
    //  syntax analysis
    int token ;
    double number ;
    NSString *symbol ;
    NSString *errorString ;
}

- (id)initWithLibrary:(NSDictionary*)libDict parameters:(NSDictionary*)paramDict variables:(NSDictionary*)varDict  ;

//- (EvalResult)eval:(NSString*)string ;

- (NSString*)error ;

- (double)expression ;
- (int)nextToken ;
- (double)nextUnaryExpression ;

@end
