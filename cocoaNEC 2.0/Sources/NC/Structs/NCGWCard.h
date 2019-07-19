//
//  NCGWCard.h
//  cocoaNEC
//
//  Created by Kok Chen on 5/30/09.
//	-----------------------------------------------------------------------------
//  Copyright 2009-2016 Kok Chen, W7AY. 
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

#import "NCCard.h"
#import "NCNode.h"

@interface NCGWCard : NCCard {
	double f1 ;
	double f2 ;
	double f3 ;
	double f4 ;
	double f5 ;
	double f6 ;
	double f7 ;
	int i1 ;
	int i2 ;
	int i3 ;
	int i4 ;

	RuntimeStack *runtime ;
}

- (id)initWithRuntime:(RuntimeStack*)rt ;

- (void)setF1:(double)value ;
- (void)setF2:(double)value ;
- (void)setF3:(double)value ;
- (void)setF4:(double)value ;
- (void)setF5:(double)value ;
- (void)setF6:(double)value ;
- (void)setF7:(double)value ;

- (void)setI1:(int)value ;
- (void)setI2:(int)value ;
- (void)setI3:(int)value ;
- (void)setI4:(int)value ;


@end
