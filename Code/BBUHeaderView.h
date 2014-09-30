//
//  BBUHeaderView.h
//  image-uploader
//
//  Created by Boris Bügling on 25/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <JNWCollectionView/JNWCollectionView.h>

@interface BBUHeaderView : JNWCollectionViewReusableView

@property (nonatomic) NSColor* backgroundColor;
@property (nonatomic, readonly) NSButton* closeButton;
@property (nonatomic, readonly) NSTextField* subtitleLabel;
@property (nonatomic, readonly) NSTextField* titleLabel;

@end
