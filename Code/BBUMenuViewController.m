//
//  BBUMenuViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUAppStyle.h"
#import "BBUConfirmationFooter.h"
#import "BBUHeaderView.h"
#import "BBUImageCell.h"
#import "BBUMenuCell.h"
#import "BBUMenuViewController.h"
#import "NSButton+Contentful.h"
#import "NSView+Geometry.h"

@interface BBUMenuViewController () <JNWCollectionViewDataSource, JNWCollectionViewListLayoutDelegate>

@property (nonatomic, readonly) JNWCollectionView* collectionView;
@property (nonatomic) NSString* titleForSelection;

@end

#pragma mark -

@implementation BBUMenuViewController

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collectionView.dataSource = self;

    JNWCollectionViewListLayout *listLayout = [JNWCollectionViewListLayout new];
    listLayout.delegate = self;
    listLayout.rowHeight = 50.0;
    listLayout.verticalSpacing = 20.0;
    self.collectionView.collectionViewLayout = listLayout;

    [self.collectionView registerClass:BBUMenuCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView registerClass:BBUConfirmationFooter.class forSupplementaryViewOfKind:JNWCollectionViewListLayoutFooterKind withReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView registerClass:BBUHeaderView.class forSupplementaryViewOfKind:JNWCollectionViewListLayoutHeaderKind withReuseIdentifier:NSStringFromClass(self.class)];
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
        if (cell.selectable) {
            block(cell);
        }
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
    self.titleForSelection = note.userInfo[NSLocalizedDescriptionKey];
    [self.collectionView reloadData];

    BBUMenuCell* cell = (BBUMenuCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:0 inSection:0]];
    [cell becomeFirstResponder];
}

-(NSString*)valueForRow:(NSUInteger)row {
    BBUMenuCell* cell = (BBUMenuCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:row inSection:0]];
    return cell.value;
}

#pragma mark - Actions

-(void)confirmClicked:(NSButton*)button {
    NSString* title = [self valueForRow:0];
    NSString* description = [self valueForRow:1];

    [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
        cell.assetDescription = description;
        cell.title = title;
    }];
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

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.relatedCollectionView.indexPathsForSelectedItems.count > 0 ? 2 : 0;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

#pragma mark - JNWCollectionViewListLayoutDelegate

-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForFooterInSection:(NSInteger)index {
    return self.relatedCollectionView.indexPathsForSelectedItems.count > 0 ? 170.0 : 0.0;
}

-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)index {
    return 100.0;
}

-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.jnw_item == 1 ? 150.0 : 50.0;
}

-(JNWCollectionViewReusableView *)collectionView:(JNWCollectionView *)collectionView viewForSupplementaryViewOfKind:(NSString *)kind inSection:(NSInteger)section {
    if ([kind isEqualToString:JNWCollectionViewListLayoutFooterKind]) {
        BBUConfirmationFooter* footerView = (BBUConfirmationFooter*)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifer:NSStringFromClass(self.class)];

        [footerView.confirmationButton bbu_setPrimaryButtonTitle:NSLocalizedString(@"Update selected",
                                                                                   nil)];

        footerView.confirmationButton.action = @selector(confirmClicked:);
        footerView.confirmationButton.target = self;

        footerView.informationLabel.hidden = self.relatedCollectionView.indexPathsForSelectedItems.count <= 1;
        footerView.informationLabel.stringValue = NSLocalizedString(@"Title or description changes will be applied to all selected files", nil);

        return footerView;
    }

    BBUHeaderView* headerView = (BBUHeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifer:NSStringFromClass(self.class)];

    if (self.relatedCollectionView.indexPathsForSelectedItems.count > 0) {
        headerView.subtitleLabel.stringValue = self.titleForSelection;
        headerView.titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d file(s) selected", nil), self.relatedCollectionView.indexPathsForSelectedItems.count];
    } else {
        headerView.subtitleLabel.stringValue = NSLocalizedString(@"Click on file(s) to select or deselect them", nil);
        headerView.titleLabel.stringValue = NSLocalizedString(@"No selection", nil);
    }

    return headerView;
}

@end
