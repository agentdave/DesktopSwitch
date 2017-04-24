//
//  SwitchCommunication.m
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-18.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import "SwitchCommunication.h"

@implementation SwitchCommunication

+ (NSString*) sendRequest:(NSString*)ipAddress
					 port:(NSString*)port
				  service:(NSString*)service 
				   action:(NSString*)action 
					value:(NSString*)value {

	return [self sendRequest:ipAddress
						port:port
					 service:service
					  action:action
					   value:value
					 timeout:0];
}

// Because everyone loves methods that are wayyyyy too long ;-)
+ (NSString*) sendRequest:(NSString*)ipAddress
					 port:(NSString*)port
				  service:(NSString*)service 
				   action:(NSString*)action 
					value:(NSString*)value
				  timeout:(NSTimeInterval)timeout {
	
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
	
	NSMutableURLRequest *request;
	if(timeout == 0) {
		request = [NSMutableURLRequest requestWithURL:url];
	} else {
		request = [NSMutableURLRequest requestWithURL:url 
										  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
									  timeoutInterval:timeout];		
	}

	[request setHTTPMethod:@"POST"];
	
	NSString* contentType = @"text/xml; charset='utf-8'";
	NSString* contentLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestBody length]];
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
		NSXMLElement* rootNode = [document rootElement];
		NSArray* states = [rootNode nodesForXPath:@"//body" error:&error];
		if([states count] == 1) {
			NSXMLElement* element = [states objectAtIndex:0];
			return [element stringValue];
		}
	}
	
	return nil;
}

@end
