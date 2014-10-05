//
//  BBUImageCell.h
//  image-uploader
//
//  Created by Boris Bügling on 14/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <IAmUpload/BBUFileUpload.h>
#import <JNWCollectionView/JNWCollectionViewCell.h>

@class BBUDraggedFile;
@class BBUImageCell;

typedef void(^BBUDeletionSuccessfulHandler)(BBUImageCell* imageCell);

@interface BBUImageCell : JNWCollectionViewCell

@property (nonatomic) NSString* assetDescription;
@property (nonatomic, copy) BBUDeletionSuccessfulHandler deletionHandler;
@property (nonatomic, weak) BBUDraggedFile* draggedFile;
@property (nonatomic, readonly) BOOL selectable;
@property (nonatomic) NSString* title;

-(void)deleteAsset;
-(void)updateAsset;

@end
