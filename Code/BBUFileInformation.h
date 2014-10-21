//
//  BBUFileInformation.h
//  image-uploader
//
//  Created by Boris Bügling on 13/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/CMAClient.h>
#import <Realm/Realm.h>

@class BBUDraggedFile;

@interface BBUFileInformation : RLMObject

@property (nonatomic, readonly) NSError* error;
@property (nonatomic, readonly) BOOL hasAsset;
@property (nonatomic, readonly) NSString* originalPath;
@property (nonatomic, readonly) CMASpace* space;

+(instancetype)fileInformationWithDraggedFile:(BBUDraggedFile*)draggedFile;

-(void)fetchAssetWithSuccess:(CMAAssetFetchedBlock)success failure:(CDARequestFailureBlock)failure;

@end
