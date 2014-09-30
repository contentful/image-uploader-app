//
//  BBUImageCell.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>
#import <KVOController/FBKVOController.h>

#import "BBUAppStyle.h"
#import "BBUDraggedFile.h"
#import "BBUDraggedFileFormatter.h"
#import "BBUImageCell.h"
#import "NSView+Geometry.h"

@interface BBUImageCell ()

@property (nonatomic, readonly) NSRect actualImageRect;
@property (nonatomic, readonly) NSButton* deleteButton;
@property (nonatomic, getter = isEditable) BOOL editable;
@property (nonatomic, readonly) NSImageView* failedImageView;
@property (nonatomic, readonly) NSImageView* imageView;
@property (nonatomic, readonly) NSTextField* infoLabel;
@property (nonatomic, readonly) FBKVOController* kvoController;
@property (nonatomic, readonly) NSProgressIndicator* progressIndicator;
@property (nonatomic) BOOL showFailure;
@property (nonatomic) BOOL showSuccess;
@property (nonatomic, readonly) NSImageView* successImageView;
@property (nonatomic, readonly) NSTextField* titleLabel;

@end

#pragma mark -

@implementation BBUImageCell

@synthesize deleteButton = _deleteButton;
@synthesize failedImageView = _failedImageView;
@synthesize imageView = _imageView;
@synthesize infoLabel = _infoLabel;
@synthesize kvoController = _kvoController;
@synthesize progressIndicator = _progressIndicator;
@synthesize successImageView = _successImageView;
@synthesize titleLabel = _titleLabel;

#pragma mark -

- (NSRect)actualImageRect {
    NSRect imageRect = NSMakeRect(0.0, 0.0,
                                  self.imageView.image.size.width, self.imageView.image.size.height);
    return fitRectIntoRectWithDimension(imageRect, self.imageView.bounds, RectAxisVertical);
}

-(void)dealloc {
    [self.kvoController unobserveAll];
}

-(void)deleteAsset {
    [self.draggedFile deleteWithCompletionHandler:^(BOOL success) {
        if (success) {
            self.progressIndicator.hidden = YES;
        } else {
            self.editable = YES;
            self.showFailure = YES;
        }
    }];
}

-(NSButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 32.0, 32.0)];
        _deleteButton.action = @selector(deleteClicked:);
        _deleteButton.bordered = NO;
        _deleteButton.hidden = YES;
        _deleteButton.image = [NSImage imageNamed:@"close"];
        _deleteButton.target = self;
        [self addSubview:_deleteButton];
    }

    return _deleteButton;
}

-(void)drawRect:(NSRect)dirtyRect {
    if (self.trackingAreas.count == 0) {
        NSTrackingArea* trackingArea = [[NSTrackingArea alloc]
                                        initWithRect:self.bounds
                                        options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                        owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    }

    self.backgroundColor = [NSColor clearColor];

    self.deleteButton.y = self.height - self.deleteButton.height;

    self.imageView.width = self.width - 20.0;
    self.imageView.y = self.height - self.imageView.height - 10.0;

    self.infoLabel.width = self.imageView.width;
    self.infoLabel.y = 20.0;

    self.titleLabel.width = self.imageView.width;
    self.titleLabel.y = NSMaxY(self.infoLabel.frame) + 5.0;

    self.progressIndicator.width = self.imageView.width;
    self.progressIndicator.y = NSMaxY(self.titleLabel.frame) + 5.0;

    self.failedImageView.x = MIN(self.actualImageRect.size.width + self.imageView.x + self.failedImageView.width,
                                 self.width - self.failedImageView.width);
    self.failedImageView.y = self.imageView.y + self.actualImageRect.size.height - self.failedImageView.height;

    self.successImageView.x = self.failedImageView.x;
    self.successImageView.y = self.failedImageView.y;

    [super drawRect:dirtyRect];
}

- (NSImageView *)failedImageView {
    if (!_failedImageView) {
        _failedImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 16.0, 16.0)];
        _failedImageView.hidden = YES;
        _failedImageView.image = [NSImage imageNamed:@"Failed"];
        [self addSubview:_failedImageView];
    }

    return _failedImageView;
}

- (NSImageView *)imageView {
    if (!_imageView) {
        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 200.0)];

#if 0
        NSShadow *dropShadow = [[NSShadow alloc] init];
        [dropShadow setShadowColor:[NSColor blackColor]];
        [dropShadow setShadowOffset:NSMakeSize(0, -3.0)];
        [dropShadow setShadowBlurRadius:3.0];

        [_imageView setWantsLayer: YES];
        [_imageView setShadow: dropShadow];
#endif

        [self addSubview:_imageView];
    }

    return _imageView;
}

- (NSTextField *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        [_infoLabel setAlignment:NSCenterTextAlignment];
        [_infoLabel setBordered:NO];
        [_infoLabel setDrawsBackground:NO];
        [_infoLabel setEditable:NO];
        [_infoLabel setFont:[BBUAppStyle defaultStyle].subtitleFont];
        [_infoLabel setHidden:YES];
        [_infoLabel setTextColor:[BBUAppStyle defaultStyle].textColor];
        [self addSubview:_infoLabel];
    }

    return _infoLabel;
}

-(FBKVOController *)kvoController {
    if (!_kvoController) {
        _kvoController = [[FBKVOController alloc] initWithObserver:self];
    }

    return _kvoController;
}

-(void)mouseEntered:(NSEvent *)theEvent {
    self.deleteButton.hidden = NO;
}

-(void)mouseExited:(NSEvent *)theEvent {
    self.deleteButton.hidden = YES;
}

-(NSProgressIndicator *)progressIndicator {
    if (!_progressIndicator) {
        _progressIndicator = [[NSProgressIndicator alloc]
                              initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 5.0)];
        _progressIndicator.doubleValue = self.draggedFile.progress;
        _progressIndicator.indeterminate = NO;
        _progressIndicator.maxValue = 1.0;
        _progressIndicator.style = NSProgressIndicatorBarStyle;
        [self addSubview:_progressIndicator];
    }

    return _progressIndicator;
}

- (void)setAssetDescription:(NSString *)assetDescription {
    self.draggedFile.asset.description = assetDescription;
}

- (void)setDraggedFile:(BBUDraggedFile *)draggedFile {
    if (_draggedFile == draggedFile) {
        return;
    }

    _draggedFile = draggedFile;

    if (self.draggedFile.asset.description) {
        self.assetDescription = self.draggedFile.asset.description;
    }

    self.title = self.draggedFile.title;
    self.editable = draggedFile.asset.URL || draggedFile.error;
    self.imageView.image = self.draggedFile.image;
    self.infoLabel.stringValue = [[BBUDraggedFileFormatter new] stringForObjectValue:self.draggedFile];
    self.showSuccess = draggedFile.asset.URL != nil;
    self.showFailure = draggedFile.error != nil;

    [self.kvoController observe:draggedFile keyPath:@"asset" options:0 block:^(id observer, BBUDraggedFile* draggedFile, NSDictionary *change) {
        if (draggedFile.asset.URL) {
            self.editable = YES;
            self.showSuccess = YES;
        }
    }];

    [self.kvoController observe:draggedFile keyPath:@"error" options:0 block:^(id observer, BBUDraggedFile* draggedFile, NSDictionary *change) {
        if (draggedFile.error) {
            self.editable = YES;
            self.showFailure = YES;
        }
    }];

    [self.kvoController observe:draggedFile keyPath:@"progress" options:0 block:^(id observer, id object, NSDictionary *change) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressIndicator.doubleValue = self.draggedFile.progress;

            [self updateTitleLabel];
        });
    }];

    [self setNeedsDisplay:YES];
}

- (void)setEditable:(BOOL)editable {
    _editable = editable;

    if (editable) {
        self.progressIndicator.hidden = YES;

        self.infoLabel.hidden = NO;
        self.titleLabel.stringValue = self.draggedFile.title;
    } else {
        self.progressIndicator.hidden = NO;

        self.infoLabel.hidden = YES;
        [self updateTitleLabel];
    }

    self.imageView.alphaValue = editable ? 1.0 : 0.3;
}

-(void)setShowFailure:(BOOL)showFailure {
    _showFailure = showFailure;

    if (showFailure) {
        self.failedImageView.hidden = NO;
        self.successImageView.hidden = YES;
    } else {
        self.failedImageView.hidden = YES;
    }
}

-(void)setShowSuccess:(BOOL)showSuccess {
    _showSuccess = showSuccess;

    if (showSuccess) {
        self.failedImageView.hidden = YES;
        self.successImageView.hidden = NO;
    } else {
        self.successImageView.hidden = YES;
    }
}

- (void)setTitle:(NSString *)title {
    self.draggedFile.asset.title = title;
    self.titleLabel.stringValue = title;
}

- (NSImageView *)successImageView {
    if (!_successImageView) {
        _successImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 16.0, 16.0)];
        _successImageView.hidden = YES;
        _successImageView.image = [NSImage imageNamed:@"Check"];
        [self addSubview:_successImageView];
    }

    return _successImageView;
}

- (NSString *)title {
    return self.titleLabel.stringValue;
}

- (NSTextField *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(10.0, 0.0, 0.0, 20.0)];
        [_titleLabel setAlignment:NSCenterTextAlignment];
        [_titleLabel setBordered:NO];
        [_titleLabel setDrawsBackground:NO];
        [_titleLabel setEditable:NO];
        [_titleLabel setFont:[BBUAppStyle defaultStyle].titleFont];
        [_titleLabel setTextColor:[NSColor whiteColor]];
        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

- (void)updateAsset {
    [self.draggedFile updateWithCompletionHandler:^(BOOL success) {
        if (success) {
            self.editable = YES;
        } else {
            self.showFailure = YES;
        }
    }];
}

-(void)updateTitleLabel {
    self.titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Uploading %.0f%%", nil), self.draggedFile.progress * 100];
}

#pragma mark - Actions

-(void)deleteClicked:(id)sender {
    self.editable = NO;

    [self deleteAsset];
}

@end
