//
//  BBUUploaderPreferences.m
//  image-uploader
//
//  Created by Boris Bügling on 30/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <DJProgressHUD/DJProgressHUD.h>
#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <JNWCollectionView/JNWCollectionView.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUS3SettingsSheet.h"
#import "BBUS3Uploader+SharedSettings.h"
#import "BBUUploaderCell.h"
#import "BBUUploaderPreferences.h"

@interface BBUUploaderPreferences () <JNWCollectionViewDataSource, JNWCollectionViewDelegate>

@property (nonatomic) IBOutlet JNWCollectionView* collectionView;
@property (nonatomic) BBUS3SettingsSheet* s3settings;
@property (nonatomic, readonly) BOOL settingsAvailable;
@property (nonatomic) IBOutlet NSButton* unlinkButton;

@end

#pragma mark -

@implementation BBUUploaderPreferences

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collectionView.backgroundColor = [NSColor controlColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    JNWCollectionViewListLayout *listLayout = [JNWCollectionViewListLayout new];
    listLayout.rowHeight = 50.0;
    listLayout.verticalSpacing = 20.0;
    self.collectionView.collectionViewLayout = listLayout;

    [self.collectionView registerClass:BBUUploaderCell.class
            forCellWithReuseIdentifier:NSStringFromClass(self.class)];

    [self refresh];
}

-(id)init {
    self = [self initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(loadingStateChanged:)
                                                     name:DBAuthHelperOSXStateChangedNotification
                                                   object:nil];
    }
    return self;
}

-(void)loadingStateChanged:(NSNotification*)note {
    [self refresh];
}

-(void)refresh {
    [self.collectionView reloadData];

    self.unlinkButton.enabled = self.settingsAvailable && ![DBAuthHelperOSX sharedHelper].loading;
}

-(BOOL)settingsAvailable {
    return [BBUS3Uploader hasValidCredentials] || [DBSession sharedSession].isLinked;
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUUploaderCell* cell = (BBUUploaderCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];
    NSInteger row = [indexPath indexAtPosition:1];

    switch (row) {
        case 0:
            cell.image = [NSImage imageNamed:@"aws-logo"];
            cell.title = NSLocalizedString(@"Amazon S3", nil);
            break;

        case 1:
            cell.image = [NSImage imageNamed:@"dropbox_logo"];
            cell.title = NSLocalizedString(@"Dropbox", nil);
            break;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        cell.alphaValue = self.settingsAvailable ? 0.3 : 1.0;
    });

    return cell;
}

-(NSUInteger)collectionView:(JNWCollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return 2;
}

-(NSInteger)numberOfSectionsInCollectionView:(JNWCollectionView *)collectionView {
    return 1;
}

#pragma mark - Actions

-(IBAction)unlinkClicked:(NSButton*)button {
    [BBUS3Uploader unlink];

    if ([DBSession sharedSession].isLinked) {
        [[DBSession sharedSession] unlinkAll];
    }

    [self refresh];
}

#pragma mark - JNWCollectionViewDelegate

-(void)collectionView:(JNWCollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath indexAtPosition:1];

    switch (row) {
        case 0: {
            self.s3settings = [BBUS3SettingsSheet new];
            [[NSApp windows].lastObject beginSheet:self.s3settings.window
                                 completionHandler:^(NSModalResponse returnCode) {
                                     self.s3settings = nil;

                                     [self refresh];
                                 }];
            break;
        }

        case 1:
            if (![DBSession sharedSession].isLinked) {
                [[DBAuthHelperOSX sharedHelper] authenticate];
            }
            break;
    }
}

#pragma mark - MASPreferencesViewController 

-(NSString *)identifier {
    return @"com.contentful.uploader.settings";
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAdvanced];
}

-(NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Upload", nil);
}

@end
