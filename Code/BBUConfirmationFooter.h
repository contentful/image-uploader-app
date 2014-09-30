//
//  BBUConfirmationFooter.h
//  image-uploader
//
//  Created by Boris Bügling on 29/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "JNWCollectionViewReusableView.h"

@interface BBUConfirmationFooter : JNWCollectionViewReusableView

@property (nonatomic, readonly) NSButton* confirmationButton;
@property (nonatomic, readonly) NSTextField* informationLabel;
@property (nonatomic) BOOL showInformationLabel;

@end
