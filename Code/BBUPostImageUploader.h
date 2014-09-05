//
//  BBUPostImageUploader.h
//  image-uploader
//
//  Created by Boris Bügling on 03/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IAmUpload/BBUFileUpload.h>

@interface BBUPostImageUploader : NSObject <BBUFileUpload>

+(instancetype)sharedUploader;

@end
