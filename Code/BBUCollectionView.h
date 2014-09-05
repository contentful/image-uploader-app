//
//  BBUCollectionView.h
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionViewFramework.h>

@class BBUCollectionView;

@protocol BBUCollectionViewDelegate <NSObject>

-(void)collectionView:(BBUCollectionView*)collectionView didDragFiles:(NSArray*)draggedFiles;

@end

#pragma mark -

@interface BBUCollectionView : JNWCollectionView <NSDraggingDestination>

@property (nonatomic, weak) id<BBUCollectionViewDelegate> draggingDelegate;
@property (nonatomic) BOOL draggingEnabled;

@end
