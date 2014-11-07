//
//  BBUS3Uploader+SharedSettings.h
//  image-uploader
//
//  Created by Boris Bügling on 10/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <IAmUpload/BBUS3Uploader.h>

extern NSString* const kS3Bucket;
extern NSString* const kS3Key;
extern NSString* const kS3Path;
extern NSString* const kS3Secret;

@interface BBUS3Uploader (SharedSettings)

+(NSString*)credentialString;
+(BOOL)hasValidCredentials;
+(instancetype)sharedUploader;
+(void)unlink;

@end
