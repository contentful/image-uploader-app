//
//  BBULoginController.m
//  image-uploader
//
//  Created by Boris Bügling on 05/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <CocoaPods-Keys/ImageUploaderKeys.h>

#import "BBUAppStyle.h"
#import "BBULoginController.h"
#import "NSButton+Contentful.h"
#import "NSView+Geometry.h"

@implementation BBULoginController

+(instancetype)presentLogin {
    BBULoginController* controller = [BBULoginController new];
    [NSApp runModalForWindow:controller.window];
    return controller;
}

#pragma mark -

-(id)init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    return self;
}

- (IBAction)linkClicked:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.contentful.com"]];
}

- (IBAction)loginClicked:(NSButton *)sender {
    sender.enabled = NO;

    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://be.contentful.com/oauth/authorize?response_type=token&client_id=%@&redirect_uri=contentful-uploader%%3a%%2f%%2ftoken&token&scope=content_management_manage", [ImageUploaderKeys new].contentfulOAuthClient]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor.CGColor;

    NSButton* loginButton = [NSButton primaryContentfulButton];
    loginButton.action = @selector(loginClicked:);
    loginButton.target = self;
    loginButton.width = 190.0;
    loginButton.x = (contentView.width - loginButton.width) / 2;
    loginButton.y = 40.0;
    [loginButton bbu_setPrimaryButtonTitle:NSLocalizedString(@"Login to Contentful", nil)];
    [contentView addSubview:loginButton];
}

@end
