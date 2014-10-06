//
//  BBUMenuCell.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "BBUMenuCell.h"
#import "NSView+Geometry.h"

@interface BBUMenuCell () <NSTextFieldDelegate>

@property (nonatomic, readonly) NSTextField* entryField;
@property (nonatomic, readonly) NSTextField* titleLabel;

@end

#pragma mark -

@implementation BBUMenuCell

@synthesize entryField = _entryField;
@synthesize titleLabel = _titleLabel;

#pragma mark -

-(BOOL)becomeFirstResponder {
    [super becomeFirstResponder];
    return [self.entryField becomeFirstResponder];
}

-(void)drawRect:(NSRect)dirtyRect {
    self.backgroundColor = [NSColor clearColor];

    self.titleLabel.x = 20.0;
    self.titleLabel.width = self.width - 40.0;
    self.titleLabel.height = 20.0;
    self.titleLabel.y = self.height - self.titleLabel.height;

    self.entryField.frame = self.titleLabel.frame;
    self.entryField.height = self.height - self.titleLabel.height - 10.0;
    self.entryField.y = 0.0;

    [super drawRect:dirtyRect];
}

- (NSTextField *)entryField {
    if (!_entryField) {
        _entryField = [[NSTextField alloc] initWithFrame:self.bounds];
        _entryField.delegate = self;
        [_entryField.cell setPlaceholderString:self.title];
        [self addSubview:_entryField];
    }

    return _entryField;
}

-(void)setTitle:(NSString *)title {
    self.titleLabel.stringValue = title;
}

-(void)setValue:(NSString *)value {
    self.entryField.stringValue = value;
}

-(NSString *)title {
    return self.titleLabel.stringValue;
}

-(NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:self.bounds];
        [_titleLabel setBackgroundColor:[BBUAppStyle defaultStyle].darkBackgroundColor];
        [_titleLabel setBordered:NO];
        [_titleLabel setEditable:NO];
        [_titleLabel setFont:[BBUAppStyle defaultStyle].titleFont];
        [_titleLabel setTextColor:[NSColor whiteColor]];
        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

-(NSString*)value {
    return self.entryField.stringValue;
}

#pragma mark - NSTextFieldDelegate

-(BOOL)control:(NSControl*)control
      textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;

    if (commandSelector == @selector(insertNewline:)) {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }

    return result;
}

@end
