//
//  BBUHeaderView.m
//  image-uploader
//
//  Created by Boris Bügling on 25/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUHeaderView.h"
#import "NSView+Geometry.h"

@implementation BBUHeaderView

@synthesize closeButton = _closeButton;
@synthesize titleLabel = _titleLabel;

#pragma mark -

-(NSColor *)backgroundColor {
    return [NSColor colorWithCGColor:self.layer.backgroundColor];
}

-(NSButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 12.0, 12.0)];
        _closeButton.action = @selector(closeClicked:);
        _closeButton.bordered = NO;
        _closeButton.hidden = YES;
        _closeButton.image = [NSImage imageNamed:@"close"];
        _closeButton.target = self;
        [self addSubview:_closeButton];
    }

    return _closeButton;
}

-(void)drawRect:(NSRect)dirtyRect {
    self.closeButton.x = self.width - 10.0 - self.closeButton.width;
    self.closeButton.y = (self.height - self.closeButton.height) / 2;

    self.titleLabel.y = (self.height - self.titleLabel.height) / 2;
    self.titleLabel.width = self.width - 20.0;

    [super drawRect:dirtyRect];
}

-(void)setBackgroundColor:(NSColor *)backgroundColor {
    self.layer.backgroundColor = backgroundColor.CGColor;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        [_titleLabel setBordered:NO];
        [_titleLabel setDrawsBackground:NO];
        [_titleLabel setEditable:NO];
        [_titleLabel setFont:[BBUAppStyle defaultStyle].titleFont];
        [_titleLabel setTextColor:[NSColor whiteColor]];
        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

#pragma mark - Actions

-(void)closeClicked:(NSButton*)button {
    self.hidden = YES;
}

@end
