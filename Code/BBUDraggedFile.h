//
//  BBUDraggedFile.h
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BBUBoolResultBlock)(BOOL success);

@class CMAAsset;
@class CMASpace;

@interface BBUDraggedFile : NSObject

@property (nonatomic) CMAAsset* asset;
@property (nonatomic) CMASpace* space;

@property (nonatomic) NSError* error; // FIXME: should be read-only
@property (nonatomic, readonly) NSDictionary* fileAttributes;
@property (nonatomic, readonly) NSImage* image;
@property (nonatomic, readonly) BOOL operationInProgress;
@property (nonatomic, readonly) NSString* originalFileName;

-(void)deleteWithCompletionHandler:(BBUBoolResultBlock)completionHandler;
-(instancetype)initWithPasteboardItem:(NSPasteboardItem*)item;
-(void)updateWithCompletionHandler:(BBUBoolResultBlock)completionHandler;

@end
