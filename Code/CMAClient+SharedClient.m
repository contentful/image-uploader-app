//
//  CMAClient+SharedClient.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <objc/runtime.h>

#import "CMAClient+SharedClient.h"

static const char* kSharedSpace         = "SharedSpace";
static NSString* const kSharedSpaceKey  = @"8d116e2ik5be";

@interface CMAClient ()

@property (nonatomic) CMASpace* sharedSpace;

@end

#pragma mark -

@implementation CMAClient (SharedClient)

+(instancetype)sharedClient {
    static dispatch_once_t once;
    static CMAClient *sharedClient;
    dispatch_once(&once, ^ {
        NSString* token = [[[NSProcessInfo processInfo] environment]
                           valueForKey:@"CONTENTFUL_MANAGEMENT_API_ACCESS_TOKEN"];

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

    return [self fetchSpaceWithIdentifier:kSharedSpaceKey
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

-(CMASpace *)sharedSpace {
    return objc_getAssociatedObject(self, kSharedSpace);
}

@end
