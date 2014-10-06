//
//  BBUAssetUploadOperation.m
//  image-uploader
//
//  Created by Boris Bügling on 21/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>
#import <Dropbox-OSX-SDK/DropboxOSX/DropboxOSX.h>
#import <IAmUpload/BBUUploadsImUploader.h>

#import "BBUAssetUploadOperation.h"
#import "BBUDraggedFile.h"
#import "BBUImageCell.h"
#import "BBUS3Uploader+SharedSettings.h"

const NSUInteger kProcessingFailedErrorCode = 0xFF;

static const NSUInteger kNumberOfRetries = 15;
static const NSTimeInterval kProcessWait = 1.0;

@interface BBUAssetUploadOperation () <DBRestClientDelegate>

@property (nonatomic) DBRestClient* client;
@property (nonatomic) BOOL done;
@property (nonatomic) BBUDraggedFile* draggedFile;
@property (nonatomic) NSUInteger retries;
@property (nonatomic, readonly) dispatch_time_t time;

@end

#pragma mark -

@implementation BBUAssetUploadOperation

- (void)changeOperationStatusToProcessingFailed {
    self.draggedFile.error = [NSError errorWithDomain:@"com.contentful.management" code:kProcessingFailedErrorCode userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Processing uploaded image failed, try again.", nil) }];
    [self changeOperationStatusWithDone:YES];
}

- (void)changeOperationStatusWithDone:(BOOL)done {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    self.client = nil;
    self.done = done;
    self.draggedFile.progress = done ? 1.0 : self.draggedFile.progress;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

-(void)handleProcessing {
    dispatch_after(self.time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.draggedFile fetchWithCompletionHandler:^(BOOL success) {
            if (!success) {
                [self changeOperationStatusWithDone:YES];
                return;
            }

            self.draggedFile.progress = 0.8;

            if (self.draggedFile.asset.URL) {
                [self.draggedFile.asset publishWithSuccess:^{
                    [self changeOperationStatusWithDone:YES];
                } failure:^(CDAResponse *response, NSError *error) {
                    self.draggedFile.error = error;
                    [self changeOperationStatusWithDone:YES];
                }];

                return;
            }

            if (self.retries < kNumberOfRetries) {
                self.retries++;

                [self handleProcessing];
            } else {
                [self changeOperationStatusToProcessingFailed];
            }
        }];
    });
}


-(void)performUploadToContentfulWithUploadURL:(NSURL*)uploadURL {
    self.draggedFile.progress = 0.4;

    NSDictionary* uploads = @{ self.draggedFile.asset.locale: uploadURL.absoluteString };

    [self.draggedFile.asset updateWithLocalizedUploads:uploads success:^{
        self.draggedFile.progress = 0.5;

        [self.draggedFile.asset processWithSuccess:^{
            self.draggedFile.progress = 0.6;

            [self handleProcessing];
        } failure:^(CDAResponse *response, NSError *error) {
            self.draggedFile.error = error;

            [self changeOperationStatusWithDone:YES];
        }];
    } failure:^(CDAResponse *response, NSError *error) {
        self.draggedFile.error = error;

        [self changeOperationStatusWithDone:YES];
    }];
}

-(id)initWithDraggedFile:(BBUDraggedFile *)draggedFile {
    self = [super init];
    if (self) {
        self.draggedFile = draggedFile;
    }
    return self;
}

-(BOOL)isConcurrent {
    return YES;
}

-(BOOL)isExecuting {
    return !self.done;
}

-(BOOL)isFinished {
    return self.done;
}

-(void)start {
    [self.draggedFile createWithCompletionHandler:^(BOOL success) {
        if (success) {
            [self uploadImage];
        } else {
            [self changeOperationStatusWithDone:YES];
        }
    }];
}

-(void)uploadImage {
    NSParameterAssert(self.draggedFile);
    NSParameterAssert(self.draggedFile.asset);

    [self changeOperationStatusWithDone:NO];
    self.retries = 0;

    if ([DBSession sharedSession].isLinked) {
        self.client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.client.delegate = self;

        NSString* path = self.draggedFile.originalPath;
        NSString* fileName = [[NSUUID UUID] UUIDString];
        fileName = [fileName stringByAppendingPathExtension:path.pathExtension];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.client uploadFile:fileName toPath:@"/" withParentRev:nil fromPath:path];
        });
        
        return;
    }

    [[BBUS3Uploader sharedUploader] uploadImage:self.draggedFile.image completionHandler:^(NSURL *uploadURL, NSError *error) {
        if (!uploadURL) {
            self.draggedFile.error = error;

            [self changeOperationStatusWithDone:YES];
            return;
        }

        [self performUploadToContentfulWithUploadURL:uploadURL];
    } progressHandler:nil];
}

-(dispatch_time_t)time {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kProcessWait * NSEC_PER_SEC));
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path {
    link = [link stringByReplacingOccurrencesOfString:@"dl=0" withString:@"dl=1"];
    [self performUploadToContentfulWithUploadURL:[NSURL URLWithString:link]];
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    self.draggedFile.error = error;

    [self changeOperationStatusWithDone:YES];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
    [client loadSharableLinkForFile:destPath shortUrl:NO];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    self.draggedFile.error = error;

    [self changeOperationStatusWithDone:YES];
}

@end
