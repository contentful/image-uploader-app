//
//  BBUNetworkRequestLogger.m
//  image-uploader
//
//  Created by Boris Bügling on 08/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <FormatterKit/TTTURLRequestFormatter.h>

#import "BBUNetworkRequestLogger.h"

static NSURLRequest * AFNetworkRequestFromNotification(NSNotification *notification) {
    NSURLRequest *request = nil;
    if ([[notification object] isKindOfClass:[AFURLConnectionOperation class]]) {
        request = [(AFURLConnectionOperation *)[notification object] request];
    } else if ([[notification object] respondsToSelector:@selector(originalRequest)]) {
        request = [[notification object] originalRequest];
    }

    return request;
}

#pragma mark -

@implementation BBUNetworkRequestLogger

+ (instancetype)sharedLogger {
    static BBUNetworkRequestLogger *_sharedLogger = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] init];
    });

    return _sharedLogger;
}

#pragma mark -

- (void)dealloc {
    [self stopLogging];
}

- (void)networkRequestDidStart:(NSNotification *)notification {
    NSURLRequest *request = AFNetworkRequestFromNotification(notification);
    NSLog(@"%@", [TTTURLRequestFormatter cURLCommandFromURLRequest:request]);
}

- (void)startLogging {
    [self stopLogging];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestDidStart:) name:AFNetworkingOperationDidStartNotification object:nil];
}

- (void)stopLogging {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
