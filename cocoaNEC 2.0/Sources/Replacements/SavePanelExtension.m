//
//  SavePanelExtension.m
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

#import "SavePanelExtension.h"

@implementation SavePanelExtension

//  v0.88 replace deprecated -runModalForDirectory: in 10.10
+ (NSInteger)runModalFor:(NSSavePanel*)panel directory:(NSString*)directory file:(NSString*)file types:(NSArray*)types
{
    if ( file != nil ) [ panel setNameFieldStringValue:file ] ;
    if ( directory != nil ) [ panel setDirectoryURL:[ NSURL fileURLWithPath:directory isDirectory:YES ] ] ;
    if ( types != nil ) [ panel setAllowedFileTypes:types ] ;
    
    return [ panel runModal ] ;
}

+ (NSInteger)runModalFor:(NSSavePanel*)panel directory:(NSString*)directory file:(NSString*)file
{
    return [ self runModalFor:panel directory:directory file:file types:nil ] ;
}

@end
