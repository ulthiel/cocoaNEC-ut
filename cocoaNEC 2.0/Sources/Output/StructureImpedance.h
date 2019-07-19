//
//  StructureImpedance.h
//  cocoaNEC
//
//  Created by Kok Chen on 4/16/08.
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

	#import <Cocoa/Cocoa.h>
	#import "coordinate.h"

	typedef struct {
		int tag ;
		int segment ;
		int type ;
	} LoadInfo ;

	@interface StructureImpedance : NSObject {
		LoadInfo g ;
	}
	
	- (id)initWithLine:(char*)string ;
	- (LoadInfo*)info ;
	- (int)tag ;
	
	//  type
	#define	DISTRIBUTED			0x80
	#define	FIXEDIMPEDANCE		1
	#define	LOADEDWIRE			( 2 | DISTRIBUTED )
	#define	PARALLEL			3
	#define	SERIES				4
	#define	DISTRIBUTEDPARALLEL	( 5 | DISTRIBUTED )
	#define	DISTRIBUTEDSERIES	( 6 | DISTRIBUTED )
	
	@end
