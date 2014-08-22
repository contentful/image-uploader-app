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

@interface BBUAssetUploadOperation ()

@property (nonatomic) BOOL done;
@property (nonatomic) BBUDraggedFile* draggedFile;
@property (nonatomic) NSError* error;

@end

#pragma mark -

@implementation BBUAssetUploadOperation

- (void)changeOperationStatusWithDone:(BOOL)done error:(NSError*)error {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    self.done = done;
    self.error = error;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
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
    NSParameterAssert(self.draggedFile);
    NSParameterAssert(self.draggedFile.asset);

    [self changeOperationStatusWithDone:NO error:nil];

    [[BBUUploadsImUploader sharedUploader] uploadImage:self.draggedFile.image completionHandler:^(NSURL *uploadURL,
                                                                                                  NSError *error) {
        if (!uploadURL) {
            [self changeOperationStatusWithDone:YES error:error];
            return;
        }

        // TODO: Actual locale support
        NSDictionary* uploads = @{ @"en-US": uploadURL.absoluteString };

        [self.draggedFile.asset updateWithLocalizedUploads:uploads success:^{
            [self.draggedFile.asset processWithSuccess:^{
                // TODO: Do the actual publishing
                [self changeOperationStatusWithDone:YES error:nil];
            } failure:^(CDAResponse *response, NSError *error) {
                [self changeOperationStatusWithDone:YES error:error];
            }];
        } failure:^(CDAResponse *response, NSError *error) {
            [self changeOperationStatusWithDone:YES error:error];
        }];
    }];
}

@end
