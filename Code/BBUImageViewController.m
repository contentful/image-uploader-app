//
//  BBUImageViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <DJProgressHUD/DJProgressHUD.h>
#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUAppDelegate.h"
#import "BBUAppStyle.h"
#import "BBUCollectionView.h"
#import "BBUDraggedFile.h"
#import "BBUDraggedFileFormatter.h"
#import "BBUDragHintView.h"
#import "BBUEmptyViewController.h"
#import "BBUHeaderView.h"
#import "BBUImageCell.h"
#import "BBUImageViewController.h"
#import "BBUS3Uploader+SharedSettings.h"
#import "CMAClient+SharedClient.h"
#import "NSView+Geometry.h"

@interface BBUImageViewController () <BBUCollectionViewDelegate, JNWCollectionViewDataSource, JNWCollectionViewDelegate, JNWCollectionViewGridLayoutDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, readonly) BBUCollectionView* collectionView;
@property (nonatomic) NSString* currentSpaceId;
@property (nonatomic, readonly) BBUDragHintView* dragHintView;
@property (nonatomic, readonly) NSArray* fileTypes;
@property (nonatomic, readonly) NSArray* filteredFiles;
@property (nonatomic, readonly) NSDictionary* filteredFilesByType;
@property (nonatomic) NSMutableArray* files;
@property (weak) IBOutlet NSSegmentedControl *filterSelection;
@property (nonatomic) BBUHeaderView* headerView;
@property (nonatomic, readonly) BBUEmptyViewController* helpViewController;
@property (nonatomic) NSUInteger lastNumberOfUploads;
@property (nonatomic) NSUInteger numberOfUploads;
@property (weak) IBOutlet NSMenu *sortingMenu;
@property (weak) IBOutlet NSToolbarItem *sortingToolbarItem;
@property (nonatomic) NSInteger sortingType;
@property (weak) IBOutlet NSToolbarItem *spaceSelection;
@property (nonatomic) NSUInteger totalNumberOfUploads;
@property (nonatomic) NSOperationQueue* uploadQueue;

@end

#pragma mark -

@implementation BBUImageViewController

@synthesize dragHintView = _dragHintView;
@synthesize fileTypes = _fileTypes;
@synthesize filteredFilesByType = _filteredFilesByType;
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

    self.sortingToolbarItem.enabled = NO;

    self.uploadQueue = [NSOperationQueue new];
    self.uploadQueue.maxConcurrentOperationCount = 3;

    self.files = [@[] mutableCopy];

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.draggingDelegate = self;

    JNWCollectionViewGridLayout *gridLayout = [JNWCollectionViewGridLayout new];
    gridLayout.delegate = self;
    gridLayout.itemPaddingEnabled = NO;
    gridLayout.itemSize = CGSizeMake(200, 190);
    self.collectionView.collectionViewLayout = gridLayout;

    [self.collectionView registerClass:BBUImageCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView registerClass:BBUHeaderView.class
            forSupplementaryViewOfKind:JNWCollectionViewGridLayoutHeaderKind
                   withReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView reloadData];

    self.helpViewController.view.hidden = [self collectionView:self.collectionView
                                        numberOfItemsInSection:0] > 0;
    self.dragHintView.hidden = !self.helpViewController.view.isHidden;

    [self performSelector:@selector(windowResize) withObject:nil afterDelay:0.1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       self.collectionView.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor;
                       self.collectionView.borderType = NSNoBorder;
                   });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(spaceChanged:)
                                                 name:kContentfulSpaceChanged
                                               object:nil];
}

- (BBUCollectionView *)collectionView {
    return (BBUCollectionView*)self.view;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowDidResizeNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kContentfulSpaceChanged
                                                  object:nil];
}

- (BBUDraggedFile*)draggedFileAtIndexPath:(NSIndexPath*)indexPath {
    if (self.sortingType == 3) {
        NSString* key = self.fileTypes[indexPath.jnw_section];
        return self.filteredFilesByType[key][indexPath.jnw_item];
    }
    
    return self.filteredFiles[[indexPath indexAtPosition:1]];
}

- (BBUDragHintView *)dragHintView {
    if (!_dragHintView) {
        _dragHintView = [[BBUDragHintView alloc] initWithFrame:NSMakeRect(0.0, 0.0,
                                                                          self.view.width, 60.0)];
        [self.view.superview addSubview:self.dragHintView];
    }

    return _dragHintView;
}

- (void)enqueueOperationForDraggedFile:(BBUDraggedFile*)draggedFile {
    CMASpace* sharedSpace = [CMAClient sharedClient].sharedSpace;
    NSOperation* operation = [draggedFile creationOperationForSpace:sharedSpace];

    if ([self.uploadQueue.operations containsObject:operation]) {
        return;
    }

    operation.completionBlock = ^{
        NSError* error = draggedFile.error;

        if (!error) {
            self.numberOfUploads++;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            [self postSuccessNotificationIfNeeded];
            [self updateHeaderView];
        });
    };

    [self.uploadQueue addOperation:operation];
}

- (NSArray *)fileTypes {
    if (!_fileTypes) {
        _fileTypes = [self.filteredFilesByType.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }

    return _fileTypes;
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

    NSArray *files = predicate ? [self.files filteredArrayUsingPredicate:predicate] : self.files;
    return [self sortedArrayUsingCurrentFilter:files];
}

- (NSDictionary*)filteredFilesByType {
    if (!_filteredFilesByType) {
        NSMutableDictionary* filteredFiles = [@{} mutableCopy];

        for (BBUDraggedFile* file in self.files) {
            NSMutableArray* filesByType = filteredFiles[file.fileType];
            if (!filesByType) {
                filesByType = [@[] mutableCopy];
                filteredFiles[file.fileType] = filesByType;
            }

            [filesByType addObject:file];
        }

        _fileTypes = nil;
        _filteredFilesByType = [filteredFiles copy];
    }

    return _filteredFilesByType;
}

- (BBUEmptyViewController *)helpViewController {
    if (!_helpViewController) {
        _helpViewController = [BBUEmptyViewController new];
        _helpViewController.view.hidden = YES;
        [self.view.superview addSubview:_helpViewController.view];

        __weak typeof(self) welf = self;
        _helpViewController.browseAction = ^(NSButton* button) {
            [welf selectFilesToUpload];
        };
    }

    return _helpViewController;
}

- (void)moveSelectionForward:(BOOL)forward {
    if (self.sortingType == 3) {
        return;
    }

    NSIndexPath* indexPath = self.collectionView.indexPathsForSelectedItems.firstObject;
    NSInteger item = 0;

    if (indexPath) {
        if (forward) {
            item = (indexPath.jnw_item + 1) % self.filteredFiles.count;
        } else {
            item = indexPath.jnw_item == 0 ? self.filteredFiles.count - 1 : indexPath.jnw_item - 1;
        }
    }

    indexPath = [NSIndexPath jnw_indexPathForItem:item inSection:0];

    [self.collectionView deselectAllItems];
    [self.collectionView selectItemAtIndexPath:indexPath atScrollPosition:JNWCollectionViewScrollPositionMiddle animated:YES];
}

- (void)postSuccessNotificationIfNeeded {
    if (self.uploadQueue.operationCount == 0) {
        NSUserNotification* note = [NSUserNotification new];
        note.actionButtonTitle = NSLocalizedString(@"View on Contentful", nil);
        note.title = NSLocalizedString(@"Upload completed", nil);
        note.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%d of %d file(s) successfully uploaded.", nil), self.numberOfUploads, self.totalNumberOfUploads];

        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
        [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:note];

        self.spaceSelection.enabled = YES;

        self.lastNumberOfUploads = self.numberOfUploads;
        self.numberOfUploads = 0;
        self.totalNumberOfUploads = 0;
    }
}

- (void)refresh {
    self.filterSelection.enabled = self.uploadQueue.operationCount > 0;
    self.headerView.hidden = self.uploadQueue.operationCount == 0;
    self.helpViewController.view.hidden = self.files.count > 0;
    self.sortingToolbarItem.enabled = self.uploadQueue.operationCount > 0;
    self.spaceSelection.enabled = self.uploadQueue.operationCount == 0;

    self.dragHintView.hidden = !self.helpViewController.view.isHidden;

    NSArray* selection = [self selectedFiles];
    
    [self.collectionView reloadData];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self restoreSelection:selection];
    });
}

-(void)restoreSelection:(NSArray*)selection {
    if (self.sortingType == 3) {
        return;
    }

    for (BBUDraggedFile* draggedFile in selection) {
        NSUInteger row = [self.filteredFiles indexOfObject:draggedFile];
        if (row == NSNotFound) {
            continue;
        }

        NSIndexPath* indexPath = [NSIndexPath jnw_indexPathForItem:row inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath
                                  atScrollPosition:JNWCollectionViewScrollPositionNone
                                          animated:NO];
    }
}

- (NSArray*)selectedFiles {
    NSMutableArray* selectedFiles = [@[] mutableCopy];

    for (NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems) {
        BBUDraggedFile* draggedFile = [self draggedFileAtIndexPath:indexPath];
        [selectedFiles addObject:draggedFile];
    }

    return [selectedFiles copy];
}

- (void)selectFilesToUpload {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = YES;
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    [openPanel runModal];

    if (openPanel.URLs.count > 0) {
        NSMutableArray* files = [@[] mutableCopy];
        for (NSURL* url in openPanel.URLs) {
            [files addObject:[[BBUDraggedFile alloc] initWithURL:url]];
        }

        [self collectionView:self.collectionView didDragFiles:[files copy]];
    }
}

- (void)spaceChanged:(NSNotification*)note {
    [self.files makeObjectsPerformSelector:@selector(writeToPersistentStore)];
    [self.collectionView deselectAllItems];
    [self.files removeAllObjects];

    [DJProgressHUD showStatus:NSLocalizedString(@"Restoring assets...", nil)
                     FromView:self.view];

    [BBUDraggedFile fetchFilesForSpace:note.userInfo[kContentfulSpaceChanged] fromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        [self.files addObjectsFromArray:array];
        [self refresh];

        [DJProgressHUD dismiss];
    }];
}

- (void)updateHeaderView {
    if (self.uploadQueue.operationCount == 0) {
        self.headerView.titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%d file(s) successfully uploaded", nil), self.lastNumberOfUploads];
        return;
    }

    if (self.totalNumberOfUploads < self.numberOfUploads) {
        self.totalNumberOfUploads = self.numberOfUploads;
    }

    NSUInteger percentage = self.totalNumberOfUploads == 0 ? 0 : ((float)self.numberOfUploads / self.totalNumberOfUploads) * 100;

    self.headerView.titleLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Uploaded %d of %d file(s) %d%% done.", nil), self.numberOfUploads, self.totalNumberOfUploads, percentage];
}

- (void)windowResize {
    self.helpViewController.view.y = 0.0;
    self.helpViewController.view.width = self.view.window.frame.size.width;
    self.helpViewController.view.height = self.view.height;

    self.dragHintView.width = MAX(self.view.width, 20.0);
}

#pragma mark - Actions

-(void)openAssetClicked:(NSMenuItem*)menuItem {
    BBUDraggedFile* draggedFile = menuItem.representedObject;
    NSString* urlString = [NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets/%@", draggedFile.space.identifier, draggedFile.asset.identifier];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

-(void)copyURLClicked:(NSMenuItem*)menuItem {
    BBUDraggedFile* draggedFile = menuItem.representedObject;
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:draggedFile.asset.URL.absoluteString forType:NSStringPboardType];
}

- (IBAction)deleteClicked:(NSMenuItem *)sender {
    for (NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems) {
        BBUImageCell* cell = (BBUImageCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell deleteAsset];
    }

    [self.collectionView deselectAllItems];
}

-(void)filterChanged {
    [self.collectionView reloadData];
}

- (IBAction)nextClicked:(NSMenuItem *)sender {
    [self moveSelectionForward:YES];
}

- (IBAction)previousClicked:(NSMenuItem *)sender {
    [self moveSelectionForward:NO];
}

- (NSArray*)sortedArrayUsingCurrentFilter:(NSArray*)files {
    return [files sortedArrayUsingComparator:^NSComparisonResult(BBUDraggedFile* file1,
                                                                 BBUDraggedFile* file2) {
        switch (self.sortingType) {
            case 2:
                return file1.numberOfBytes > file2.numberOfBytes;

            case 3:
                return [file1.fileType compare:file2.fileType options:NSCaseInsensitiveSearch];

            case 4:
                return [file1.mtime compare:file2.mtime];

            default:
                break;
        }

        return [file1.title compare:file2.title options:NSCaseInsensitiveSearch];
    }];
}

- (IBAction)sortingOptionSelected:(NSMenuItem*)menuItem {
    for (NSMenuItem* item in self.sortingMenu.itemArray) {
        item.state = NSOffState;
    }

    menuItem.state = NSOnState;
    self.sortingType = menuItem.tag;

    [self.collectionView reloadData];
}

- (IBAction)uploadFilesClicked:(NSMenuItem*)menuItem {
    [self selectFilesToUpload];
}

#pragma mark - BBUCollectionViewDelegate

-(void)collectionView:(BBUCollectionView *)collectionView didDragFiles:(NSArray *)draggedFiles {
    if (![BBUS3Uploader hasValidCredentials] && ![DBSession sharedSession].isLinked) {
        [[NSApp delegate] performSelector:@selector(showPreferences)];
        return;
    }

    _filteredFilesByType = nil;

    [self.files addObjectsFromArray:draggedFiles];
    [self refresh];

    CMASpace* sharedSpace = [CMAClient sharedClient].sharedSpace;
    self.currentSpaceId = sharedSpace.identifier;

    for (BBUDraggedFile* draggedFile in [self sortedArrayUsingCurrentFilter:draggedFiles]) {
        if (!draggedFile.image) {
            continue;
        }

        self.totalNumberOfUploads++;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateHeaderView];
        });

        [self enqueueOperationForDraggedFile:draggedFile];
    }

    [self refresh];
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUImageCell* imageCell = (BBUImageCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    BBUDraggedFile* draggedFile = [self draggedFileAtIndexPath:indexPath];
    imageCell.draggedFile = draggedFile;

    __weak typeof(self) welf = self;
    imageCell.deletionHandler = ^(BBUImageCell* cell) {
        __strong typeof(self) sself = welf;

        [sself.files removeObject:cell.draggedFile];
        _filteredFilesByType = nil;
        
        [sself.collectionView reloadData];
    };

    return imageCell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    if (self.sortingType == 3) {
        NSString* key = self.fileTypes[section];
        return [self.filteredFilesByType[key] count];
    }

    return self.filteredFiles.count;
}

-(JNWCollectionViewReusableView *)collectionView:(JNWCollectionView *)collectionView viewForSupplementaryViewOfKind:(NSString *)kind inSection:(NSInteger)section {
    BBUHeaderView* headerView = (BBUHeaderView*)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifer:NSStringFromClass(self.class)];

    if (section != 0) {
        if (self.headerView == headerView) {
            self.headerView = nil;
        }

        headerView.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor;
        headerView.closeButton.hidden = YES;
        headerView.separator.hidden = NO;
        headerView.titleLabel.stringValue = self.fileTypes[section];
        return headerView;
    }

    headerView.backgroundColor = [BBUAppStyle defaultStyle].lightBackgroundColor;
    headerView.hidden = self.headerView.isHidden;

    self.headerView = headerView;
    self.headerView.closeButton.hidden = NO;
    self.headerView.separator.hidden = YES;
    
    [self updateHeaderView];
    return headerView;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return self.sortingType == 3 ? self.filteredFilesByType.allKeys.count : 1;
}

-(void)updateSelectionForCellAtIndexPath:(NSIndexPath*)indexPath {
    BBUImageCell* cell = (BBUImageCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

    if (!cell.selectable) {
        return;
    }

    NSMutableDictionary* info = [@{} mutableCopy];

    switch (self.collectionView.indexPathsForSelectedItems.count ) {
        case 0:
            break;

        case 1:
            info[NSLocalizedDescriptionKey] = [[BBUDraggedFileFormatter new] stringForObjectValue:[self draggedFileAtIndexPath:self.collectionView.indexPathsForSelectedItems.firstObject]];
            break;

        default: {
            NSMutableArray* selectedFiles = [@[] mutableCopy];
            for (NSIndexPath* indexPath in self.collectionView.indexPathsForSelectedItems) {
                [selectedFiles addObject:[self draggedFileAtIndexPath:indexPath]];
            }

            info[NSLocalizedDescriptionKey] = [[BBUDraggedFileFormatter new] stringForObjectValue:[selectedFiles copy]];
            break;
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification
                                                        object:self.collectionView
                                                      userInfo:info];

    cell.backgroundColor = cell.selected ? [[BBUAppStyle defaultStyle] selectionColor] : [NSColor clearColor];
}

#pragma mark - JNWCollectionViewDelegate

-(void)collectionView:(JNWCollectionView *)colview didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSelectionForCellAtIndexPath:indexPath];
}

-(void)collectionView:(JNWCollectionView *)colview didRightClickItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUDraggedFile* draggedFile = [self draggedFileAtIndexPath:indexPath];

    if (!draggedFile.asset) {
        return;
    }

    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@""];
    theMenu.autoenablesItems = YES;

    NSMenuItem* menuItem = [theMenu insertItemWithTitle:NSLocalizedString(@"Open Asset in Browser", nil)
                                                 action:@selector(openAssetClicked:)
                                          keyEquivalent:@""
                                                atIndex:0];
    menuItem.representedObject = draggedFile;
    menuItem.target = self;

    if (draggedFile.asset.URL) {
        menuItem = [theMenu insertItemWithTitle:NSLocalizedString(@"Copy URL", nil)
                                         action:@selector(copyURLClicked:)
                                  keyEquivalent:@""
                                        atIndex:0];
        menuItem.representedObject = draggedFile;
        menuItem.target = self;
    }

    [NSMenu popUpContextMenu:theMenu
                   withEvent:[NSApp currentEvent]
                     forView:[self.collectionView cellForItemAtIndexPath:indexPath]];
}

-(void)collectionView:(JNWCollectionView *)colview didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSelectionForCellAtIndexPath:indexPath];

    BBUImageCell* cell = (BBUImageCell*)[self.collectionView cellForItemAtIndexPath:indexPath];

    if (!cell.selectable && cell.draggedFile.error && !cell.draggedFile.asset.URL) {
        [self enqueueOperationForDraggedFile:cell.draggedFile];
        [self refresh];
    }
}

#pragma mark - JNWCollectionViewGridLayoutDelegate

-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForFooterInSection:(NSInteger)index {
    return index == [self numberOfSectionsInCollectionView:collectionView] - 1 ? 60.0 : 0.0;
}

-(CGFloat)collectionView:(JNWCollectionView *)collectionView heightForHeaderInSection:(NSInteger)index {
    return self.headerView.isHidden ? 0.0 : 40.0;
}

#pragma mark - NSUserNotificationCenterDelegate

-(void)userNotificationCenter:(NSUserNotificationCenter *)center
      didActivateNotification:(NSUserNotification *)notification {
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets", self.currentSpaceId]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
