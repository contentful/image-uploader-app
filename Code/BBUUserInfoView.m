//
//  BBUUserInfoView.m
//  image-uploader
//
//  Created by Boris Bügling on 15/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "BBUUserInfoView.h"
#import "NSView+Geometry.h"

@interface BBUUserInfoView ()

@property (nonatomic, readonly) NSImageView* avatarImageView;
@property (nonatomic, readonly) NSTextField* usernameLabel;

@end

#pragma mark -

@implementation BBUUserInfoView

@synthesize avatarImageView = _avatarImageView;
@synthesize usernameLabel = _usernameLabel;

#pragma mark -

-(NSImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 37.0, 37.0)];
        [self addSubview:_avatarImageView];
    }

    return _avatarImageView;
}

-(void)awakeFromNib {
    [super awakeFromNib];

    self.usernameLabel.stringValue = @"foobar";

    self.usernameLabel.x = NSMaxX(self.avatarImageView.frame) + 10.0;
    self.usernameLabel.width = self.width - self.usernameLabel.x;
}

-(void)setUser:(CMAUser *)user {
    self.usernameLabel.stringValue = user.firstName;

    if (!user.avatarURL) {
        return;
    }

    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:user.avatarURL]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (data) {
                                   self.avatarImageView.image = [[NSImage alloc] initWithData:data];;
                               }
                           }];
}

-(CMAUser *)user {
    return nil;
}

-(NSTextField *)usernameLabel {
    if (!_usernameLabel) {
        _usernameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, -15.0, 0.0, 37.0)];
        _usernameLabel.bordered = NO;
        _usernameLabel.drawsBackground = NO;
        _usernameLabel.editable = NO;
        _usernameLabel.font = [NSFont boldSystemFontOfSize:16.0];
        [self addSubview:_usernameLabel];
    }

    return _usernameLabel;
}

@end
