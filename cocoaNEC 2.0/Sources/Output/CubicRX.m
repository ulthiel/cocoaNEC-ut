//
//  CubicRX.m
//  cocoaNEC v0.70
//
//  Created by Kok Chen on 4/11/11.
//	-----------------------------------------------------------------------------
//  Copyright 2011-2016 Kok Chen, W7AY. 
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

#import "CubicRX.h"


@implementation CubicRX

- (void)createInterpolants:(RXF*)rxf
{
	// create cubic spline coeffients
	[ self computeCoefficients:rxf component:0 ] ;
	[ self computeCoefficients:rxf component:1 ] ;
}

//	return RX point using cubic interpolation
- (NSPoint)evaluate:(float)t
{
	int index ;
	NSPoint result ;
	
	index = t ;
	t -= index ;
	//  rescale parameter t
	t *= h[index] ;
	result.x = qa[index].x + ( qb[index].x + ( qc[index].x + qd[index].x*t )*t )*t ;
	result.y = qa[index].y + ( qb[index].y + ( qc[index].y + qd[index].y*t )*t )*t ;

	return result ;
}

@end
