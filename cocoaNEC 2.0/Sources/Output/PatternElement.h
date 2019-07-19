//
//  PatternElement.h
//  cocoaNEC
//
//  Created by Kok Chen on 8/22/07.
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

	typedef struct {
		float theta ;
		float phi ;
		float dBv ;
		float dBh ;
		float dBt ;
		float dBl ;			//  v0.67 LHCP
		float dBr ;			//  v0.67 RHCP
	} PatternInfo ;

	@interface PatternElement : NSObject {
		PatternInfo w ;
		Boolean cached ;
		char line[160] ;
	}

	- (id)initWithLine:(char*)string ;
	- (PatternInfo)info ;
	
	- (Boolean)cachePattern ;
	
	@end
