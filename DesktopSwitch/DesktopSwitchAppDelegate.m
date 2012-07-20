//
//  DesktopSwitchAppDelegate.m
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-16.
//  Copyright (c) 2012 David Ackermn
//
//  Released under the MIT Licence:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial 
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
//  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
//  NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#import "DesktopSwitchAppDelegate.h"
#import "SettingsWindowController.h"
#import "SwitchCommunication.h"

@interface DesktopSwitchAppDelegate(PRIVATE)

-(void) turnOn:(id)sender;
-(void) turnOff:(id)sender;
- (void)quit:(id)sender;
-(BOOL) socketActive;
- (NSMenu *) createMenu;
- (void) updateStatus:(NSString*)status forMenuItem:(NSMenuItem*)switchItem;
- (void) defaultsChanged:(NSNotification*)notification;
- (NSDictionary*)connectionInfoForMenuItem:(NSMenuItem*)menuItem;

@end


@implementation DesktopSwitchAppDelegate

@synthesize statusItem;
@synthesize settingsController;

- (NSMenu *) createMenu
{
	_menuItemConnectionInfo = [[NSMutableArray alloc] init];

	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;

	NSArray* switches = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Devices"];
	for(NSDictionary* switchDictionary in switches) {
		NSString* switchName = [switchDictionary valueForKey:@"SwitchName"];
		NSString* switchIPAddress = [switchDictionary valueForKey:@"IPAddress"];
		NSString* switchPort = [switchDictionary valueForKey:@"Port"];

		menuItem = [menu addItemWithTitle:switchName
								   action:@selector(toggleSwitch:)
							keyEquivalent:@""];
		[menuItem setTarget:self];
		[_menuItemConnectionInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											menuItem, @"MenuItem",
											switchIPAddress, @"IPAddress",
											switchPort, @"Port",
											nil]];

		NSString* status = [SwitchCommunication sendRequest:switchIPAddress
													   port:switchPort
													service:@"basicevent" 
													 action:@"GetBinaryState" 
													  value:nil
													timeout:0.5];
		[self updateStatus:status forMenuItem:menuItem];
	}

	if([switches count] > 0) {
		[menu addItem:[NSMenuItem separatorItem]];
	} else {
		[self updateStatus:nil forMenuItem:nil];		
	}

	menuItem = [menu addItemWithTitle:@"Settings..."
							   action:@selector(openSettings:)
						keyEquivalent:@""];
	[menuItem setTarget:self];
	[menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [menu addItemWithTitle:@"Quit"
							   action:@selector(quit:)
						keyEquivalent:@""];
	
	[menuItem setToolTip:@"Click to Remove the DesktopSwitch Menu from the task bar."];
	[menuItem setTarget:self];

	if(self.statusItem && [self.statusItem menu]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleStatusItemMenuOpened:)
													 name:NSMenuDidBeginTrackingNotification
												   object:[self.statusItem menu]];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleStatusItemMenuOpened:)
												 name:NSMenuDidBeginTrackingNotification
											   object:menu];

	return menu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 [[NSArray alloc] init], @"Devices",
								 nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];

	NSMenu *menu = [self createMenu];
	[self.statusItem setMenu:menu];

	[self.statusItem setHighlightMode:YES];
	[self.statusItem setToolTip:@"Desktop Switch"];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(defaultsChanged:)  
												 name:NSUserDefaultsDidChangeNotification
											   object:nil];
}

- (void)openSettings:(id)sender {
	if(!self.settingsController) {
		self.settingsController = [[SettingsWindowController alloc] initWithWindowNibName:@"Settings"];
	}
	[NSApp activateIgnoringOtherApps:YES];
	[self.settingsController showWindow:sender];
	[[self.settingsController window] makeKeyAndOrderFront:sender];
}

- (void) turnOn:(id)sender {
	NSDictionary* connection = [self connectionInfoForMenuItem:sender];
	NSString* status = [SwitchCommunication sendRequest:[connection objectForKey:@"IPAddress"]
												   port:[connection objectForKey:@"Port"]
												service:@"basicevent" 
												 action:@"SetBinaryState" 
												  value:@"1"];
	[self updateStatus:status forMenuItem:sender];
}

- (void) turnOff:(id)sender {
	NSDictionary* connection = [self connectionInfoForMenuItem:sender];
	NSString* status = [SwitchCommunication sendRequest:[connection objectForKey:@"IPAddress"]
												   port:[connection objectForKey:@"Port"]
												service:@"basicevent" 
												 action:@"SetBinaryState" 
												  value:@"0"];
	[self updateStatus:status forMenuItem:sender];
}

- (void) toggleSwitch:(id)sender {
	NSMenuItem* switchItem = sender;
	if([switchItem state] == NSOnState) {
		[self turnOff:sender];
	} else {
		[self turnOn:sender];
	}
}

- (void) updateStatus:(NSString*)status forMenuItem:(NSMenuItem*)switchItem {
	if(!_onImage) {
		_onImage = [NSImage imageNamed:@"on"];
		[_onImage setSize:NSMakeSize(20, 20)];
	}

	if(!_offImage) {
		_offImage = [NSImage imageNamed:@"off"];
		[_offImage setSize:NSMakeSize(20, 20)];
	}

	if(status) {
		if([status isEqualToString:@"1"]) {
			if(switchItem) [switchItem setState:NSOnState];
			[self.statusItem setImage:_onImage];
		} else {
			if(switchItem) [switchItem setState:NSOffState];
			[self.statusItem setImage:_offImage];
		}
	} else {
		if(switchItem) [switchItem setState:NSOffState];
		[self.statusItem setImage:_offImage];		
	}
}

- (void)quit:(id)sender {
	[NSApp terminate:sender];
}

- (void) defaultsChanged:(NSNotification*)notification {
	NSMenu *menu = [self createMenu];
	[self.statusItem setMenu:menu];
}

- (NSDictionary*)connectionInfoForMenuItem:(NSMenuItem*)menuItem {
	for(NSDictionary* connectionDictionary in _menuItemConnectionInfo) {
		if([connectionDictionary objectForKey:@"MenuItem"] == menuItem) {
			return connectionDictionary;
		}
	}
	return nil;
}

- (void) handleStatusItemMenuOpened:(NSNotification*)notification {
	for(NSDictionary* connectionDictionary in _menuItemConnectionInfo) {
		NSString* status = [SwitchCommunication sendRequest:[connectionDictionary objectForKey:@"IPAddress"]
													   port:[connectionDictionary objectForKey:@"Port"]
													service:@"basicevent" 
													 action:@"GetBinaryState" 
													  value:nil
													timeout:0.5];
		[self updateStatus:status forMenuItem:[connectionDictionary objectForKey:@"MenuItem"]];
	}
}

@end
