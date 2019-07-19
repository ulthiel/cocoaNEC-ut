//
//  NCTerminationF.h
//  cocoaNEC
//
//  Created by Kok Chen on 11/12/12.
//	-----------------------------------------------------------------------------
//  Copyright 2012-2016 Kok Chen, W7AY. 
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

@class NCWire ;
@class NCSystem ;

//	Frequency dependent Terminator
@interface NCTerminationF : NSObject {
	NCWire *terminationWire ;		//  short wire in farfield that contains the TL for termination
}

+ (id)rlcTermination:(NCWire*)wire type:(int)rlcType r:(double)r l:(double)l c:(double)c system:(NCSystem*)system ;


@end
