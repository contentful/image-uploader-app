//
//  BBUMenuViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUAppStyle.h"
#import "BBUHeaderView.h"
#import "BBUImageCell.h"
#import "BBUMenuCell.h"
#import "BBUMenuViewController.h"
#import "NSView+Geometry.h"

@interface BBUMenuViewController () <JNWCollectionViewDataSource, JNWCollectionViewGridLayoutDelegate>

@property (nonatomic, readonly) JNWCollectionView* collectionView;

@end

#pragma mark -

@implementation BBUMenuViewController

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collectionView.dataSource = self;

    JNWCollectionViewGridLayout *gridLayout = [JNWCollectionViewGridLayout new];
    gridLayout.delegate = self;
    gridLayout.itemSize = CGSizeMake(self.view.width, 50);
    self.collectionView.collectionViewLayout = gridLayout;

    [self.collectionView registerClass:BBUMenuCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView registerClass:BBUHeaderView.class forSupplementaryViewOfKind:JNWCollectionViewGridLayoutHeaderKind withReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView reloadData];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       self.collectionView.backgroundColor = [BBUAppStyle defaultStyle].darkBackgroundColor;
                       self.collectionView.borderType = NSNoBorder;
                   });
}

-(JNWCollectionView *)collectionView {
    return (JNWCollectionView*)self.view;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTableViewSelectionDidChangeNotification
                                                  object:nil];
}

-(void)enumerateCellsInRelatedCollectionViewUsingBlock:(void (^)(BBUImageCell* cell))block {
    NSParameterAssert(block);

    for (NSIndexPath* indexPath in self.relatedCollectionView.indexPathsForSelectedItems) {
        BBUImageCell* cell = (BBUImageCell*)[self.relatedCollectionView cellForItemAtIndexPath:indexPath];
        block(cell);
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(selectionDidChange:)
                                                     name:NSTableViewSelectionDidChangeNotification
                                                   object:nil];
    }
    return self;
}

-(void)selectionDidChange:(NSNotification*)note {
    [self.collectionView reloadData];
}

#pragma mark - JNWCollectionViewDataSource

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
-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)index {
    return self.relatedCollectionView.indexPathsForSelectedItems.count > 0 ? 0.0 : 40.0;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.relatedCollectionView.indexPathsForSelectedItems.count > 0 ? 2 : 0;
}

-(JNWCollectionViewReusableView *)collectionView:(JNWCollectionView *)collectionView viewForSupplementaryViewOfKind:(NSString *)kind inSection:(NSInteger)section {
    BBUHeaderView* headerView = (BBUHeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifer:NSStringFromClass(self.class)];
    headerView.titleLabel.stringValue = NSLocalizedString(@"No selection", nil);
    return headerView;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

@end
