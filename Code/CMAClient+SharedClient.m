//
//  CMAClient+SharedClient.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <objc/runtime.h>
#import <SSKeychain/SSKeychain.h>

#import "CMAClient+SharedClient.h"

NSString* const kContentfulServiceType  = @"com.contentful";
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

        sharedClient = [[CMAClient alloc] initWithAccessToken:token];
    });
    return sharedClient;
}

#pragma mark -

-(CDARequest*)fetchSharedSpaceWithSuccess:(CMASpaceFetchedBlock)success
                                  failure:(CDARequestFailureBlock)failure {
    if (self.sharedSpace) {
        if (success) {
            success(nil, self.sharedSpace);
        }

        return nil;
    }

    NSParameterAssert(self.sharedSpaceKey);
    return [self fetchSpaceWithIdentifier:self.sharedSpaceKey
                                  success:^(CDAResponse *response, CMASpace *space) {
                                      self.sharedSpace = space;

                                      if (success) {
                                          success(response, space);
                                      }
                                  } failure:failure];
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
