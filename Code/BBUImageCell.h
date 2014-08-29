//
//  BBUImageCell.h
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <IAmUpload/BBUFileUpload.h>
#import <JNWCollectionView/JNWCollectionViewCell.h>

@class CMAAsset;

@interface BBUImageCell : JNWCollectionViewCell

@property (nonatomic) NSString* assetDescription;
@property (nonatomic) BBUDraggedFile* draggedFile;
@property (nonatomic, getter = isEditable) BOOL editable;
@property (nonatomic) NSError* error;
@property (nonatomic) NSImage* image;
@property (nonatomic, readonly, copy) BBUProgressHandler progressHandler;
@property (nonatomic) BOOL showFailure;
@property (nonatomic) BOOL showSuccess;
@property (nonatomic) NSString* title;

@end
