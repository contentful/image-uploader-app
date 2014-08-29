//
//  BBUAssetUploadOperation.m
//  image-uploader
//
//  Created by Boris Bügling on 21/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>
#import <IAmUpload/BBUUploadsImUploader.h>

#import "BBUAssetUploadOperation.h"
#import "BBUDraggedFile.h"
#import "BBUImageCell.h"

const NSUInteger kProcessingFailedErrorCode = 0xFF;

static const NSUInteger kNumberOfRetries = 3;
static const NSTimeInterval kProcessWait = 5.0;

@interface BBUAssetUploadOperation ()

@property (nonatomic) BOOL done;
@property (nonatomic) BBUDraggedFile* draggedFile;
@property (nonatomic) NSError* error;
@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic) NSUInteger retries;
@property (nonatomic, readonly) CMASpace* space;
@property (nonatomic, readonly) dispatch_time_t time;

@end

#pragma mark -

@implementation BBUAssetUploadOperation

- (void)changeOperationStatusToProcessingFailed {
    NSError* error = [NSError errorWithDomain:@"com.contentful.management" code:kProcessingFailedErrorCode userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Processing uploaded image failed, try again.", nil) }];
    [self changeOperationStatusWithDone:YES error:error];
}

- (void)changeOperationStatusWithDone:(BOOL)done error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cell.editable = YES;
    });

    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    self.done = done;
    self.error = error;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

-(void)handleProcessing {
    dispatch_after(self.time, dispatch_get_main_queue(), ^{
        [self.space fetchAssetWithIdentifier:self.identifier
                                     success:^(CDAResponse *response, CMAAsset *asset) {
                                         if (asset.URL) {
                                             [self.draggedFile.asset publishWithSuccess:^{
                                                 [self changeOperationStatusWithDone:YES error:nil];
                                             } failure:^(CDAResponse *response, NSError *error) {
                                                 [self changeOperationStatusWithDone:YES error:error];
                                             }];

                                             return;
                                         }

                                         if (self.retries < kNumberOfRetries) {
                                             self.retries++;

                                             [self handleProcessing];
                                         } else {
                                             [self changeOperationStatusToProcessingFailed];
                                         }
                                     } failure:^(CDAResponse *response, NSError *error) {
                                         [self changeOperationStatusWithDone:YES error:error];
                                     }];
    });
}

-(NSString *)identifier {
    return self.draggedFile.asset.identifier;
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

-(CMASpace *)space {
    return self.draggedFile.space;
}

-(void)start {
    NSParameterAssert(self.draggedFile);
    NSParameterAssert(self.draggedFile.asset);
    NSParameterAssert(self.draggedFile.space.defaultLocale);

    [self changeOperationStatusWithDone:NO error:nil];
    self.retries = 0;

    [[BBUUploadsImUploader sharedUploader] uploadImage:self.draggedFile.image completionHandler:^(NSURL *uploadURL, NSError *error) {
        if (!uploadURL) {
            [self changeOperationStatusWithDone:YES error:error];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            self.cell.editable = NO;
        });

        NSDictionary* uploads = @{ self.draggedFile.space.defaultLocale: uploadURL.absoluteString };

        [self.draggedFile.asset updateWithLocalizedUploads:uploads success:^{
            [self.draggedFile.asset processWithSuccess:^{
                [self handleProcessing];
            } failure:^(CDAResponse *response, NSError *error) {
                [self changeOperationStatusWithDone:YES error:error];
            }];
        } failure:^(CDAResponse *response, NSError *error) {
            [self changeOperationStatusWithDone:YES error:error];
        }];
    } progressHandler:self.cell.progressHandler];
}

-(dispatch_time_t)time {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kProcessWait * NSEC_PER_SEC));
}

@end
