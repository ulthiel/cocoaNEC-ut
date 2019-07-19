//
//  SavePanelExtension.h
//  cocoaNEC 2.0
//
//  Created by Kok Chen on 5/23/16.
//	-----------------------------------------------------------------------------
//  Copyright 2016 Kok Chen, W7AY. 
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

@interface SavePanelExtension : NSObject
{
}

//  v0.88 replace deprecated -runModalForDirectory: in 10.10
+ (NSInteger)runModalFor:(NSSavePanel*)panel directory:(NSString*)directory file:(NSString*)file types:(NSArray*)types ;
+ (NSInteger)runModalFor:(NSSavePanel*)panel directory:(NSString*)directory file:(NSString*)file ;


@end
