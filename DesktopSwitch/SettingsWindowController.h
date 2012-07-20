//
//  SettingsWindowController.h
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-18.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingsWindowController : NSWindowController {
	BOOL _scanning;
}

- (IBAction)scanForDevices:(id)sender;
- (IBAction)addDevice:(id)sender;

@property (retain) IBOutlet NSProgressIndicator* spinner;
@property (retain) NSString* port;
@property (retain) NSString* currentScanStatus;

@end
