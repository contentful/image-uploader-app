//
//  BBUMenuViewController.h
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JNWCollectionView/JNWCollectionView.h>

@interface BBUMenuViewController : NSViewController

@property (nonatomic, weak) IBOutlet JNWCollectionView* relatedCollectionView;

@end
