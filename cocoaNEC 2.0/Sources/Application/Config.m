//
//  Config.m
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

#import "Config.h"
#import "NECEngines.h"

@implementation Config

static Boolean _use4DigitTag = NO ;

//  change %3d%5d to %4d%4d for the tag/segment fields
//  e.g., GW%3d%5d
+ (NSString*)format:(const char*)originalString
{
    char newString[132] ;
    
    if ( _use4DigitTag ) {
        //  need to make a copy because the input is a constant string
        strcpy( newString, originalString ) ;
        newString[3] = newString[6] = '4' ;
        originalString = newString ;
    }
    return [ NSString stringWithCString:originalString encoding:NSASCIIStringEncoding ] ;
}

//  change %3d%5d to %4d%4d for the tag/segment fields for card type that is included in format
//  e.g., %2s%3d%5d
+ (NSString*)formatWithType:(const char*)originalString
{
    char newString[132] ;

    if ( _use4DigitTag != 0 ) {
        //  need to make a copy because the input is a constant string
        strcpy( newString, originalString ) ;
        newString[4] = newString[7] = '4' ;
        originalString = newString ;
    }
    return [ NSString stringWithCString:originalString encoding:NSASCIIStringEncoding ] ;
}

//  v0.89
+ (void)setEngineType:(int)type
{
    _use4DigitTag = ( FOURDIGITTAG != 0 ) ;     //  use 4 digit tag for all engines for now
}

@end
