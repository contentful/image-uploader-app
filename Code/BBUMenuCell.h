//
//  BBUMenuCell.h
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "JNWCollectionViewCell.h"

@class BBUMenuCell;

typedef void(^BBUTabKeyAction)(BBUMenuCell* currentCell);
typedef void(^BBUTextChangedAction)(BBUMenuCell* currentCell, NSString* newText);

@interface BBUMenuCell : JNWCollectionViewCell

@property (nonatomic, readonly) NSTextField* entryField;
@property (nonatomic, copy) BBUTabKeyAction tabKeyAction;
@property (nonatomic, copy) BBUTextChangedAction textChangedAction;
@property (nonatomic) NSString* title;

@end
