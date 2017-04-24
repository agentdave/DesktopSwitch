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

@property (strong) IBOutlet NSProgressIndicator* spinner;
@property (strong) NSString* port;
@property (strong) NSString* currentScanStatus;

@end
