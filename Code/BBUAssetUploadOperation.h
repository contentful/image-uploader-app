//
//  BBUAssetUploadOperation.h
//  image-uploader
//
//  Created by Boris Bügling on 21/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSUInteger kProcessingFailedErrorCode;

@class BBUDraggedFile;
@class BBUImageCell;

@interface BBUAssetUploadOperation : NSOperation

@property (nonatomic, weak) BBUImageCell* cell;
@property (nonatomic, readonly) NSError* error;

-(id)initWithDraggedFile:(BBUDraggedFile*)draggedFile;

@end
