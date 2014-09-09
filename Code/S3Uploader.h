//
//  S3Uploader.h
//  image-uploader
//
//  Created by Boris Bügling on 03/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IAmUpload/BBUFileUpload.h>

extern NSString* const kS3Bucket;
extern NSString* const kS3Key;
extern NSString* const kS3Path;
extern NSString* const kS3Secret;

@interface S3Uploader : NSObject <BBUFileUpload>

@property (nonatomic, copy) NSString* path;

+(instancetype)sharedUploader;

-(instancetype)initWithBucket:(NSString*)bucket key:(NSString*)key secret:(NSString*)secret;

@end
