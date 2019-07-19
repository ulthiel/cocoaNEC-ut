//
//  AlertExtension.h
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

@interface AlertExtension : NSObject
{
}

+ (NSAlert*)alertWithMessage:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton otherButton:(NSString*)otherButton informativeTextWithFormat:(NSString*)infoText ;

+ (NSModalResponse)modalAlert:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton otherButton:(NSString*)otherButton informativeTextWithFormat:(NSString*)infoText ;

@end
