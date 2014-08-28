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
#import "BBUImageCell.h"
#import "BBUImageViewController.h"
#import "CMAClient+SharedClient.h"

@interface BBUImageViewController () <BBUCollectionViewDelegate, JNWCollectionViewDataSource>

@property (nonatomic, readonly) BBUCollectionView* collectionView;
@property (nonatomic) NSMutableArray* files;
@property (nonatomic) NSUInteger numberOfUploads;
@property (nonatomic) NSOperationQueue* uploadQueue;

@end

#pragma mark -

@implementation BBUImageViewController

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

- (void)postSuccessNotificationIfNeeded {
    if (self.uploadQueue.operationCount == 0) {
        NSUserNotification* note = [NSUserNotification new];
        note.title = NSLocalizedString(@"Upload completed", nil);
        note.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%d file(s) successfully uploaded.", nil), self.numberOfUploads];

        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:note];

        self.numberOfUploads = 0;
    }
}

- (void)setCellStatus:(BBUImageCell*)cell withError:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        cell.error = error;
        cell.showFailure = error != nil;
        cell.showSuccess = error == nil;
    });
}

#pragma mark - BBUCollectionViewDelegate

-(void)collectionView:(BBUCollectionView *)collectionView didDragFiles:(NSArray *)draggedFiles {
    [self.files addObjectsFromArray:draggedFiles];
    [collectionView reloadData];

    [[CMAClient sharedClient] fetchSharedSpaceWithSuccess:^(CDAResponse *response, CMASpace *space) {
        for (BBUDraggedFile* draggedFile in draggedFiles) {
            NSUInteger idx = [self.files indexOfObject:draggedFile];
            BBUImageCell* cell = (BBUImageCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:idx inSection:0]];

            [space createAssetWithTitle:@{ space.defaultLocale: cell.title }
                            description:nil
                           fileToUpload:nil
                                success:^(CDAResponse *response, CMAAsset *asset) {
                                    draggedFile.asset = asset;
                                    draggedFile.space = space;

                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        cell.editable = YES;
                                    });

                                    BBUAssetUploadOperation* operation = [[BBUAssetUploadOperation alloc] initWithDraggedFile:draggedFile];

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
    imageCell.editable = NO;

    BBUDraggedFile* draggedFile = self.files[[indexPath indexAtPosition:1]];
    imageCell.draggedFile = draggedFile;

    return imageCell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.files.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

@end
