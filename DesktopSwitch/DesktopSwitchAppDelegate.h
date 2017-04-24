//
//  DesktopSwitchAppDelegate.h
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-16.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SettingsWindowController;

@interface DesktopSwitchAppDelegate : NSObject <NSApplicationDelegate> {
	NSImage* _onImage;
	NSImage* _offImage;

	NSMutableArray* _menuItemConnectionInfo;
}

@property (strong) NSStatusItem* statusItem;
@property (strong) SettingsWindowController* settingsController;

@end
