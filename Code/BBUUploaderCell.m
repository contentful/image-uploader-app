//
//  BBUUploaderCell.m
//  image-uploader
//
//  Created by Boris Bügling on 30/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUUploaderCell.h"
#import "NSView+Geometry.h"

@interface BBUUploaderCell ()

@property (nonatomic, readonly) NSImageView* imageView;
@property (nonatomic, readonly) NSTextField* titleLabel;

@end

#pragma mark -

@implementation BBUUploaderCell

@synthesize imageView = _imageView;
@synthesize titleLabel = _titleLabel;

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    self.backgroundColor = [NSColor controlColor];

    self.imageView.height = self.height;
    self.imageView.width = self.imageView.height;

    self.titleLabel.width = self.width - self.imageView.width - 10.0;
    self.titleLabel.height = self.height;
    self.titleLabel.x = NSMaxX(self.imageView.frame);
}

-(NSImage *)image {
    return self.imageView.image;
}

-(NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 0.0)];
        _imageView.wantsLayer = YES;
        [self.contentView addSubview:_imageView];
    }

    return _imageView;
}

-(void)setAlphaValue:(CGFloat)alphaValue {
    [super setAlphaValue:alphaValue];

    self.imageView.layer.opacity = alphaValue;
    self.titleLabel.layer.opacity = alphaValue;
}

-(void)setImage:(NSImage *)image {
    self.imageView.image = image;
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
        [_titleLabel setBackgroundColor:[NSColor controlColor]];
        [_titleLabel setBordered:NO];
        [_titleLabel setEditable:NO];
        [_titleLabel setFont:[NSFont boldSystemFontOfSize:18.0]];
        [_titleLabel setTextColor:[NSColor blackColor]];
        [_titleLabel setWantsLayer:YES];
        [self.contentView addSubview:_titleLabel];
    }

    return _titleLabel;
}

@end
