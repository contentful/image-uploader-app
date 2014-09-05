//
//  BBUDraggedFile.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "BBUDraggedFile.h"

@interface BBUDraggedFile ()

@property (nonatomic) NSError* error;
@property (nonatomic) NSDictionary* fileAttributes;
@property (nonatomic) NSImage* image;
@property (nonatomic) BOOL operationInProgress;
@property (nonatomic) NSString* originalFileName;

@end

#pragma mark -

@implementation BBUDraggedFile

-(void)deleteInternalWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.asset deleteWithSuccess:^{
        self.operationInProgress = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES);
        });
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;
        self.operationInProgress = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

-(void)deleteWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    self.operationInProgress = YES;

    if (self.asset.published) {
        [self.asset unpublishWithSuccess:^{
            [self deleteInternalWithCompletionHandler:completionHandler];
        } failure:^(CDAResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.error = error;
                self.operationInProgress = NO;

                completionHandler(NO);
            });
        }];
    } else {
        [self deleteInternalWithCompletionHandler:completionHandler];
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"BBUDraggedFile with name '%@', attributes %@",
            self.originalFileName, self.fileAttributes];
}

-(instancetype)initWithPasteboardItem:(NSPasteboardItem *)item {
    self = [super init];
    if (self) {
        NSString* urlString = [item stringForType:(NSString*)kUTTypeFileURL];
        NSURL* url = [NSURL URLWithString:urlString];

        self.fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                               error:nil];
        self.image = [[NSImage alloc] initWithContentsOfURL:url];
        self.originalFileName = url.path.lastPathComponent;
    }
    return self;
}

-(void)updateWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    self.operationInProgress = YES;

    [self.asset updateWithSuccess:^{
        if (self.asset.fields[@"file"]) {
            [self.asset publishWithSuccess:^{
                self.operationInProgress = NO;

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(YES);
                });
            } failure:^(CDAResponse *response, NSError *error) {
                self.error = error;
                self.operationInProgress = NO;

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO);
                });
            }];
        } else {
            self.operationInProgress = NO;

            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(YES);
            });
        }
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;
        self.operationInProgress = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

@end
