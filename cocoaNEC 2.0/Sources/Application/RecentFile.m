//
//  RecentFile.m
//  cocoaNEC
//
//  Created by Kok Chen on 8/19/07.
//	-----------------------------------------------------------------------------
//  Copyright 2007-2016 Kok Chen, W7AY. 
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

#import "RecentFile.h"

@implementation RecentFile

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		plistKey = @"none" ;
		recentPaths = [ [ NSMutableArray alloc ] init ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ recentPaths release ] ;
	[ super dealloc ] ;
}

- (void)awakeFromNib
{
	//  set ourself to receive menuNeedsUpdate mewssage
	[ recentMenu setDelegate:self ] ;
	//  enable menus explicitly in menuNeedsUpdate
	[ recentMenu setAutoenablesItems:NO ] ;
}

- (void)touchedPath:(NSString*)path
{
	intType i, count ;
	NSString *check ;
	
	//  first check if path already exist, if so, remove 
	count = [ recentPaths count ] ;
	if ( count >= 1 ) {
		for ( i = 0; i < count; i++ ) {
			check = [ recentPaths objectAtIndex:i ] ;
			if ( [ path isEqualToString:check ] ) {
				[ recentPaths removeObjectAtIndex:i ] ;
				break ;
			}
		}
	}
	[ recentPaths insertObject:[ path retain ] atIndex:0 ] ;		
	//  truncate array to 6
	count = [ recentPaths count ] ;
	if ( count >= 6 ) [ recentPaths removeLastObject ] ;
}

//  sender is the menu
- (void)clearItems:(id)sender
{
	[ recentPaths removeAllObjects ] ;
}

//  subclass overrides this to do nessessary operation on the path
- (void)performOpen:(NSString*)path
{
	printf( "need to implement performOpen in a RecentFile subclass\n" ) ;
}

- (void)openRecentFile:(id)sender
{
	NSString *path ;
	intType n, count ;
	
	// sanity check	
	n = [ sender tag ] ;
	count = [ recentPaths count ] ;
	if ( n < 0 || n >= count ) return ;
	
	path = [ recentPaths objectAtIndex:n ] ;
	[ self performOpen:path ] ;
}

//  delegate to NSMenu
- (void)menuNeedsUpdate:(NSMenu*)menu
{
	NSMenuItem *item ;
	NSString *title ;
	intType i, items, count ;
	
	if ( menu == recentMenu ) {
	
		//  first clear menu
		items = [ menu numberOfItems ] ;
		count = [ recentPaths count ] ;		
		for ( i = 0; i < items; i++ ) [ menu removeItemAtIndex:0 ] ;			
		if ( count ) {
			//  now insert items
			for ( i = 0; i < count; i++ ) {
				title = [ recentPaths objectAtIndex:i ] ;
				if ( title != nil ) {
					item = [ menu addItemWithTitle:title action:@selector(openRecentFile:) keyEquivalent:@"" ] ;
					[ item setTarget:self ] ;
					[ item setTag:i ] ;
				}
			}
			[ menu addItem:[ NSMenuItem separatorItem ] ] ;
			item = [ menu addItemWithTitle:@"Clear Menu" action:@selector(clearItems:) keyEquivalent:@"" ] ;
			[ item setTarget:self ] ;
		}
	}
}

- (void)updatePrefsFromDict:(NSDictionary*)dict
{
	NSArray *recent ;
	
	recent = [ dict objectForKey:plistKey ] ;
	if ( recent ) [ recentPaths addObjectsFromArray:recent ] ;
}

- (void)savePrefsToPlist:(NSMutableDictionary*)plist
{
	[ plist setObject:recentPaths forKey:plistKey ] ;
}

@end
