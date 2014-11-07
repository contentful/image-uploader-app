//
//  BBUS3Uploader+SharedSettings.m
//  image-uploader
//
//  Created by Boris Bügling on 10/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <SSKeychain/SSKeychain.h>

#import "BBUS3Uploader+SharedSettings.h"

NSString* const kS3Bucket   = @"S3BucketKey";
NSString* const kS3Key      = @"S3KeyKey";
NSString* const kS3Path     = @"S3PathKey";
NSString* const kS3Secret   = @"S3SecretKey";

@implementation BBUS3Uploader (SharedSettings)

+(NSString*)credentialString {
    return [NSString stringWithFormat:@"Bucket: %@\nPath: %@", [SSKeychain passwordForService:kS3Bucket account:kS3Bucket], [SSKeychain passwordForService:kS3Path account:kS3Path]];
}

+(BOOL)hasValidCredentials {
    NSString* bucket = [SSKeychain passwordForService:kS3Bucket account:kS3Bucket];
    NSString* key = [SSKeychain passwordForService:kS3Key account:kS3Key];
    NSString* path = [SSKeychain passwordForService:kS3Path account:kS3Path];
    NSString* secret = [SSKeychain passwordForService:kS3Secret account:kS3Secret];
    return bucket && key && path && secret;
}

+(instancetype)sharedUploader {
    static dispatch_once_t once;
    static BBUS3Uploader *sharedUploader;
    dispatch_once(&once, ^ {
        NSString* bucket = [SSKeychain passwordForService:kS3Bucket account:kS3Bucket];
        NSString* key = [SSKeychain passwordForService:kS3Key account:kS3Key];
        NSString* path = [SSKeychain passwordForService:kS3Path account:kS3Path];
        NSString* secret = [SSKeychain passwordForService:kS3Secret account:kS3Secret];

        sharedUploader = [[BBUS3Uploader alloc] initWithBucket:bucket key:key secret:secret];

        if (path) {
            sharedUploader.path = path;
        }
    });
    return sharedUploader;
}

+(void)unlink {
    [SSKeychain setPassword:@"" forService:kS3Key account:kS3Key];
    [SSKeychain setPassword:@"" forService:kS3Secret account:kS3Secret];
    [SSKeychain setPassword:@"" forService:kS3Bucket account:kS3Bucket];
    [SSKeychain setPassword:@"" forService:kS3Path account:kS3Path];
}

@end
