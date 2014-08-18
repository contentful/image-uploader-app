//
//  BBUDraggedFile.h
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBUDraggedFile : NSObject

@property (nonatomic) NSDictionary* fileAttributes;
@property (nonatomic) NSImage* image;
@property (nonatomic) NSString* originalFileName;

@end
