//
//  DesktopSwitchAppDelegate.h
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-16.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DesktopSwitchAppDelegate : NSObject <NSApplicationDelegate> {
	NSImage* _onImage;
	NSImage* _offImage;
}

@property (assign) NSStatusItem* statusItem;

@end
