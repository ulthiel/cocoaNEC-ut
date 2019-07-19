//
//  DateFormat.m
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

#import "DateFormat.h"

@implementation DateFormat

//  deprecated [ [ NSDate date ] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M" timeZone:nil locale:nil ] ;

//  For NSDateFormatter
//  EEEE is weekday
//  d is day of month
//  MMMM is Month in string, M is month in decimal
//  YYYY is year
//  HH is two digit hour (24 hour) hh is two digit hour (12 hour)
//  mm is two digit minutes

+ (NSString*)descriptionWithCalendarFormat:(NSString*)format timeZone:(NSTimeZone*)timeZone locale:(NSLocale*)locale
{
    NSDateFormatter *dateFormatter ;
    NSString *dateString ;
    
    //  tests
    //format = @"EEEE d MMMM YYYY HH:mm" ;
    //format = @"Y-M-d HH:mm" ;
    
    dateFormatter = [ [ NSDateFormatter alloc ] init ] ;
    [ dateFormatter setDateFormat:format ] ;
    [ dateFormatter setTimeZone:( ( timeZone == nil ) ? [ NSTimeZone systemTimeZone ] : timeZone ) ] ;
    
    dateString = [ dateFormatter stringFromDate:[ NSDate date ] ] ;
    
    [ dateFormatter release ] ;
    return dateString ;
}

+ (NSString*)descriptionWithCalendarFormat:(NSString*)format
{
    return [ DateFormat descriptionWithCalendarFormat:format timeZone:nil locale:nil ] ;
}


@end
