//
//  NCExcitation.h
//  cocoaNEC
//
//  Created by Kok Chen on 9/22/07.
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

	#define	VOLTAGEEXCITATION	1
	#define	CURRENTEXCITATION	2
	#define	PLANEEXCITATION		3			//  v0.51
	#define	RIGHTEXCITATION		4			//  v0.51
	#define	LEFTEXCITATION		5			//  v0.51	
	#define	CURRENTPHASOR		6			//  v0.85
	#define	CURRENTPHASORD		7			//  v0.85
	
	
	@interface NCExcitation : NSObject {
		int type ;			
		double real ;
		double imag ;
		double theta ;
		double phi ;
		double eta ;
	}
	
	- (id)initWithType:(int)inType real:(double)r imag:(double)i ;
	- (id)initWithType:(int)inType theta:(double)t phi:(double)p eta:(double)e ;	//  v0.51

	
	- (int)excitationType ;
	- (double)real ;
	- (double)imag ;
	
	//  incident plane wave
	- (double)theta ;
	- (double)phi ;
	- (double)eta ;

	@end
