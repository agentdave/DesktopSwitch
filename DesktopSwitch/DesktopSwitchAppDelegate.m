//
//  DesktopSwitchAppDelegate.m
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-16.
//  Copyright (c) 2012 David Ackermn
//
//  Released under the MIT Licence:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 
//  "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, 
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject 
//  to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#import "DesktopSwitchAppDelegate.h"

@interface DesktopSwitchAppDelegate(PRIVATE)

-(void) turnOn:(id)sender;
-(void) turnOff:(id)sender;
- (void)quit:(id)sender;
-(BOOL) socketActive;
- (NSMenu *) createMenu;
- (NSString*) sendRequest:(NSString*)service action:(NSString*)action value:(NSString*)value;
- (void) updateStatus:(NSString*)status forMenuItem:(NSMenuItem*)switchItem;

@end


@implementation DesktopSwitchAppDelegate

@synthesize statusItem;

- (NSMenu *) createMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	
	NSString* switchName = [self sendRequest:@"basicevent" action:@"GetFriendlyName" value:nil];
	menuItem = [menu addItemWithTitle:switchName
							   action:@selector(toggleSwitch:)
						keyEquivalent:@""];	
	[menuItem setTarget:self];

	NSString* status = [self sendRequest:@"basicevent" action:@"GetBinaryState" value:nil];
	[self updateStatus:status forMenuItem:menuItem];

	[menu addItem:[NSMenuItem separatorItem]];

	menuItem = [menu addItemWithTitle:@"Settings..."
							   action:@selector(openSettings:)
						keyEquivalent:@""];
	[menuItem setTarget:self];
	[menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [menu addItemWithTitle:@"Quit"
							   action:@selector(quit:)
						keyEquivalent:@""];
	
	[menuItem setToolTip:@"Click to Remove the WebStack Menu from the task bar."];
	[menuItem setTarget:self];
	
	return menu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{	
	self.statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];

	NSMenu *menu = [self createMenu];
	[self.statusItem setMenu:menu];

	[self.statusItem setHighlightMode:YES];
	[self.statusItem setToolTip:@"Desktop Switch"];
}

- (void)openSettings:(id)sender {
	NSLog(@"Implement me!!!");
}

- (void) turnOn:(id)sender {
	NSString* status = [self sendRequest:@"basicevent" action:@"SetBinaryState" value:@"1"];
	[self updateStatus:status forMenuItem:sender];
}

- (void) turnOff:(id)sender {
	NSString* status = [self sendRequest:@"basicevent" action:@"SetBinaryState" value:@"0"];
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

// Because everyone loves methods that are wayyyyy too long ;-)
- (NSString*) sendRequest:(NSString*)service action:(NSString*)action value:(NSString*)value {
	// TODO: Make this into an actual settings panel
	NSString* ipAddress = @"10.0.1.24";
	NSString* port = @"49152";

	// If this supported more than the Set/GetBinaryState actions, I'd probably want to throw the following out and
	// look into some real SOAP APIs. Note that this stuff seems to use the UPnP protocol, so theoretically an API
	// made for that would work as well.
	NSString* arguments = [NSString stringWithFormat:@"<BinaryState>%@</BinaryState>", value];

	NSString* requestBody = [NSString stringWithFormat:@"<?xml version='1.0'encoding='utf-8'?>"
						 "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>"
						 "<s:Body>"
							"<u:%@ xmlns:u='urn:Belkin:service:%@:1'>"
								"%@"
							"</u:%@>"
						 "</s:Body>"
						 "</s:Envelope>", action, service, arguments, action];

	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: @"http://%@:%@/upnp/control/%@1", ipAddress, port, service]];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
	[request setHTTPMethod:@"POST"];
	
	NSString* contentType = @"text/xml; charset='utf-8'";
	NSString* contentLength = [NSString stringWithFormat:@"%u", [requestBody length]];
	// Grrr... Seems it's rather important here to use double-quotes. Single quotes just won't cut it.
	NSString* soapAction = [NSString stringWithFormat:@"\"urn:Belkin:service:%@:1#%@\"", service, action];
	NSDictionary* headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 contentType, @"Content-Type",
							 soapAction, @"SOAPACTION",
							 contentLength, @"Content-Length", nil];

	[request setAllHTTPHeaderFields:headers];
	[request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];

	/*
		This is ugly as all hell. In the ruby prototype, this came back like so:

		<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
			<s:Body>
				<u:SetBinaryStateResponse xmlns:u="urn:Belkin:service:basicevent:1">
					<BinaryState>1</BinaryState>
				</u:SetBinaryStateResponse>
			</s:Body>
		</s:Envelope>
	 
		But for some reason, here, it's coming back as regular HTML. I'm probably not setting some XML schema property properly...
	 */
	NSURLResponse* responseCode;
	NSError* error;
	NSData* response = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];	
	if(response) {
		NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:response options:NSXMLDocumentTidyHTML error:&error];
		NSLog(@"response: %@", document);
		NSXMLElement* rootNode = [document rootElement];
		NSArray* states = [rootNode nodesForXPath:@"//body" error:&error];
		if([states count] == 1) {
			NSXMLElement* element = [states objectAtIndex:0];
			return [element stringValue];
		}
	}
	
	return nil;
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
	}
}

- (void)quit:(id)sender {
	[NSApp terminate:sender];
}

@end
