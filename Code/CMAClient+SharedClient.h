//
//  CMAClient+SharedClient.h
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

extern NSString* const kContentfulServiceType;

@interface CMAClient (SharedClient)

+(instancetype)sharedClient;

-(CDARequest*)fetchSharedSpaceWithSuccess:(CMASpaceFetchedBlock)success
                                  failure:(CDARequestFailureBlock)failure;

@end
