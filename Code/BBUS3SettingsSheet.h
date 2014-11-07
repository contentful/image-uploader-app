//
//  BBUS3SettingsSheet.h
//  image-uploader
//
//  Created by Boris Bügling on 30/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^BBUS3SettingsCompletionHandler)();

@interface BBUS3SettingsSheet : NSWindowController

@property (nonatomic, copy) BBUS3SettingsCompletionHandler completionHandler;

@end
