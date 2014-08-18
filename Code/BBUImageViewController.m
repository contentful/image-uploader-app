//
//  BBUImageViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUCollectionView.h"
#import "BBUDraggedFile.h"
#import "BBUImageCell.h"
#import "BBUImageViewController.h"

@interface BBUImageViewController () <BBUCollectionViewDelegate, JNWCollectionViewDataSource>

@property (nonatomic, readonly) BBUCollectionView* collectionView;
@property (nonatomic) NSMutableArray* files;

@end

#pragma mark -

@implementation BBUImageViewController

- (void)awakeFromNib {
    [super awakeFromNib];

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

#pragma mark - BBUCollectionViewDelegate

-(void)collectionView:(BBUCollectionView *)collectionView didDragFiles:(NSArray *)draggedFiles {
    [self.files addObjectsFromArray:draggedFiles];
    [collectionView reloadData];
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUImageCell* imageCell = (BBUImageCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    BBUDraggedFile* draggedFile = self.files[[indexPath indexAtPosition:1]];
    imageCell.image = draggedFile.image;

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
