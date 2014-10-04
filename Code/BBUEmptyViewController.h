//
//  BBUEmptyViewController.h
//  image-uploader
//
//  Created by Boris Bügling on 23/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^BBUBrowseClickAction)(NSButton* button);

@interface BBUEmptyViewController : NSViewController

@property (nonatomic, copy) BBUBrowseClickAction browseAction;

@end
