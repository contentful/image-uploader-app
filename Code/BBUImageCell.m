//
//  BBUImageCell.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "BBUDraggedFile.h"
#import "BBUImageCell.h"
#import "NSView+Geometry.h"

@interface BBUImageCell () <NSTextFieldDelegate>

@property (nonatomic, readonly) NSRect actualImageRect;
@property (nonatomic, readonly) NSTextField* descriptionTextField;
@property (nonatomic, readonly) NSImageView* failureImageView;
@property (nonatomic, readonly) NSImageView* imageView;
@property (nonatomic, readonly) NSProgressIndicator* progressIndicator;
@property (nonatomic, readonly) NSImageView* successImageView;
@property (nonatomic, readonly) NSTextField* titleTextField;

@end

#pragma mark -

@implementation BBUImageCell

@synthesize descriptionTextField = _descriptionTextField;
@synthesize failureImageView = _failureImageView;
@synthesize imageView = _imageView;
@synthesize titleTextField = _titleTextField;
@synthesize progressIndicator = _progressIndicator;
@synthesize successImageView = _successImageView;

#pragma mark -

- (NSRect)actualImageRect {
    NSRect imageRect = NSMakeRect(0.0, 0.0, self.image.size.width, self.image.size.height);
    return fitRectIntoRectWithDimension(imageRect, self.imageView.bounds, RectAxisVertical);
}

- (NSString *)assetDescription {
    return self.descriptionTextField.stringValue;
}

-(NSTextField *)descriptionTextField {
    if (!_descriptionTextField) {
        _descriptionTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        _descriptionTextField.delegate = self;
        [_descriptionTextField.cell setPlaceholderString:NSLocalizedString(@"Description", nil)];
        [self addSubview:_descriptionTextField];
    }

    return _descriptionTextField;
}

-(void)drawRect:(NSRect)dirtyRect {
    self.imageView.width = self.width - 20.0;
    self.imageView.y = self.height - self.imageView.height - 10.0;

    self.titleTextField.width = self.imageView.width;
    self.titleTextField.y = 20.0;

    self.descriptionTextField.width = self.imageView.width;
    self.descriptionTextField.y = NSMaxY(self.titleTextField.frame) + 10.0;

    self.progressIndicator.x = (self.imageView.width - self.progressIndicator.width) / 2;
    self.progressIndicator.y = self.imageView.y + (self.imageView.height -
                                                   self.progressIndicator.height) / 2;

    self.successImageView.x = self.actualImageRect.size.width + self.imageView.x;
    self.successImageView.y = self.imageView.y;

    self.failureImageView.x = self.successImageView.x;
    self.failureImageView.y = self.successImageView.y + 5.0;

    [super drawRect:dirtyRect];
}

- (NSImageView *)failureImageView {
    if (!_failureImageView) {
        _failureImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 32.0, 32.0)];
        _failureImageView.hidden = YES;
        _failureImageView.image = [NSImage imageNamed:@"failure"];
        [self addSubview:_failureImageView];
    }

    return _failureImageView;
}

- (NSImage *)image {
    return self.imageView.image;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 200.0)];
        [self addSubview:_imageView];
    }

    return _imageView;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [NSColor clearColor];
    }
    return self;
}

-(NSProgressIndicator *)progressIndicator {
    if (!_progressIndicator) {
        _progressIndicator = [[NSProgressIndicator alloc]
                              initWithFrame:NSMakeRect(0.0, 0.0, 64.0, 64.0)];
        [self addSubview:_progressIndicator];
    }

    return _progressIndicator;
}

- (void)setAssetDescription:(NSString *)assetDescription {
    self.descriptionTextField.stringValue = assetDescription;
}

- (void)setDraggedFile:(BBUDraggedFile *)draggedFile {
    if (_draggedFile == draggedFile) {
        return;
    }

    _draggedFile = draggedFile;

    if (self.draggedFile.asset) {
        self.assetDescription = self.draggedFile.asset.description;
    }

    if (self.draggedFile.image) {
        self.image = self.draggedFile.image;
    }

    if (self.draggedFile.asset.title) {
        self.title = self.draggedFile.asset.title;
    } else {
        self.title = [self.draggedFile.originalFileName stringByDeletingPathExtension];
    }
}

- (void)setEditable:(BOOL)editable {
    _editable = editable;

    if (editable) {
        [self.progressIndicator stopAnimation:nil];
        self.progressIndicator.hidden = YES;
    } else {
        self.progressIndicator.hidden = NO;
        self.progressIndicator.style = NSProgressIndicatorSpinningStyle;
        [self.progressIndicator startAnimation:nil];
    }

    self.imageView.alphaValue = editable ? 1.0 : 0.5;

    [self.descriptionTextField setEditable:editable];
    [self.titleTextField setEditable:editable];
}

- (void)setImage:(NSImage *)image {
    self.imageView.image = image;
}

-(void)setShowFailure:(BOOL)showFailure {
    _showFailure = showFailure;

    self.failureImageView.hidden = !showFailure;
}

-(void)setShowSuccess:(BOOL)showSuccess {
    _showSuccess = showSuccess;

    self.successImageView.hidden = !showSuccess;
}

- (void)setTitle:(NSString *)title {
    self.titleTextField.stringValue = title;
}

-(NSImageView *)successImageView {
    if (!_successImageView) {
        _successImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 32.0, 32.0)];
        _successImageView.hidden = YES;
        _successImageView.image = [NSImage imageNamed:@"success"];
        [self addSubview:_successImageView];
    }

    return _successImageView;
}

- (NSString *)title {
    return self.titleTextField.stringValue;
}

- (NSTextField *)titleTextField {
    if (!_titleTextField) {
        _titleTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        _titleTextField.delegate = self;
        [_titleTextField.cell setPlaceholderString:NSLocalizedString(@"Title", nil)];
        [self addSubview:_titleTextField];
    }

    return _titleTextField;
}

#pragma mark - NSTextFieldDelegate

-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if (control == self.descriptionTextField) {
        self.draggedFile.asset.description = fieldEditor.string;
    }

    if (control == self.titleTextField) {
        self.draggedFile.asset.title = fieldEditor.string;
    }

    self.editable = NO;

    [self.draggedFile.asset updateWithSuccess:^{
        if (self.draggedFile.asset.fields[@"file"]) {
            [self.draggedFile.asset processWithSuccess:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.editable = YES;
                });
            } failure:^(CDAResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.error = error;
                    self.showFailure = YES;
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.editable = YES;
            });
        }
    } failure:^(CDAResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.error = error;
            self.showFailure = YES;
        });
    }];

    return YES;
}

@end
