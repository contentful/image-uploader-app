//
//  BBUImageCell.h
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "JNWCollectionViewCell.h"

@class CMAAsset;

@interface BBUImageCell : JNWCollectionViewCell

@property (nonatomic) CMAAsset* asset;
@property (nonatomic) NSString* assetDescription;
@property (nonatomic) NSImage* image;
@property (nonatomic) NSString* title;

@end
