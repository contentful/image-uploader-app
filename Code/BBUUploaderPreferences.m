//
//  BBUUploaderPreferences.m
//  image-uploader
//
//  Created by Boris Bügling on 30/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <JNWCollectionView/JNWCollectionView.h>

#import "BBUS3SettingsSheet.h"
#import "BBUS3Uploader+SharedSettings.h"
#import "BBUUploaderCell.h"
#import "BBUUploaderPreferences.h"
#import "NSView+Geometry.h"

typedef NS_ENUM(NSUInteger, UploaderType) {
    kDropbox,
    kAmazonS3,
};

@interface BBUUploaderPreferences () <JNWCollectionViewDataSource, JNWCollectionViewDelegate>

@property (nonatomic) IBOutlet NSButton* actionButton;
@property (nonatomic) IBOutlet JNWCollectionView* collectionView;
@property (nonatomic) UploaderType currentUploaderType;
@property (nonatomic) IBOutlet NSTextField* informationLabel;
@property (nonatomic) IBOutlet NSView* mainView;
@property (nonatomic) BBUS3SettingsSheet* s3settings;

@end

#pragma mark -

@implementation BBUUploaderPreferences

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collectionView.backgroundColor = [NSColor controlColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    JNWCollectionViewListLayout *listLayout = [JNWCollectionViewListLayout new];
    listLayout.rowHeight = 25.0;
    listLayout.verticalSpacing = 5.0;
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

    self.actionButton.enabled = ![DBAuthHelperOSX sharedHelper].loading;
}

-(void)refresh {
    [self.collectionView reloadData];

    NSString* const pleaseLinkText = NSLocalizedString(@"Before uploading assets, please link Contentful Media Uploader app to a cloud storage service for storing your files during upload and processing.", nil);

    NSIndexPath* indexPath = nil;

    switch (self.currentUploaderType) {
        case kAmazonS3:
            indexPath = [NSIndexPath jnw_indexPathForItem:0 inSection:0];

            self.actionButton.enabled = YES;
            self.actionButton.title = NSLocalizedString(@"Link Amazon S3", nil);

            if ([BBUS3Uploader hasValidCredentials]) {
                self.actionButton.title = NSLocalizedString(@"Unlink Amazon S3", nil);
                self.informationLabel.stringValue = [NSString stringWithFormat:@"%@\n\n\n%@", NSLocalizedString(@"You currently use Amazon S3 for storing your files during upload and processing. If you wish to use other cloud storage services, please first unlink your Amazon S3 bucket.", nil), [BBUS3Uploader credentialString]];
            } else if ([DBSession sharedSession].isLinked) {
                self.actionButton.enabled = NO;
                self.informationLabel.stringValue = NSLocalizedString(@"Please unlink other cloud storage services before connecting your Amazon S3 account to Contentful Media Uploader app.", nil);
            } else {
                self.informationLabel.stringValue = pleaseLinkText;
            }
            break;

        case kDropbox:
            indexPath = [NSIndexPath jnw_indexPathForItem:1 inSection:0];

            self.actionButton.enabled = YES;
            self.actionButton.title = NSLocalizedString(@"Link to Dropbox", nil);

            if ([DBSession sharedSession].isLinked) {
                self.actionButton.title = NSLocalizedString(@"Unlink Dropbox", nil);
                self.informationLabel.stringValue = NSLocalizedString(@"You currently use Dropbox for storing your files during upload and processing. If you wish to use other cloud storage services, please first unlink your Dropbox account.", nil);
            } else if ([BBUS3Uploader hasValidCredentials]) {
                self.actionButton.enabled = NO;
                self.informationLabel.stringValue = NSLocalizedString(@"Please unlink other cloud storage services before connecting your Dropbox account to Contentful Media Uploader app.", nil);
            } else {
                self.informationLabel.stringValue = pleaseLinkText;
            }
            break;
    }

    self.actionButton.width = 140.0;
    self.actionButton.x = (self.mainView.width - self.actionButton.width) / 2;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       JNWCollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
                       cell.backgroundColor = [NSColor selectedMenuItemColor];
    });
}

#pragma mark - JNWCollectionViewDataSource

-(JNWCollectionViewCell *)collectionView:(JNWCollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BBUUploaderCell* cell = (BBUUploaderCell*)[collectionView dequeueReusableCellWithIdentifier:NSStringFromClass(self.class)];

    switch ([indexPath indexAtPosition:1]) {
        case 0:
            cell.image = [NSImage imageNamed:@"aws-logo"];
            cell.title = NSLocalizedString(@"Amazon S3", nil);
            break;

        case 1:
            cell.image = [NSImage imageNamed:@"dropbox_logo"];
            cell.title = NSLocalizedString(@"Dropbox", nil);
            break;
    }

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

-(IBAction)actionButtonPressed:(NSButton*)sender {
    switch (self.currentUploaderType) {
        case kAmazonS3:
            if ([BBUS3Uploader hasValidCredentials]) {
                [BBUS3Uploader unlink];
                [self refresh];
            } else {
                self.s3settings = [BBUS3SettingsSheet new];

                __weak typeof(self) welf = self;
                self.s3settings.completionHandler = ^{
                    welf.s3settings = nil;

                    [welf refresh];
                };

                [[NSApp windows][1] beginSheet:self.s3settings.window
                             completionHandler:nil];
            }
            break;

        case kDropbox:
            if ([DBSession sharedSession].isLinked) {
                [[DBSession sharedSession] unlinkAll];

                [self refresh];
            } else {
                sender.enabled = NO;

                [[DBAuthHelperOSX sharedHelper] authenticate];
            }
            break;
    }
}

#pragma mark - JNWCollectionViewDelegate

-(void)collectionView:(JNWCollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentUploaderType = [indexPath indexAtPosition:1] == 0 ? kAmazonS3 : kDropbox;

    [self refresh];
}

#pragma mark - MASPreferencesViewController 

-(NSString *)identifier {
    return @"com.contentful.uploader.settings";
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAdvanced];
}

-(NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Storage Services", nil);
}

-(void)viewWillAppear {
    [self.collectionView selectItemAtIndexPath:[NSIndexPath jnw_indexPathForItem:1 inSection:0] atScrollPosition:JNWCollectionViewScrollPositionNone animated:NO];
    [self refresh];
}

@end
