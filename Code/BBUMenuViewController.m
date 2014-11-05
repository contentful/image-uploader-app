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
@property (nonatomic) NSButton* confirmationButton;
@property (nonatomic, readonly) BBUImageCell* selectedCell;
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

-(BBUImageCell*)selectedCell {
    if (self.relatedCollectionView.indexPathsForSelectedItems.count != 1) {
        return nil;
    }

    NSIndexPath* indexPath = self.relatedCollectionView.indexPathsForSelectedItems.firstObject;
    return (BBUImageCell*)[self.relatedCollectionView cellForItemAtIndexPath:indexPath];
}

-(void)selectionDidChange:(NSNotification*)note {
    self.titleForSelection = note.userInfo[NSLocalizedDescriptionKey];
    [self.collectionView reloadData];

    BBUMenuCell* cell = (BBUMenuCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:0 inSection:0]];
    [cell becomeFirstResponder];
}

-(void)updateConfirmationButton {
    self.confirmationButton.enabled = YES;
    [self.confirmationButton bbu_setPrimaryButtonTitle:NSLocalizedString(@"Update selected", nil)];
}

-(NSString*)valueForRow:(NSUInteger)row {
    BBUMenuCell* cell = (BBUMenuCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:row inSection:0]];
    return cell.entryField.stringValue;
}

#pragma mark - Actions

-(void)confirmClicked:(NSButton*)button {
    button.enabled = NO;
    [button bbu_setPrimaryButtonTitle:NSLocalizedString(@"Saved", nil)];

    NSString* title = [self valueForRow:0];
    NSString* description = [self valueForRow:1];

    [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
        cell.assetDescription = description;
        cell.title = title;

        [cell updateAsset];
    }];
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUMenuCell* cell = (BBUMenuCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];
    NSInteger row = [indexPath indexAtPosition:1];

    switch (row) {
        case 0:
            cell.title = NSLocalizedString(@"Title", nil);

            if (self.selectedCell.title) {
                cell.entryField.stringValue = self.selectedCell.title;
                [cell.entryField.cell setUsesSingleLineMode:YES];
            }
            break;

        case 1:
            cell.title = NSLocalizedString(@"Description", nil);

            if (self.selectedCell.assetDescription) {
                cell.entryField.stringValue = self.selectedCell.assetDescription;
            }
            break;
    }

    cell.tabKeyAction = ^(BBUMenuCell* cell) {
        BBUMenuCell* otherCell = (BBUMenuCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:row == 0 ? 1 : 0 inSection:0]];
        [otherCell.entryField becomeFirstResponder];
    };

    cell.textChangedAction = ^(BBUMenuCell* cell, NSString* newText) {
        [self enumerateCellsInRelatedCollectionViewUsingBlock:^(BBUImageCell *cell) {
            switch (row) {
                case 0:
                    cell.title = newText;
                    break;

                case 1:
                    cell.assetDescription = newText;
                    break;
            }
        }];

        [self updateConfirmationButton];
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
        footerView.confirmationButton.width = 130.0;

        self.confirmationButton = footerView.confirmationButton;

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
