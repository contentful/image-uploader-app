//
//  BBUGeometryHelper.h
//  image-uploader
//
//  Created by Boris Bügling on 28/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum RectAxis {
    RectAxisHorizontal,
    RectAxisVertical
} RectAxis;

NSRect fitRectIntoRectWithDimension(NSRect inner, NSRect outer, RectAxis dimension);
