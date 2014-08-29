//
//  BBUMenuCell.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUMenuCell.h"
#import "NSView+Geometry.h"

@interface BBUMenuCell ()

@property (nonatomic, readonly) NSTextField* entryField;
@property (nonatomic, readonly) NSTextField* titleLabel;

@end

#pragma mark -

@implementation BBUMenuCell

@synthesize entryField = _entryField;
@synthesize titleLabel = _titleLabel;

#pragma mark -

-(void)drawRect:(NSRect)dirtyRect {

    self.titleLabel.frame = self.bounds;
    self.titleLabel.height = self.height / 2;
    self.titleLabel.y = self.titleLabel.height;

    self.entryField.frame = self.bounds;
    self.entryField.height = self.titleLabel.height;

    [super drawRect:dirtyRect];
}

- (NSTextField *)entryField {
    if (!_entryField) {
        _entryField = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        _entryField.alphaValue = 0.5;
        _entryField.editable = NO;
        [_entryField.cell setPlaceholderString:self.title];
        [self addSubview:_entryField];
    }

    return _entryField;
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
        [_titleLabel setDrawsBackground:NO];
        [_titleLabel setEditable:NO];
        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

@end
