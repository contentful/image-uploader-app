//
//  BBUAppDelegate.m
//  image-uploader
//
//  Created by Boris Bügling on 13/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Keys/ImageUploaderKeys.h>
#import <DJProgressHUD/DJProgressHUD.h>
#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <MASPreferences/MASPreferencesWindowController.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUAboutWindowController.h"
#import "BBUAppDelegate.h"
#import "BBULoginController.h"
#import "BBUUploaderPreferences.h"
#import "CMAClient+SharedClient.h"

@interface BBUAppDelegate ()

@property (nonatomic, readonly) BBUAboutWindowController* aboutWindowController;
@property (nonatomic, readonly) NSView* mainView;
@property (nonatomic, readonly) MASPreferencesWindowController* preferencesController;

@end

#pragma mark -

@implementation BBUAppDelegate

@synthesize aboutWindowController = _aboutWindowController;
@synthesize preferencesController = _preferencesController;

#pragma mark -

- (IBAction)aboutUsClicked:(id)sender {
    [self.aboutWindowController showWindow:self];
}

-(BBUAboutWindowController *)aboutWindowController {
    if (!_aboutWindowController) {
        _aboutWindowController = [BBUAboutWindowController new];
    }

    return _aboutWindowController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:[ImageuploaderKeys new].dropboxOAuthKey
                            appSecret:[ImageuploaderKeys new].dropboxOAuthSecret
                            root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       [DJProgressHUD showStatus:NSLocalizedString(@"Fetching Spaces...", nil)
                                        FromView:self.mainView];
                   });

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
    
    [NSApp stopModal];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];

    if ([url hasPrefix:@"db-"]) {
        return;
    }

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
    [self showPreferences];
}

- (MASPreferencesWindowController *)preferencesController {
    if (!_preferencesController) {
        _preferencesController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[ [BBUUploaderPreferences new] ]];
    }

    return _preferencesController;
}

- (void)selectSpace:(CMASpace*)space {
    self.spaceSelection.title = space.name;
    [CMAClient sharedClient].sharedSpace = space;

    [[NSNotificationCenter defaultCenter] postNotificationName:kContentfulSpaceChanged object:nil userInfo:@{ kContentfulSpaceChanged: space }];
}

- (void)showPreferences {
    [self.preferencesController showWindow:nil];
}

- (void)spaceSelected:(NSMenuItem*)menuItem {
    [self selectSpace:menuItem.representedObject];
}

- (void)startOAuthFlow {
    [BBULoginController presentLogin];
}

@end
