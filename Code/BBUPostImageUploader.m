//
//  BBUPostImageUploader.m
//  image-uploader
//
//  Created by Boris Bügling on 03/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "BBUPostImageUploader.h"

@interface BBUPostImageUploader ()

@property (nonatomic) AFHTTPRequestOperationManager* manager;

@end

#pragma mark -

@implementation BBUPostImageUploader

+(instancetype)sharedUploader {
    static dispatch_once_t once;
    static BBUPostImageUploader *sharedUploader;
    dispatch_once(&once, ^ {
        sharedUploader = [BBUPostImageUploader new];
    });
    return sharedUploader;
}

#pragma mark -

-(id)init {
    self = [super init];
    if (self) {
        NSURL* url = [NSURL URLWithString:@"http://postimage.org"];
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];

        self.manager.responseSerializer = [AFHTTPResponseSerializer new];

        NSMutableSet* acceptableContentTypes = [self.manager.responseSerializer.acceptableContentTypes
                                                mutableCopy];
        [acceptableContentTypes addObject:@"text/html"];
        self.manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    }
    return self;
}

-(void)uploadFileWithData:(NSData *)data
        completionHandler:(BBUFileUploadHandler)handler
          progressHandler:(BBUProgressHandler)progressHandler {
    NSParameterAssert(data);
    NSParameterAssert(handler);

    NSString* URLString = [self.manager.baseURL.absoluteString stringByAppendingString:@"/index.php?um=computer"];

    NSError* error;
    NSURLRequest* request = [self.manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:URLString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:data
                                    name:@"upload"
                                fileName:@"file.jpg"
                                mimeType:@"image/jpeg"];
        [formData appendPartWithFormData:[@"no" dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"adult"];
    } error:&error];

    AFHTTPRequestOperation* operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString* response = [[NSString alloc] initWithData:responseObject
                                                   encoding:NSUTF8StringEncoding];
        response = [response componentsSeparatedByString:@"'"][51];
        response = [response componentsSeparatedByString:@"?"][0];

        NSURL* uploadUrl = [NSURL URLWithString:response];
        handler(uploadUrl, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(nil, error);
    }];

    if (progressHandler) {
        [operation setUploadProgressBlock:progressHandler];
    }

    [self.manager.operationQueue addOperation:operation];
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
