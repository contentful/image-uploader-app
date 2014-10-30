//
//  BBUS3SettingsSheet.m
//  image-uploader
//
//  Created by Boris Bügling on 30/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <SSKeychain/SSKeychain.h>

#import "BBUS3SettingsSheet.h"
#import "BBUS3Uploader+SharedSettings.h"

@interface BBUS3SettingsSheet ()

@property (weak) IBOutlet NSTextField *awsKeyTextField;
@property (weak) IBOutlet NSTextField *awsSecretTextField;
@property (weak) IBOutlet NSButton* linkS3Button;
@property (weak) IBOutlet NSTextField *s3BucketTextField;
@property (weak) IBOutlet NSTextField *uploadPathTextField;

@end

#pragma mark -

@implementation BBUS3SettingsSheet

-(BOOL)commitEditing {
    [SSKeychain setPassword:self.awsKeyTextField.stringValue forService:kS3Key account:kS3Key];
    [SSKeychain setPassword:self.awsSecretTextField.stringValue forService:kS3Secret account:kS3Secret];
    [SSKeychain setPassword:self.s3BucketTextField.stringValue forService:kS3Bucket account:kS3Bucket];
    [SSKeychain setPassword:self.uploadPathTextField.stringValue forService:kS3Path account:kS3Path];

    if (![BBUS3Uploader hasValidCredentials]) {
        return YES;
    }

    [[BBUS3Uploader sharedUploader] uploadImage:[NSImage imageNamed:@"close"]
                              completionHandler:^(NSURL *uploadURL, NSError *error) {
                                  if (!uploadURL) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          NSAlert* alert = [NSAlert alertWithError:error];
                                          [alert runModal];
                                      });
                                  }
                              } progressHandler:nil];

    return YES;
}

-(instancetype)init {
    return [self initWithWindowNibName:NSStringFromClass(self.class)];
}

-(void)windowDidLoad {
    [super awakeFromNib];

    self.awsKeyTextField.stringValue = [SSKeychain passwordForService:kS3Key account:kS3Key] ?: @"";
    self.awsSecretTextField.stringValue = [SSKeychain passwordForService:kS3Secret account:kS3Secret] ?: @"";
    self.s3BucketTextField.stringValue = [SSKeychain passwordForService:kS3Bucket account:kS3Bucket] ?: @"";
    self.uploadPathTextField.stringValue = [SSKeychain passwordForService:kS3Path account:kS3Path] ?: @"";
}

#pragma mark - Actions

-(IBAction)linkS3Clicked:(NSButton*)sender {
    [self commitEditing];

    [NSApp endSheet:self.window];
    [self.window orderOut:self];
}

@end
