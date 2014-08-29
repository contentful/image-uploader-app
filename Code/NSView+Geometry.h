//
//  NSView+Geometry.h
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum RectAxis {
    RectAxisHorizontal,
    RectAxisVertical
} RectAxis;

NSRect fitRectIntoRectWithDimension(NSRect inner, NSRect outer, RectAxis dimension);

@interface NSView (Geometry)

@property (nonatomic) CGFloat x, y, width, height;

@end
