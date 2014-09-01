//
//  BBUAppDelegate.h
//  image-uploader
//
//  Created by Boris Bügling on 13/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BBUAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *spaceSelectionMenu;
@property (weak) IBOutlet NSToolbarItem *spaceSelection;

@end
