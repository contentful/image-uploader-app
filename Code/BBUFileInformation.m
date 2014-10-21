//
//  BBUFileInformation.m
//  image-uploader
//
//  Created by Boris Bügling on 13/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUDraggedFile.h"
#import "BBUFileInformation.h"
#import "CMAClient+SharedClient.h"

@interface BBUFileInformation ()

@property (nonatomic) NSString* assetIdentifier;
@property (nonatomic) NSError* error;
@property (nonatomic) NSData* errorData;
@property (nonatomic) NSString* originalPath;
@property (nonatomic) CMASpace* space;
@property (nonatomic) NSString* spaceIdentifier;

@end

#pragma mark -

@implementation BBUFileInformation

+(instancetype)fileInformationWithDraggedFile:(BBUDraggedFile *)draggedFile {
    RLMRealm* realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];

    BBUFileInformation* info = [[BBUFileInformation alloc] initWithDraggedFile:draggedFile];

    [realm commitWriteTransaction];
    return info;
}

+(NSArray *)ignoredProperties {
    return @[@"error", @"space"];
}

+(NSString *)primaryKey {
    return @"originalPath";
}

#pragma mark -

-(BOOL)hasAsset {
    return self.assetIdentifier.length > 0 && self.spaceIdentifier.length > 0;
}

-(NSError *)error {
    return [NSKeyedUnarchiver unarchiveObjectWithData:self.errorData];
}

-(void)fetchAssetWithSuccess:(CMAAssetFetchedBlock)success failure:(CDARequestFailureBlock)failure {
    [[CMAClient sharedClient] fetchSpaceWithIdentifier:self.spaceIdentifier success:^(CDAResponse *response,
                                                                                      CMASpace *space) {
        self.space = space;
        [space fetchAssetWithIdentifier:self.assetIdentifier success:success failure:failure];
    } failure:failure];
}

-(instancetype)initWithDraggedFile:(BBUDraggedFile*)draggedFile {
    self = [super init];
    if (self) {
        self.assetIdentifier = draggedFile.asset.identifier ?: @"";
        self.error = draggedFile.error;
        self.originalPath = draggedFile.originalPath ?: @"";
        self.spaceIdentifier = draggedFile.space.identifier ?: @"";
    }
    return self;
}

-(void)setError:(NSError *)error {
    self.errorData = [NSKeyedArchiver archivedDataWithRootObject:error];
}

@end
