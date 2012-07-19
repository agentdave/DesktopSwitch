//
//  SwitchCommunication.h
//  DesktopSwitch
//
//  Created by David Ackerman on 12-07-18.
//  Copyright (c) 2012 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwitchCommunication : NSObject

+ (NSString*) sendRequest:(NSString*)ipAddress
					 port:(NSString*)port
				  service:(NSString*)service 
				   action:(NSString*)action 
					value:(NSString*)value
				  timeout:(NSTimeInterval)timeout;

+ (NSString*) sendRequest:(NSString*)ipAddress
					 port:(NSString*)port
				  service:(NSString*)service 
				   action:(NSString*)action 
					value:(NSString*)value;

@end
