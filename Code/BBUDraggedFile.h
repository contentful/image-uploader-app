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

@property (nonatomic, readonly) CMAAsset* asset;
@property (nonatomic) NSError* error;
@property (nonatomic, readonly) NSImage* image;
@property (nonatomic, readonly) NSString* title;
@property (nonatomic, readonly) NSURL* url;

-(NSOperation*)creationOperationForSpace:(CMASpace*)space;
-(instancetype)initWithPasteboardItem:(NSPasteboardItem*)item;

-(void)createWithCompletionHandler:(BBUBoolResultBlock)completionHandler;
-(void)deleteWithCompletionHandler:(BBUBoolResultBlock)completionHandler;
-(void)fetchWithCompletionHandler:(BBUBoolResultBlock)completionHandler;
-(void)updateWithCompletionHandler:(BBUBoolResultBlock)completionHandler;

@end
