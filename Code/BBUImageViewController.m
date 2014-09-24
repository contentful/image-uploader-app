//
//  BBUImageViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUAppStyle.h"
#import "BBUCollectionView.h"
#import "BBUDraggedFile.h"
#import "BBUEmptyViewController.h"
#import "BBUImageCell.h"
#import "BBUImageViewController.h"
#import "BBUS3Uploader+SharedSettings.h"
#import "CMAClient+SharedClient.h"
#import "NSView+Geometry.h"

@interface BBUImageViewController () <BBUCollectionViewDelegate, JNWCollectionViewDataSource, JNWCollectionViewDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, readonly) BBUCollectionView* collectionView;
@property (nonatomic) NSString* currentSpaceId;
@property (nonatomic, readonly) NSArray* filteredFiles;
@property (nonatomic) NSMutableArray* files;
@property (weak) IBOutlet NSSegmentedControl *filterSelection;
@property (nonatomic, readonly) BBUEmptyViewController* helpViewController;
@property (nonatomic) NSUInteger numberOfUploads;
@property (nonatomic) NSUInteger totalNumberOfUploads;
@property (nonatomic) NSOperationQueue* uploadQueue;

@end

#pragma mark -

@implementation BBUImageViewController

@synthesize helpViewController = _helpViewController;

#pragma mark -

- (void)allowResizing:(BOOL)resizing {
    NSWindow* window = [NSApp windows][0];

    if (resizing) {
        [window setStyleMask:[window styleMask] | NSResizableWindowMask];
    } else {
        [window setStyleMask:[window styleMask] & ~NSResizableWindowMask];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowResize)
                                                 name:NSWindowDidResizeNotification
                                               object:nil];


    self.filterSelection.enabled = NO;
    self.filterSelection.action = @selector(filterChanged);
    self.filterSelection.target = self;

    self.uploadQueue = [NSOperationQueue new];
    self.uploadQueue.maxConcurrentOperationCount = 3;

    self.files = [@[] mutableCopy];

    self.collectionView.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.draggingDelegate = self;

    JNWCollectionViewGridLayout *gridLayout = [JNWCollectionViewGridLayout new];
    gridLayout.itemPaddingEnabled = NO;
    gridLayout.itemSize = CGSizeMake(300, 290);
    self.collectionView.collectionViewLayout = gridLayout;

    [self.collectionView registerClass:BBUImageCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView reloadData];

    self.helpViewController.view.hidden = [self collectionView:self.collectionView
                                        numberOfItemsInSection:0] > 0;
    self.helpViewController.view.y = 0.0;
    self.helpViewController.view.width = self.view.window.frame.size.width;
}

- (BBUCollectionView *)collectionView {
    return (BBUCollectionView*)self.view;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidResizeNotification
                                                  object:nil];
}

- (NSArray *)filteredFiles {
    NSPredicate* predicate = nil;

    switch (self.filterSelection.selectedSegment) {
        case 1:
            predicate = [NSPredicate predicateWithBlock:^BOOL(BBUDraggedFile* file,
                                                              NSDictionary *bindings) {
                return file.asset.URL != nil;
            }];
            break;

        case 2:
            predicate = [NSPredicate predicateWithBlock:^BOOL(BBUDraggedFile* file,
                                                              NSDictionary *bindings) {
                return file.error != nil;
            }];
            break;
    }

    return predicate ? [self.files filteredArrayUsingPredicate:predicate] : self.files;
}

- (BBUEmptyViewController *)helpViewController {
    if (!_helpViewController) {
        _helpViewController = [BBUEmptyViewController new];
        _helpViewController.view.hidden = YES;
        [self.view.superview addSubview:_helpViewController.view];
    }

    return _helpViewController;
}

- (void)postSuccessNotificationIfNeeded {
    if (self.uploadQueue.operationCount == 0) {
        NSUserNotification* note = [NSUserNotification new];
        note.actionButtonTitle = NSLocalizedString(@"View on Contentful", nil);
        note.title = NSLocalizedString(@"Upload completed", nil);
        note.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%d of %d file(s) successfully uploaded.", nil), self.numberOfUploads, self.totalNumberOfUploads];

        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:note];

        self.numberOfUploads = 0;
        self.totalNumberOfUploads = 0;
    }
}

- (void)windowResize {
    self.helpViewController.view.width = self.view.window.frame.size.width;
    self.helpViewController.view.height = self.view.height;
}

#pragma mark - Actions

-(void)filterChanged {
    [self.collectionView reloadData];
}

#pragma mark - BBUCollectionViewDelegate

-(void)collectionView:(BBUCollectionView *)collectionView didDragFiles:(NSArray *)draggedFiles {
    if (![BBUS3Uploader hasValidCredentials]) {
        NSAlert* alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Please provide your Amazon S3 credentials in the Preferences before uploading files.", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
        [alert runModal];
        return;
    }

    self.filterSelection.enabled = draggedFiles.count > 0;
    self.helpViewController.view.hidden = draggedFiles.count > 0;

    [self.files addObjectsFromArray:draggedFiles];
    [collectionView reloadData];

    [[CMAClient sharedClient] fetchSharedSpaceWithSuccess:^(CDAResponse *response, CMASpace *space) {
        self.currentSpaceId = space.identifier;

        for (BBUDraggedFile* draggedFile in draggedFiles) {
            if (!draggedFile.image) {
                continue;
            }

            self.totalNumberOfUploads++;

            NSOperation* operation = [draggedFile creationOperationForSpace:space];

            operation.completionBlock = ^{
                NSError* error = draggedFile.error;

                if (!error) {
                    self.numberOfUploads++;
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.collectionView reloadData];
                    [self postSuccessNotificationIfNeeded];
                });
            };

            [self.uploadQueue addOperation:operation];
        }
    } failure:^(CDAResponse *response, NSError *error) {
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUImageCell* imageCell = (BBUImageCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    BBUDraggedFile* draggedFile = self.filteredFiles[[indexPath indexAtPosition:1]];
    imageCell.draggedFile = draggedFile;

    return imageCell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.filteredFiles.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

#pragma mark - JNWCollectionViewDelegate

-(void)collectionView:(JNWCollectionView *)colview didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUImageCell* cell = (BBUImageCell*)[colview cellForItemAtIndexPath:indexPath];
    cell.userSelected = !cell.userSelected;
    cell.backgroundColor = cell.userSelected ? [NSColor selectedControlColor] : [NSColor whiteColor];
}

#pragma mark - NSUserNotificationCenterDelegate

-(void)userNotificationCenter:(NSUserNotificationCenter *)center
      didActivateNotification:(NSUserNotification *)notification {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets", self.currentSpaceId]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
