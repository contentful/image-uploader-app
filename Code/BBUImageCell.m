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

@property (nonatomic, readonly) NSTextField* descriptionTextField;
@property (nonatomic, readonly) NSImageView* imageView;
@property (nonatomic, readonly) NSTextField* titleTextField;

@end

#pragma mark -

@implementation BBUImageCell

@synthesize descriptionTextField = _descriptionTextField;
@synthesize imageView = _imageView;
@synthesize titleTextField = _titleTextField;

#pragma mark -

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

    [super drawRect:dirtyRect];
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

    self.imageView.alphaValue = editable ? 1.0 : 0.5;

    [self.descriptionTextField setEditable:editable];
    [self.titleTextField setEditable:editable];
}

- (void)setImage:(NSImage *)image {
    self.imageView.image = image;
}

- (void)setTitle:(NSString *)title {
    self.titleTextField.stringValue = title;
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

    [self.draggedFile.asset updateWithSuccess:^{
        if (self.draggedFile.asset.fields[@"file"]) {
            [self.draggedFile.asset processWithSuccess:^{
                NSLog(@"Update successful.");
            } failure:^(CDAResponse *response, NSError *error) {
                NSAlert* alert = [NSAlert alertWithError:error];
                [alert runModal];
            }];
        } else {
            NSLog(@"Update successful.");
        }
    } failure:^(CDAResponse *response, NSError *error) {
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];

    return YES;
}

@end
