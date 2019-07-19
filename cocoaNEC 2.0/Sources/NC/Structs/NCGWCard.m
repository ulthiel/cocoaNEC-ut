//
//  NCGWCard.m
//  cocoaNEC
//
//  Created by Kok Chen on 5/30/09.
//	-----------------------------------------------------------------------------
//  Copyright 2009-2016 Kok Chen, W7AY. 
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

#import "NCGWCard.h"


//  Used by GW, GH and GM

@implementation NCGWCard

- (id)initWithRuntime:(RuntimeStack*)rt
{
	self = [ super init ] ;
	if ( self ) {
		f1 = f2 = f3 = f4 = f5 = f6 = f7 = 0.0 ;
		i1 = 100 ;
		i2 = 21 ;
		i3 = i4 = 0 ;
		runtime = rt ;
	}
	return self ;
}

- (void)setF1:(double)value
{
	f1 = value ;
}

- (void)setF2:(double)value
{
	f2 = value ;
}

- (void)setF3:(double)value
{
	f3 = value ;
}

- (void)setF4:(double)value
{
	f4 = value ;
}

- (void)setF5:(double)value
{
	f5 = value ;
}

- (void)setF6:(double)value
{
	f6 = value ;
}

- (void)setF7:(double)value
{
	f7 = value ;
}

- (void)setI1:(int)value
{
	i1 = value ;
}

- (void)setI2:(int)value
{
	i2 = value ;
}

- (void)setI3:(int)value
{
	i3 = value ;
}

- (void)setI4:(int)value
{
	i4 = value ;
}

- (NSArray*)geometryCards
{
	NSString *card ;
	
	//  v0.86
    //  v0.88
    card = [ [ NSString alloc ] initWithFormat:[ Config formatWithType:"%2s%3d%5d%10s%10s%10s%10s%10s%10s%10s" ],
            type, i1, i2, dtos(f1), dtos(f2), dtos(f3), dtos(f4), dtos(f5), dtos(f6), dtos(f7) ] ;

    return [ NSArray arrayWithObjects:card, nil ] ;
}

@end
