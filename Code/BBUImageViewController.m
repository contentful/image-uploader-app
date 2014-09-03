//
//  BBUImageViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUAssetUploadOperation.h"
#import "BBUCollectionView.h"
#import "BBUDraggedFile.h"
#import "BBUHelpView.h"
#import "BBUImageCell.h"
#import "BBUImageViewController.h"
#import "CMAClient+SharedClient.h"
#import "NSView+Geometry.h"

@interface BBUImageViewController () <BBUCollectionViewDelegate, JNWCollectionViewDataSource, NSUserNotificationCenterDelegate>

@property (nonatomic, readonly) BBUCollectionView* collectionView;
@property (nonatomic) NSString* currentSpaceId;
@property (nonatomic) NSMutableArray* files;
@property (nonatomic, readonly) BBUHelpView* helpView;
@property (nonatomic) NSUInteger numberOfUploads;
@property (nonatomic) NSUInteger totalNumberOfUploads;
@property (nonatomic) NSOperationQueue* uploadQueue;

@end

#pragma mark -

@implementation BBUImageViewController

@synthesize helpView = _helpView;

#pragma mark -

- (void)awakeFromNib {
    [super awakeFromNib];

    self.uploadQueue = [NSOperationQueue new];
    self.uploadQueue.maxConcurrentOperationCount = 3;

    self.files = [@[] mutableCopy];

    self.collectionView.dataSource = self;
    self.collectionView.draggingDelegate = self;

    JNWCollectionViewGridLayout *gridLayout = [JNWCollectionViewGridLayout new];
    gridLayout.itemPaddingEnabled = NO;
    gridLayout.itemSize = CGSizeMake(300, 300);
    self.collectionView.collectionViewLayout = gridLayout;

    [self.collectionView registerClass:BBUImageCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView reloadData];
}

- (BBUCollectionView *)collectionView {
    return (BBUCollectionView*)self.view;
}

- (BBUHelpView *)helpView {
    if (!_helpView) {
        _helpView = [[BBUHelpView alloc] initWithFrame:self.view.bounds];
        _helpView.hidden = YES;
        _helpView.helpText = NSLocalizedString(@"Drop images here to upload them to Contentful.", nil);
        [self.view addSubview:_helpView];
    }

    return _helpView;
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

- (void)setCellStatus:(BBUImageCell*)cell withError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        cell.draggedFile.error = error;
        cell.showFailure = error != nil;
        cell.showSuccess = error == nil;
    });
}

- (void)viewWillAppear {
    [super viewWillAppear];

    self.helpView.hidden = [self collectionView:self.collectionView numberOfItemsInSection:0] > 0;
    self.helpView.width = self.view.width;
}

#pragma mark - BBUCollectionViewDelegate

-(void)collectionView:(BBUCollectionView *)collectionView didDragFiles:(NSArray *)draggedFiles {
    self.helpView.hidden = draggedFiles.count > 0;

    [self.files addObjectsFromArray:draggedFiles];
    [collectionView reloadData];

    [[CMAClient sharedClient] fetchSharedSpaceWithSuccess:^(CDAResponse *response, CMASpace *space) {
        self.currentSpaceId = space.identifier;

        for (BBUDraggedFile* draggedFile in draggedFiles) {
            if (!draggedFile.image) {
                continue;
            }

            self.totalNumberOfUploads++;

            NSUInteger idx = [self.files indexOfObject:draggedFile];
            BBUImageCell* cell = (BBUImageCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:idx inSection:0]];

            [space createAssetWithTitle:@{ space.defaultLocale: cell.title ?: @"" }
                            description:nil
                           fileToUpload:nil
                                success:^(CDAResponse *response, CMAAsset *asset) {
                                    draggedFile.asset = asset;
                                    draggedFile.space = space;

                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        cell.editable = YES;
                                    });

                                    BBUAssetUploadOperation* operation = [[BBUAssetUploadOperation alloc] initWithDraggedFile:draggedFile];
                                    operation.cell = cell;

                                    __weak typeof(operation) weakOperation = operation;
                                    operation.completionBlock = ^{
                                        NSError* error = weakOperation.error;

                                        if (error) {
                                            [self setCellStatus:cell withError:error];
                                        } else {
                                            self.numberOfUploads++;

                                            [self setCellStatus:cell withError:nil];
                                        }

                                        [self postSuccessNotificationIfNeeded];
                                    };

                                    [self.uploadQueue addOperation:operation];
                                } failure:^(CDAResponse *response, NSError *error) {
                                    [self setCellStatus:cell withError:error];
                                }];
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

    BBUDraggedFile* draggedFile = self.files[[indexPath indexAtPosition:1]];
    imageCell.draggedFile = draggedFile;
    imageCell.editable = draggedFile.asset.URL != nil;

    return imageCell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.files.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

#pragma mark - NSUserNotificationCenterDelegate

-(void)userNotificationCenter:(NSUserNotificationCenter *)center
      didActivateNotification:(NSUserNotification *)notification {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets", self.currentSpaceId]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
