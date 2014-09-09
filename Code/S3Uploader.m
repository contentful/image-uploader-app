//
//  S3Uploader.m
//  image-uploader
//
//  Created by Boris Bügling on 03/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import <SSKeychain/SSKeychain.h>

#import "S3Uploader.h"

NSString* const kS3Bucket    = @"S3BucketKey";
NSString* const kS3Key       = @"S3KeyKey";
NSString* const kS3Path      = @"S3PathKey";
NSString* const kS3Secret    = @"S3SecretKey";

@interface S3Uploader ()

@property (nonatomic) NSURL* baseURL;

@property (nonatomic, copy) NSString* bucket;
@property (nonatomic, copy) NSString* key;
@property (nonatomic, copy) NSString* secret;

@end

#pragma mark -

@implementation S3Uploader

+(NSString *)computeHMACWithString:(NSString *)data secret:(NSString *)key {
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [HMAC base64EncodedStringWithOptions:0];
}

+(NSString*)rfc2822date {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    return [dateFormatter stringFromDate:[NSDate date]];
}

+(instancetype)sharedUploader {
    static dispatch_once_t once;
    static S3Uploader *sharedUploader;
    dispatch_once(&once, ^ {
        NSString* bucket = [SSKeychain passwordForService:kS3Bucket account:kS3Bucket];
        NSString* key = [SSKeychain passwordForService:kS3Key account:kS3Key];
        NSString* path = [SSKeychain passwordForService:kS3Path account:kS3Path];
        NSString* secret = [SSKeychain passwordForService:kS3Secret account:kS3Secret];

        sharedUploader = [[S3Uploader alloc] initWithBucket:bucket key:key secret:secret];

        if (path.length > 0) {
            sharedUploader.path = path;
        }
    });
    return sharedUploader;
}

#pragma mark -

-(instancetype)initWithBucket:(NSString*)bucket key:(NSString*)key secret:(NSString*)secret {
    self = [super init];
    if (self) {
        self.bucket = bucket;
        self.key = key;
        self.secret = secret;

        self.baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.s3.amazonaws.com",
                                             self.bucket]];
    }
    return self;
}

-(void)uploadFileWithData:(NSData *)data
        completionHandler:(BBUFileUploadHandler)handler
          progressHandler:(BBUProgressHandler)progressHandler {
    NSParameterAssert(data);
    NSParameterAssert(handler);

    NSString* contentType = @"image/jpeg";
    NSString* fileName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"jpg"];

    if (self.path) {
        fileName = [self.path stringByAppendingPathComponent:fileName];
    }

    NSURL* fileURL = [self.baseURL URLByAppendingPathComponent:fileName];
    NSString* resourceName = [NSString stringWithFormat:@"/%@/%@", self.bucket, fileName];
    NSString* dateString = [[self class] rfc2822date];
    NSString* stringToSign = [NSString stringWithFormat:@"PUT\n\n%@\n%@\nx-amz-acl:public-read\n%@",
                              contentType, dateString, resourceName];
    NSString* signature = [[self class] computeHMACWithString:stringToSign secret:self.secret];
    NSString* authorization = [NSString stringWithFormat:@"AWS %@:%@", self.key, signature];

    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{ @"Host": self.baseURL.host,
                                                    @"Date": dateString,
                                                    @"Content-Type": contentType,
                                                    @"x-amz-acl": @"public-read",
                                                    @"Authorization": authorization };
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:fileURL];
    request.HTTPMethod = @"PUT";

    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *r, NSError *error) {
        NSHTTPURLResponse* response = (NSHTTPURLResponse*)r;

        if (response.statusCode >= 200 && response.statusCode < 300) {
            handler(fileURL, nil);
            return;
        }

        if (error) {
            handler(nil, error);
        } else {
            handler(nil, [NSError errorWithDomain:@"com.amazon.s3" code:response.statusCode userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Expected HTTP status 200-299.", nil) }]);
        }
    }];

    [task resume];
}

#if TARGET_OS_IPHONE
-(void)uploadImage:(UIImage *)image
 completionHandler:(BBUFileUploadHandler)handler
   progressHandler:(BBUProgressHandler)progressHandler {
    NSData* data = UIImageJPEGRepresentation(image, 1.0);
#else
    -(void)uploadImage:(NSImage *)image
completionHandler:(BBUFileUploadHandler)handler
progressHandler:(BBUProgressHandler)progressHandler {
    NSData *data = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
    NSDictionary *imageProperties = @{ NSImageCompressionFactor: @(1.0) };
    data = [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
#endif
    [self uploadFileWithData:data completionHandler:handler progressHandler:progressHandler];
}

@end
