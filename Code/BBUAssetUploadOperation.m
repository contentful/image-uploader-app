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

static const NSUInteger kNumberOfRetries = 30;
static const NSTimeInterval kProcessWait = 1.0;

@interface BBUAssetUploadOperation () <DBRestClientDelegate>

@property (nonatomic) DBRestClient* client;
@property (nonatomic) BOOL done;
@property (nonatomic) BBUDraggedFile* draggedFile;
@property (nonatomic) NSUInteger retries;
@property (nonatomic, readonly) NSURL* temporaryFilePath;
@property (nonatomic, readonly) dispatch_time_t time;

@end

#pragma mark -

@implementation BBUAssetUploadOperation

@synthesize temporaryFilePath = _temporaryFilePath;

#pragma mark -

- (void)changeOperationStatusToProcessingFailed {
    self.draggedFile.error = [NSError errorWithDomain:@"com.contentful.management" code:kProcessingFailedErrorCode userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Processing uploaded file failed, try again.", nil) }];
    [self changeOperationStatusWithDone:YES];
}

- (void)changeOperationStatusWithDone:(BOOL)done {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    self.done = done;
    self.draggedFile.progress = done ? 1.0 : self.draggedFile.progress;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

-(void)dealloc {
    self.client = nil;
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

-(NSUInteger)hash {
    return [self.draggedFile hash];
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

-(BOOL)isEqual:(id)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }

    return [self.draggedFile isEqual:((BBUAssetUploadOperation*)object).draggedFile];
}

-(BOOL)isExecuting {
    return !self.done;
}

-(BOOL)isFinished {
    return self.done;
}

-(BOOL)shouldConvert {
    return ![@[ @"JPG", @"JPEG", @"PNG", @"GIF", @"PDF" ] containsObject:self.draggedFile.fileType] && self.draggedFile.isImage;
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

-(NSURL*)temporaryFilePath {
    if (!_temporaryFilePath) {
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"_image.jpg"];
        _temporaryFilePath = [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                                     stringByAppendingPathComponent:fileName]];
    }

    return _temporaryFilePath;
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

        if (self.shouldConvert) {
            NSBitmapImageRep *imgRep = [[self.draggedFile.image representations] objectAtIndex:0];
            NSData *data = [imgRep representationUsingType:NSJPEGFileType properties:nil];
            [data writeToURL:self.temporaryFilePath atomically:YES];

            path = self.temporaryFilePath.path;
        }

        NSString* fileName = [[NSUUID UUID] UUIDString];
        fileName = [fileName stringByAppendingPathExtension:path.pathExtension];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.client uploadFile:fileName toPath:@"/" withParentRev:nil fromPath:path];
        });
        
        return;
    }

    BBUFileUploadHandler handler = ^(NSURL *uploadURL, NSError *error) {
        if (!uploadURL) {
            self.draggedFile.error = error;

            [self changeOperationStatusWithDone:YES];
            return;
        }

        [self performUploadToContentfulWithUploadURL:uploadURL];
    };

    if (self.shouldConvert) {
        [[BBUS3Uploader sharedUploader] uploadImage:self.draggedFile.image
                                  completionHandler:handler
                                    progressHandler:nil];
    } else {
        NSData* data = [NSData dataWithContentsOfFile:self.draggedFile.originalPath];
        [[BBUS3Uploader sharedUploader] uploadFileWithData:data
                                         completionHandler:handler
                                           progressHandler:nil];
    }
}

-(dispatch_time_t)time {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kProcessWait * NSEC_PER_SEC));
}

#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path {
    [[NSFileManager defaultManager] removeItemAtURL:self.temporaryFilePath error:nil];

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
