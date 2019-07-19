//
//  Bundle.m
//  cocoaNEC 2.0
//
//  Created by Kok Chen on 5/24/16.
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

#import "Bundle.h"

@implementation Bundle

//  Class method[ NSBundle loadNibNamed ] is deprecated in 10.11.
//  However -loadNibNamed does not retain the objects that are owned by the Nib.
//  This replacement retains the objects by retaining the Array that contains them.
//
//  return nil if nib not loaded
//  else returns a retained NSArray with toplevelObjects.
//  All top level objects are retained by the NSArray.

+ (NSArray*)loadNibNamed:(NSString*)nib owner:(id)owner
{
    NSArray *array ;
    
    if ( [ [ NSBundle mainBundle ] loadNibNamed:nib owner:owner topLevelObjects:&array ] == NO ) return nil ;
    return [ array retain ] ;
}

@end
