//
//  BBUAppStyle.h
//  image-uploader
//
//  Created by Boris Bügling on 24/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBUAppStyle : NSObject

+(instancetype)defaultStyle;

@property (nonatomic, readonly) NSColor* backgroundColor;
@property (nonatomic, readonly) NSColor* darkBackgroundColor;
@property (nonatomic, readonly) NSColor* selectionColor;
@property (nonatomic, readonly) NSFont* subtitleFont;
@property (nonatomic, readonly) NSColor* textColor;
@property (nonatomic, readonly) NSFont* titleFont;

@end
