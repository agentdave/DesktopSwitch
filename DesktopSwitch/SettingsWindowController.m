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
@synthesize port;
@synthesize currentScanStatus;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		_scanning = NO;
		self.port = @"49152"; // Seems to be a decent default port for UPnP
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
		self.currentScanStatus = @"";
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

	// Ugghhh... it's hacky, but it works. I have my excuses. If I were to do it over again, I might
	// use [[NSHost currentHost] addresses] with a 3rd party regex library (for 10.6 support) or a custom
	// IPv4 filter method to get the valid IPv4 addresses I'd want to use for the scan. Or maybe the
	// overly complex looking SystemConfiguration framework with SCNetworkConnectionCopyExtendedStatus.
	NSString* ipRootString = [self systemCommand:@"ifconfig | grep inet | grep broadcast | "
												"sed -E 's/.*inet (([0-9]+\\.){3}).*/\\1/'"];
	NSArray* ipRoots = [ipRootString componentsSeparatedByString:@"\n"];
	dispatch_async(_queue, ^{
		for (NSString* ipRoot in ipRoots) {
			for (NSUInteger i = 1; i < 255; i++) {
				if(!_scanning) {
					break;
				}

				NSString* attemptIP = [NSString stringWithFormat:@"%@%lu", ipRoot, (unsigned long)i];
				self.currentScanStatus = [NSString stringWithFormat:@"Scanning: %@:%@", attemptIP, self.port];
				NSString* switchName = [SwitchCommunication sendRequest:attemptIP
																   port:self.port
																service:@"basicevent" 
																 action:@"GetFriendlyName" 
																  value:nil
																timeout:0.5];
				if(switchName) {
					NSArray* ipAddresses = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"Devices.IPAddress"];
					if([ipAddresses containsObject:attemptIP]) {
						NSLog(@"Already have a setting for: %@", attemptIP);
					} else {
						NSLog(@"Found %@ at %@:%@", switchName, attemptIP, self.port);
						[self addDeviceToUserDefaults:switchName ipAddress:attemptIP port:self.port];
					}
				}
			}
		}
		self.currentScanStatus = @"";
		_scanning = NO;
		[self.spinner setHidden:YES];
		[self.spinner stopAnimation:self];
		[sender setTitle:@"Scan"];
	});
}

- (IBAction)addDevice:(id)sender {
	[self addDeviceToUserDefaults:@"New Switch" ipAddress:@"" port:self.port];
}

- (void) addDeviceToUserDefaults:(NSString*)switchName ipAddress:(NSString*)ipAddress port:(NSString*)thePort {
	NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							switchName, @"SwitchName",
							ipAddress, @"IPAddress",
							thePort, @"Port", nil];
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
	NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[task setEnvironment:environment];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput:pipe];
	[task setStandardInput:[NSPipe pipe]];
	[task launch];
	NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
	[task waitUntilExit];

	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] 
			stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
