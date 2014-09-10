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

@interface BBUAssetUploadOperation : NSOperation

-(id)initWithDraggedFile:(BBUDraggedFile*)draggedFile;

@end
