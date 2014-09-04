//
//  BBUMenuViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUImageCell.h"
#import "BBUMenuCell.h"
#import "BBUMenuViewController.h"
#import "NSView+Geometry.h"

@interface BBUMenuViewController () <JNWCollectionViewDataSource>

@property (nonatomic, readonly) JNWCollectionView* collectionView;

@end

#pragma mark -

@implementation BBUMenuViewController

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collectionView.dataSource = self;

    JNWCollectionViewGridLayout *gridLayout = [JNWCollectionViewGridLayout new];
    gridLayout.itemSize = CGSizeMake(self.view.width, 50);
    self.collectionView.collectionViewLayout = gridLayout;

    [self.collectionView registerClass:BBUMenuCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView reloadData];
}

-(JNWCollectionView *)collectionView {
    return (JNWCollectionView*)self.view;
}

-(void)enumerateCellsInRelatedCollectionViewUsingBlock:(void (^)(BBUImageCell* cell))block {
    NSParameterAssert(block);

    for (NSIndexPath* indexPath in self.relatedCollectionView.indexPathsForVisibleItems) {
        BBUImageCell* cell = (BBUImageCell*)[self.relatedCollectionView cellForItemAtIndexPath:indexPath];

        if (!cell.userSelected) {
            continue;
        }

        block(cell);
    }
}

#pragma mark -

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUMenuCell* cell = (BBUMenuCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    switch ([indexPath indexAtPosition:1]) {
        case 0: {
            cell.textChangedHandler = ^(BBUMenuCell* cell, NSString* text) {
                [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
                    cell.title = text;
                }];
            };

            cell.title = NSLocalizedString(@"Title", nil);
            break;
        }

        case 1: {
            cell.textChangedHandler = ^(BBUMenuCell* cell, NSString* text) {
                [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
                    cell.assetDescription = text;
                }];
            };

            cell.title = NSLocalizedString(@"Description", nil);
            break;
        }
    }

    cell.endEditingHandler = ^(BBUMenuCell* cell) {
        [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
            [cell updateAsset];
        }];
    };

    return cell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return 2;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

@end
