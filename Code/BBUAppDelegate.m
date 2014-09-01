//
//  BBUAppDelegate.m
//  image-uploader
//
//  Created by Boris Bügling on 13/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <DJProgressHUD/DJProgressHUD.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUAppDelegate.h"
#import "CMAClient+SharedClient.h"

static NSString* const kClientID = @"Your-OAuth-Client-Id";

@implementation BBUAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    if ([SSKeychain accountsForService:kContentfulServiceType].count == 0) {
        [self startOAuthFlow];
    }
}

- (void)getUrl:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    [DJProgressHUD dismiss];

    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    NSArray* components = [url componentsSeparatedByString:@"#"];
    if (components.count == 2 && [components[1] hasPrefix:@"access_token"]) {
        components = [components[1] componentsSeparatedByString:@"&"];
        if (components.count < 1) {
            return;
        }

        components = [components[0] componentsSeparatedByString:@"="];
        if (components.count != 2) {
            return;
        }

        [SSKeychain setPassword:components[1]
                     forService:kContentfulServiceType
                        account:kContentfulServiceType];
    }
}

- (void)startOAuthFlow {
    NSView* mainView = [[NSApp windows][0] contentView];
    [DJProgressHUD showStatus:NSLocalizedString(@"Waiting for authentication...", nil)
                     FromView:mainView];

    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://be.contentful.com/oauth/authorize?response_type=token&client_id=%@&redirect_uri=contentful-uploader%%3a%%2f%%2ftoken&token&scope=content_management_manage", kClientID]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
