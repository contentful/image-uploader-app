//
//  BBUMenuCell.h
//  image-uploader
//
//  Created by Boris Bügling on 19/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "JNWCollectionViewCell.h"

@class BBUMenuCell;

typedef void(^BBUMenuEndEditing)(BBUMenuCell* menuCell);
typedef void(^BBUMenuTextChanged)(BBUMenuCell* menuCell, NSString* text);

@interface BBUMenuCell : JNWCollectionViewCell

@property (nonatomic, copy) BBUMenuEndEditing endEditingHandler;
@property (nonatomic, copy) BBUMenuTextChanged textChangedHandler;
@property (nonatomic) NSString* title;

@end
