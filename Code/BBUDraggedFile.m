//
//  BBUDraggedFile.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "BBUAssetUploadOperation.h"
#import "BBUDraggedFile.h"
#import "BBUFileInformation.h"

@interface BBUDraggedFile ()

@property (nonatomic) CMAAsset* asset;
@property (nonatomic) NSDictionary* fileAttributes;
@property (nonatomic) NSImage* image;
@property (nonatomic) NSString* originalPath;
@property (nonatomic) CMASpace* space;

@end

#pragma mark -

@implementation BBUDraggedFile

+(void)fetchAllFilesFromPersistentStoreWithCompletionHandler:(BBUArrayResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    RLMArray* fileInfos = [BBUFileInformation allObjects];
    NSMutableArray* result = [@[] mutableCopy];
    [self fetchNextFileFromFileInfos:fileInfos
                             atIndex:0
                         resultArray:result
               withCompletionHandler:completionHandler];
}

+(void)fetchFilesForSpace:(CMASpace*)space fromPersistentStoreWithCompletionHandler:(BBUArrayResultBlock)completionHandler {
    NSParameterAssert(space);
    NSParameterAssert(completionHandler);

    RLMArray* fileInfos = [BBUFileInformation objectsWhere:[NSString stringWithFormat:@"spaceIdentifier == '%@'", space.identifier]];
    NSMutableArray* result = [@[] mutableCopy];
    [self fetchNextFileFromFileInfos:fileInfos
                             atIndex:0
                         resultArray:result
               withCompletionHandler:completionHandler];
}

+(void)fetchNextFileFromFileInfos:(RLMArray*)fileInfos
                          atIndex:(NSUInteger)index
                      resultArray:(NSMutableArray*)result
            withCompletionHandler:(BBUArrayResultBlock)completionHandler {
    if (index >= fileInfos.count) {
        completionHandler(result);
        return;
    }

    BBUFileInformation* currentFileInfo = fileInfos[index];
    BBUDraggedFile* draggedFile = [[BBUDraggedFile alloc]
                                   initWithURL:[NSURL fileURLWithPath:currentFileInfo.originalPath]];
    draggedFile.error = currentFileInfo.error;

    if (!currentFileInfo.hasAsset) {
        if (draggedFile.error) {
            [result addObject:draggedFile];
        }

        [self fetchNextFileFromFileInfos:fileInfos
                                 atIndex:index + 1
                             resultArray:result
                   withCompletionHandler:completionHandler];
        return;
    }

    [currentFileInfo fetchAssetWithSuccess:^(CDAResponse *response, CMAAsset *asset) {
        draggedFile.asset = asset;
        draggedFile.space = currentFileInfo.space;

        if (!draggedFile.image) {
            draggedFile.image = [[NSImage alloc] initWithContentsOfURL:asset.URL];

            if (!draggedFile.image) {
                return;
            }
        }

        [result addObject:draggedFile];

        [self fetchNextFileFromFileInfos:fileInfos
                                 atIndex:index + 1
                             resultArray:result
                   withCompletionHandler:completionHandler];
    } failure:^(CDAResponse *response, NSError *error) {
        [self fetchNextFileFromFileInfos:fileInfos
                                 atIndex:index + 1
                             resultArray:result
                   withCompletionHandler:completionHandler];
    }];
}

#pragma mark -

-(BBUAssetUploadOperation *)creationOperationForSpace:(CMASpace *)space {
    NSParameterAssert(space.defaultLocale);

    self.space = space;
    return [[BBUAssetUploadOperation alloc] initWithDraggedFile:self];
}

-(void)createWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);
    NSParameterAssert(self.space);

    self.progress = 0.0;

    [self.space createAssetWithTitle:@{ self.space.defaultLocale: self.title ?: @"" }
                    description:nil
                   fileToUpload:nil
                        success:^(CDAResponse *response, CMAAsset *asset) {
                            self.asset = asset;
                            self.progress = 0.2;

                            completionHandler(YES);
                        } failure:^(CDAResponse *response, NSError *error) {
                            if (error.code == 404) {
                                NSMutableDictionary* info = [error.userInfo mutableCopy];
                                info[NSLocalizedDescriptionKey] = NSLocalizedString(@"Asset creation not allowed.", nil);
                                error = [NSError errorWithDomain:error.domain
                                                            code:error.code
                                                        userInfo:info];
                            }

                            self.error = error;

                            completionHandler(NO);
                        }];
}

-(void)deleteInternalWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.asset deleteWithSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(YES);
        });
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

-(void)deleteWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    if (self.asset.published) {
        [self.asset unpublishWithSuccess:^{
            [self deleteInternalWithCompletionHandler:completionHandler];
        } failure:^(CDAResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.error = error;

                completionHandler(NO);
            });
        }];
    } else {
        [self deleteInternalWithCompletionHandler:completionHandler];
    }
}

-(NSString *)description {
    return [NSString stringWithFormat:@"BBUDraggedFile with name '%@', attributes %@",
            self.originalPath.lastPathComponent, self.fileAttributes];
}

-(void)fetchWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.space fetchAssetWithIdentifier:self.asset.identifier success:^(CDAResponse *response,
                                                                         CMAAsset *asset) {
        self.asset = asset;

        completionHandler(YES);
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        completionHandler(NO);
    }];
}

-(NSString *)fileType {
    return [self.originalPath.lastPathComponent.pathExtension uppercaseString];
}

-(CGFloat)height {
    return self.image.size.height;
}

-(instancetype)initWithPasteboardItem:(NSPasteboardItem *)item {
    NSString* urlString = [item stringForType:(NSString*)kUTTypeFileURL];
    NSURL* url = [NSURL URLWithString:urlString];

    return [self initWithURL:url];
}

-(instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        self.fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                               error:nil];
        self.image = [[NSImage alloc] initWithContentsOfURL:url];
        self.originalPath = url.path;
    }
    return self;
}

-(NSDate *)mtime {
    return self.fileAttributes[NSFileModificationDate];
}

-(NSUInteger)numberOfBytes {
    return [self.fileAttributes[NSFileSize] unsignedIntegerValue];
}

-(NSString *)title {
    return self.asset.title ?: [self.originalPath.lastPathComponent stringByDeletingPathExtension];
}

-(void)updateWithCompletionHandler:(BBUBoolResultBlock)completionHandler {
    NSParameterAssert(completionHandler);

    [self.asset updateWithSuccess:^{
        if (self.asset.fields[@"file"]) {
            [self.asset publishWithSuccess:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(YES);
                });
            } failure:^(CDAResponse *response, NSError *error) {
                self.error = error;

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(NO);
                });
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(YES);
            });
        }
    } failure:^(CDAResponse *response, NSError *error) {
        self.error = error;

        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(NO);
        });
    }];
}

-(NSURL *)url {
    if (!self.space.identifier || !self.asset.identifier) {
        return nil;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://app.contentful.com/spaces/%@/assets/%@", self.space.identifier, self.asset.identifier]];
}

-(CGFloat)width {
    return self.image.size.width;
}

-(void)writeToPersistentStore {
    BBUFileInformation* fileInformation = [BBUFileInformation fileInformationWithDraggedFile:self];
    BBUFileInformation* oldInformation = [BBUFileInformation objectsWhere:[NSString stringWithFormat:@"originalPath == '%@'", self.originalPath]].firstObject;

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    if (oldInformation) {
        [realm deleteObject:oldInformation];
    }

    [realm addObject:fileInformation];
    [realm commitWriteTransaction];
}

@end
