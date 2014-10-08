//
//  BBUNetworkRequestLogger.h
//  image-uploader
//
//  Created by Boris Bügling on 08/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBUNetworkRequestLogger : NSObject

+ (instancetype)sharedLogger;

- (void)startLogging;
- (void)stopLogging;

@end
