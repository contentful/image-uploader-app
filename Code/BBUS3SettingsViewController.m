 //
//  BBUS3SettingsViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 09/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUS3SettingsViewController.h"
#import "BBUS3Uploader+SharedSettings.h"

@interface BBUS3SettingsViewController ()

@property (weak) IBOutlet NSTextField *awsKeyTextField;
@property (weak) IBOutlet NSTextField *awsSecretTextField;
@property (weak) IBOutlet NSButton *linkDropboxButton;
@property (weak) IBOutlet NSTextField *s3BucketTextField;
@property (weak) IBOutlet NSTextField *uploadPathTextField;

@end

#pragma mark -

@implementation BBUS3SettingsViewController

-(void)awakeFromNib {
    [super awakeFromNib];

    self.linkDropboxButton.enabled = ![DBSession sharedSession].isLinked;
}

-(BOOL)commitEditing {
    [SSKeychain setPassword:self.awsKeyTextField.stringValue forService:kS3Key account:kS3Key];
    [SSKeychain setPassword:self.awsSecretTextField.stringValue forService:kS3Secret account:kS3Secret];
    [SSKeychain setPassword:self.s3BucketTextField.stringValue forService:kS3Bucket account:kS3Bucket];
    [SSKeychain setPassword:self.uploadPathTextField.stringValue forService:kS3Path account:kS3Path];

    return YES;
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
    self.linkDropboxButton.enabled = ![DBAuthHelperOSX sharedHelper].loading;
}

#pragma mark - Actions

- (IBAction)linkDropboxClicked:(NSButton *)sender {
    [[DBAuthHelperOSX sharedHelper] authenticate];
}

#pragma mark - MASPreferencesViewController 

-(NSString *)identifier {
    return @"com.contentful.s3.settings";
}

-(NSView *)initialKeyView {
    return self.awsKeyTextField;
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameAdvanced];
}

-(NSString *)toolbarItemLabel {
    return NSLocalizedString(@"Upload", nil);
}

@end
