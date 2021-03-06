//
//  NCHelix.h
//  cocoaNEC
//
//  Created by Kok Chen on 6/19/09.
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

#import "NCArc.h"


@interface NCHelix : NCArc {
	double turnsSpacing ;
	double helixLength ;
	double startRadius ;
	double endRadius ;
}

- (void)setTurnsSpacing:(double)value ;
- (void)setHelixLength:(double)value ;
- (void)setStartRadius:(double)x ;
- (void)setEndRadius:(double)x ;

@end
