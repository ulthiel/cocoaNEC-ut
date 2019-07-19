//
//  About.m
//  cocoaNEC
//	-----------------------------------------------------------------------------
//  Copyright 2004-2016 Kok Chen, W7AY. 
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

#import "About.h"
#import "Bundle.h"

@implementation About

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
        //  v0.88 old loadNibNamed deprecated in 10.10
        retainedNibObjects = [ Bundle loadNibNamed:@"About" owner:self ] ;
        if ( retainedNibObjects == nil ) return nil ;
	}
	return self ;
}

- (void)showPanel
{
	if ( window ) {
		[ window center ] ;
		[ window orderFront:self ] ;
	}
}

- (void)dealloc
{
    [ retainedNibObjects release ] ;
    [ super dealloc ] ;
}

@end
