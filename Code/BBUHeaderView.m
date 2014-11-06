//
//  BBUHeaderView.m
//  image-uploader
//
//  Created by Boris Bügling on 25/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUHeaderView.h"
#import "BBUSeparator.h"
#import "NSView+Geometry.h"

@implementation BBUHeaderView

@synthesize closeButton = _closeButton;
@synthesize separator = _separator;
@synthesize subtitleLabel = _subtitleLabel;
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
    CGSize titleSize = [self.titleLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName:
                                                                              self.titleLabel.font }];

    self.separator.x = titleSize.width + 40.0;
    self.separator.width = self.width - self.separator.x - 10.0;
    self.separator.y = self.height - self.separator.height - titleSize.height;

    self.closeButton.x = self.width - 20.0 - self.closeButton.width;
    self.closeButton.y = (self.height - self.closeButton.height) / 2;

    self.titleLabel.y = self.height - 10.0 - self.titleLabel.height;
    self.titleLabel.width = self.width - 20.0;

    self.subtitleLabel.width = self.width - 20.0;
    self.subtitleLabel.height = self.height - self.titleLabel.height - 40.0;
    self.subtitleLabel.y = self.titleLabel.y - self.subtitleLabel.height;

    [super drawRect:dirtyRect];
}

-(NSBox *)separator {
    if (!_separator) {
        _separator = [[BBUSeparator alloc] initWithFrame:NSMakeRect(0.0, 0.0, 0.0, 2.0)];
        _separator.hidden = YES;
        [self addSubview:_separator];
    }

    return _separator;
}

-(void)setBackgroundColor:(NSColor *)backgroundColor {
    self.layer.backgroundColor = backgroundColor.CGColor;
}

-(NSTextField *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20.0, 0.0, 0.0, 0.0)];
        [_subtitleLabel setBordered:NO];
        [_subtitleLabel setDrawsBackground:NO];
        [_subtitleLabel setEditable:NO];
        [_subtitleLabel setFont:[BBUAppStyle defaultStyle].subtitleFont];
        [_subtitleLabel setTextColor:[BBUAppStyle defaultStyle].textColor];
        [self addSubview:_subtitleLabel];
    }

    return _subtitleLabel;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20.0, 0.0, 0.0, 20.0)];
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
