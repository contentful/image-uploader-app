//
//  BBUDragHintView.m
//  image-uploader
//
//  Created by Boris Bügling on 26/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUDragHintView.h"
#import "NSView+Geometry.h"

@implementation BBUDragHintView

- (void)drawRect:(NSRect)dirtyRect {
    [[BBUAppStyle defaultStyle].backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    [super drawRect:dirtyRect];
}

-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        NSImageView* imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 40.0,
                                                                               self.width, 3.0)];
        imageView.autoresizingMask = NSViewWidthSizable;
        imageView.image = [NSImage imageNamed:@"Line"];
        imageView.imageScaling = NSImageScaleAxesIndependently;
        [self addSubview:imageView];

        NSTextField* label = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 5.0,
                                                                           self.width - 20.0, 20.0)];
        [label setAlignment:NSCenterTextAlignment];
        [label setAutoresizingMask:NSViewWidthSizable];
        [label setBackgroundColor:[BBUAppStyle defaultStyle].backgroundColor];
        [label setBordered:NO];
        [label setEditable:NO];
        [label setFont:[BBUAppStyle defaultStyle].titleFont];
        [label setStringValue:NSLocalizedString(@"Drag & Drop files here to instantly upload them", nil)];
        [label setTextColor:[NSColor whiteColor]];
        [self addSubview:label];

        for (NSView *aSubview in self.subviews) {
            [aSubview unregisterDraggedTypes];
        }
    }
    return self;
}

@end
