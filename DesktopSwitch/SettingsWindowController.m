//
//  SettingsWindowController.m
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-18.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import "SettingsWindowController.h"
#import "SwitchCommunication.h"

static dispatch_queue_t _queue = nil;

@interface SettingsWindowController (PRIVATE)
- (void) addDeviceToUserDefaults:(NSString*)switchName ipAddress:(NSString*)ipAddress port:(NSString*)port;
- (NSString*) systemCommand:(NSString*)commandString;
@end

@implementation SettingsWindowController

+ (void) initialize {
	_queue = dispatch_queue_create("com.dsackerman.DesktopSwitch.BackgroundDispatchQueue", NULL);
}

@synthesize spinner;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		_scanning = NO;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)scanForDevices:(id)sender {	
	if(_scanning) {
		_scanning = NO;
		[self.spinner setHidden:YES];
		[self.spinner stopAnimation:self];
		[sender setTitle:@"Scan"];
		return;
	} else {
		_scanning = YES;
		[self.spinner setHidden:NO];
		[self.spinner startAnimation:self];
		[sender setTitle:@"Stop Scanning"];
	}

	NSString *ipRoot = [self systemCommand:@"ifconfig | grep inet | grep broadcast | sed -E 's/.*inet (([0-9]+\\.){3}).*/\\1/'"];
	NSLog(@"ipRoot: %@", ipRoot);
	
	dispatch_async(_queue, ^{
		for (NSUInteger i = 1; i < 255; i++) {
			if(!_scanning) {
				break;
			}

			NSString* attemptIP = [NSString stringWithFormat:@"%@%u", ipRoot, i];
			NSString* switchName = [SwitchCommunication sendRequest:attemptIP
															   port:@"49152"
															service:@"basicevent" 
															 action:@"GetFriendlyName" 
															  value:nil
															timeout:0.5];
			NSLog(@"Scanning: %@", attemptIP);
			if(switchName) {
				NSArray* ipAddresses = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Devices.IPAddress"];
				if([ipAddresses containsObject:attemptIP]) {
					NSLog(@"Already have a setting for: %@", attemptIP);
				} else {
					[self addDeviceToUserDefaults:switchName ipAddress:attemptIP port:@"49152"];
				}
			}
		}
		_scanning = NO;
		[self.spinner setHidden:YES];
		[self.spinner stopAnimation:self];
		[sender setTitle:@"Scan"];
	});
}

- (IBAction)addDevice:(id)sender {
	[self addDeviceToUserDefaults:@"New Switch" ipAddress:@"" port:@"49152"];
}

- (void) addDeviceToUserDefaults:(NSString*)switchName ipAddress:(NSString*)ipAddress port:(NSString*)port {
	NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							switchName, @"SwitchName",
							ipAddress, @"IPAddress",
							port, @"Port", nil];
	NSMutableArray* devices = [[[NSUserDefaults standardUserDefaults] valueForKey:@"Devices"] mutableCopy];
	[devices addObject:device];
	[[NSUserDefaults standardUserDefaults] setValue:devices forKey:@"Devices"];
}

- (NSString*) systemCommand:(NSString*)commandString {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:[NSArray arrayWithObjects:@"-c",
						[NSString stringWithFormat:@"/bin/sh -c \"%@\"",commandString],
						nil]];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task launch];
	NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
	[task waitUntilExit];
	[task release];
	return [[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] 
			stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
}

@end
