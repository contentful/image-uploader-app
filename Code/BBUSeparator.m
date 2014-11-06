//
//  BBUSeparator.m
//  image-uploader
//
//  Created by Boris Bügling on 06/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUSeparator.h"

@implementation BBUSeparator

- (void)drawRect:(NSRect)rect {
    [[NSColor lightGrayColor] set];
    NSRectFill(NSMakeRect(0, 1, NSWidth(rect), 1));

    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0, 0, NSWidth(rect), 1));
}

@end
