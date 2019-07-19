//
//  CurrentSource.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/10/07.
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

	#import "WireGeometry.h"
	#import "Expression.h"

	//  Note: this entire class has been deprecated

	@interface CurrentSource : WireGeometry {
		WireGeometry *attachedToWire ;
		intType targetTag ;
		intType targetSegment ;
		double from[3] ;
		double to[3] ;
		double unitVector[3] ;
		double current[2] ;
	}
	
	- (id)initAsAttachmentTo:(WireGeometry*)wire ;
	
	- (NSArray*)geometryCards:(Expression*)e tag:(int)tag displacement:(double)d ;
	- (NSArray*)generateExcitationAndNetwork ;
	
	- (intType)targetTag ;
	- (intType)targetSegment ;
	
	@end
