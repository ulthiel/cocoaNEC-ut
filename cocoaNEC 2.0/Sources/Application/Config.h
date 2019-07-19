//
//  Config.h
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

#import <Foundation/Foundation.h>

#define kUseGCD     0       //  set to 0 to not use GCD the GCD functions (gcd_rdpat and gcd_cmww)

#define	intType     NSInteger
#define	floatType	CGFloat

#define	DefaultFrequency	14.080


@interface Config : NSObject {
}


#define FOURDIGITTAG    1      //   set to non-zero to use 4 digit tags for Hollerith cards

+ (NSString*)format:(const char*)originalString ;

+ (NSString*)formatWithType:(const char*)originalString ;

+ (void)setEngineType:(int)type ;

@end
