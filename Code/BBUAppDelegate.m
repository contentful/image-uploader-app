//
//  BBUAppDelegate.m
//  image-uploader
//
//  Created by Boris Bügling on 13/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <DJProgressHUD/DJProgressHUD.h>
#import <MASPreferences/MASPreferencesWindowController.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUAppDelegate.h"
#import "BBULoginController.h"
#import "BBUS3SettingsViewController.h"
#import "CMAClient+SharedClient.h"

@interface BBUAppDelegate ()

@property (nonatomic, readonly) NSView* mainView;
@property (nonatomic, readonly) MASPreferencesWindowController* preferencesController;

@end

#pragma mark -

@implementation BBUAppDelegate

@synthesize preferencesController = _preferencesController;

#pragma mark -

- (IBAction)aboutUsClicked:(id)sender {
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    if ([SSKeychain passwordForService:kContentfulServiceType account:kContentfulServiceType].length == 0) {
        [self startOAuthFlow];
    } else {
        [self fetchSpaces];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}

- (void)fetchSpaces {
    [DJProgressHUD showStatus:NSLocalizedString(@"Fetching Spaces...", nil)
                     FromView:self.mainView];

    [[CMAClient sharedClient] fetchAllSpacesWithSuccess:^(CDAResponse *response, CDAArray *array) {
        [self fillMenuWithSpaces:array.items];

        [DJProgressHUD dismiss];
    } failure:^(CDAResponse *response, NSError *error) {
        [DJProgressHUD dismiss];

        NSAlert* alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];
}

- (void)fillMenuWithSpaces:(NSArray*)spaces {
    self.spaceSelection.enabled = YES;

    [self.spaceSelectionMenu removeAllItems];

    spaces = [spaces sortedArrayUsingComparator:^NSComparisonResult(CMASpace* space1, CMASpace* space2) {
        return [space1.name localizedStandardCompare:space2.name];
    }];
    [self selectSpace:spaces[0]];

    [spaces enumerateObjectsUsingBlock:^(CMASpace* space, NSUInteger idx, BOOL *stop) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:space.name
                                                          action:@selector(spaceSelected:)
                                                   keyEquivalent:@""];
        menuItem.representedObject = space;
        [self.spaceSelectionMenu addItem:menuItem];
    }];
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

        [NSApp activateIgnoringOtherApps:YES];

        [SSKeychain setPassword:components[1]
                     forService:kContentfulServiceType
                        account:kContentfulServiceType];

        [self fetchSpaces];
    }
}

- (IBAction)logoutClicked:(NSMenuItem *)sender {
    [SSKeychain deletePasswordForService:kContentfulServiceType account:kContentfulServiceType];

    [self startOAuthFlow];
}

- (NSView*)mainView {
    return [[NSApp windows][0] contentView];
}

- (IBAction)preferencesClicked:(NSMenuItem *)sender {
    [self.preferencesController showWindow:nil];
}

- (MASPreferencesWindowController *)preferencesController {
    if (!_preferencesController) {
        _preferencesController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[ [BBUS3SettingsViewController new] ]];
    }

    return _preferencesController;
}

- (void)selectSpace:(CMASpace*)space {
    self.spaceSelection.title = space.name;
    [CMAClient sharedClient].sharedSpaceKey = space.identifier;

    [[NSNotificationCenter defaultCenter] postNotificationName:kContentfulSpaceChanged object:nil userInfo:@{ kContentfulSpaceChanged: space }];
}

- (void)spaceSelected:(NSMenuItem*)menuItem {
    [self selectSpace:menuItem.representedObject];
}

- (void)startOAuthFlow {
    [BBULoginController presentLogin];
}

@end
