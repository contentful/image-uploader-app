//
//  BBUAssetUploadOperation.h
//  image-uploader
//
//  Created by Boris Bügling on 21/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BBUDraggedFile;

@interface BBUAssetUploadOperation : NSOperation

@property (nonatomic, readonly) NSError* error;

-(id)initWithDraggedFile:(BBUDraggedFile*)draggedFile;

@end
