//
//  CMAClient+SharedClient.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <objc/runtime.h>
#import <SSKeychain/SSKeychain.h>

#import "BBUNetworkRequestLogger.h"
#import "CMAClient+SharedClient.h"

NSString* const kContentfulServiceType  = @"com.contentful";
NSString* const kContentfulSpaceChanged = @"ContentfulSpaceChangedKey";
static NSString* const kUserAgent       = @"Contentful Media Uploader/1.0";

static const char* kSharedSpace         = "SharedSpace";
static const char* kSharedSpaceKey      = "SharedSpaceKey";

@interface CMAClient ()

@property (nonatomic) CMASpace* sharedSpace;

@end

#pragma mark -

@implementation CMAClient (SharedClient)

+(instancetype)sharedClient {
    static dispatch_once_t once;
    static CMAClient *sharedClient;
    dispatch_once(&once, ^ {
        NSString* token = [SSKeychain passwordForService:kContentfulServiceType account:kContentfulServiceType];

        CDAConfiguration* configuration = [CDAConfiguration defaultConfiguration];
        configuration.userAgent = kUserAgent;

        sharedClient = [[CMAClient alloc] initWithAccessToken:token configuration:configuration];

#if 0
        [[BBUNetworkRequestLogger sharedLogger] startLogging];
#endif
    });
    return sharedClient;
}

#pragma mark -

-(CDARequest*)fetchSharedSpaceWithSuccess:(CMASpaceFetchedBlock)success
                                  failure:(CDARequestFailureBlock)failure {
    if ([self.sharedSpace.identifier isEqualToString:self.sharedSpaceKey]) {
        if (success) {
            success(nil, self.sharedSpace);
        }

        return nil;
    }

    NSParameterAssert(self.sharedSpaceKey);
    CDARequest* request = [self fetchSpaceWithIdentifier:self.sharedSpaceKey
                                                 success:^(CDAResponse *response, CMASpace *space) {
                                                     self.sharedSpace = space;

                                                     if (success) {
                                                         success(response, space);
                                                     }
                                                 } failure:failure];

    NSAssert([request.request.allHTTPHeaderFields[@"User-Agent"] hasPrefix:kUserAgent], @"");
    return request;
}

#pragma mark -

-(void)setSharedSpace:(CMASpace *)sharedSpace {
    objc_setAssociatedObject(self, kSharedSpace, sharedSpace, OBJC_ASSOCIATION_RETAIN);
}

-(void)setSharedSpaceKey:(NSString *)sharedSpaceKey {
    objc_setAssociatedObject(self, kSharedSpaceKey, sharedSpaceKey, OBJC_ASSOCIATION_RETAIN);
}

-(CMASpace *)sharedSpace {
    return objc_getAssociatedObject(self, kSharedSpace);
}

-(NSString *)sharedSpaceKey {
    return objc_getAssociatedObject(self, kSharedSpaceKey);
}

@end
