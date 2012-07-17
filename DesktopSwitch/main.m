//
//  main.m
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-16.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DesktopSwitchAppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
	
    DesktopSwitchAppDelegate *menu = [[DesktopSwitchAppDelegate alloc] init];
    [NSApp setDelegate:menu];
    [NSApp run];
	
    [pool release];
	
    return EXIT_SUCCESS;
//	return NSApplicationMain(argc, (const char **)argv);
}
