//
//  NCWire.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/20/07.
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


#import "NCElement.h"
#import "NCNode.h"
#import "NCExcitation.h"
#import "NCLoad.h"
#import "NCNetwork.h"
#import "NCTermination.h"

@interface NCWire : NCElement {
	double radius ;
	double originalRadius ;						//  v0.75 radius for NEC-2 can be modified by the insulate command
	int segments ;
	NCExcitation *feed ;
	int feedSegment ;							//  v0.55
	NSMutableArray *arrayOfLoads ;				//  v0.75
	NSMutableArray *arrayOfNetworks ;			//  v0.48
	RuntimeStack *runtime ;
	
	//  GM card parameters
	WireCoord translate ;
	WireCoord rotate ;
			
	int tagForCurrentSource ;
}

- (id)initWithRuntime:(RuntimeStack*)rt ;

//  v0.77
+ (NCGeometry*)vector:(NCWire*)w1 to:(NCWire*)w2 ;

- (void)setRadius:(double)value ;
- (void)modifyRadius:(double)value ;
- (double)radius ;
- (void)setSegments:(int)value ;
- (int)segments ;
- (int)feedSegment ;
- (void)setFeedSegment:(int)value ;

- (void)setTag:(int)value ;
- (int)tag ;

//  v0.55
- (void)setTranslate:(WireCoord*)coord ;
- (void)setRotate:(WireCoord*)coord ;
- (NSString*)gmCard;

- (void)setExcitation:(NCExcitation*)excitation segment:(int)seg ;
- (NCExcitation*)excitation ;

- (void)addLoad:(NCLoad*)inLoad ;
- (NSArray*)loads ;

//  v0.81
- (WireCoord)coordAtSegment:(int)segment ;
- (void)addTermination:(NCTermination*)inLoad ;

- (void)addNetwork:(NCNetwork*)ntwork ;
- (NCNetwork*)networkAtIndex:(int)i ;										//  v0.48

@end
