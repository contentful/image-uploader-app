//
//  BBUMenuCell.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUMenuCell.h"

@interface BBUMenuCell ()

@property (nonatomic, readonly) NSTextField* titleLabel;

@end

#pragma mark -

@implementation BBUMenuCell

@synthesize titleLabel = _titleLabel;

#pragma mark -

-(void)drawRect:(NSRect)dirtyRect {
    self.titleLabel.frame = self.bounds;

    [super drawRect:dirtyRect];
}

-(void)setTitle:(NSString *)title {
    self.titleLabel.stringValue = title;
}

-(NSString *)title {
    return self.titleLabel.stringValue;
}

-(NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:self.bounds];
        _titleLabel.alignment = NSCenterTextAlignment;
        _titleLabel.font = [NSFont systemFontOfSize:30.0];
        [_titleLabel setDrawsBackground:NO];
        [_titleLabel setEditable:NO];
        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

@end
