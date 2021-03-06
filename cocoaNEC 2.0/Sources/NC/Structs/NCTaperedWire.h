//
//  NCTaperedWire.h
//  cocoaNEC
//
//  Created by Kok Chen on 4/27/08.
//	-----------------------------------------------------------------------------
//  Copyright 2008-2016 Kok Chen, W7AY. 
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

	#import "NCWire.h"


	@interface NCTaperedWire : NCWire {
		NCWire *subWire0, *subWire1 ;			//  sub wires in case we split taperedWire into 3 pieces
		double taper1, taper2 ;
		int actualSegments ;
	}

	- (void)setTaper1:(double)value ;
	- (double)taper1 ;
	- (void)setTaper2:(double)value ;
	- (double)taper2 ;

	- (void)setStartingTag:(int)value ;

	@end
