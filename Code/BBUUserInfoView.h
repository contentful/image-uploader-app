//
//  BBUUserInfoView.h
//  image-uploader
//
//  Created by Boris Bügling on 15/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CMAUser;

@interface BBUUserInfoView : NSView

@property (nonatomic) CMAUser* user;

@end
