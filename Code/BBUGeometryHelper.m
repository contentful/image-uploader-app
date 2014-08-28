//
//  BBUGeometryHelper.m
//  image-uploader
//
//  Created by Boris Bügling on 28/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUGeometryHelper.h"

NSRect fitRectIntoRectWithDimension(NSRect inner, NSRect outer, RectAxis dimension) {
    NSRect result;
    float proportion;

    if (dimension == RectAxisHorizontal) {
        proportion = inner.size.height / inner.size.width;
        result.size.width = outer.size.width;
        result.size.height = result.size.width * proportion;
        result.origin = inner.origin;
    } else if (dimension == RectAxisVertical) {
        proportion = inner.size.width / inner.size.height;
        result.size.height = outer.size.height;
        result.size.width = result.size.height * proportion;
        result.origin = inner.origin;
    } else {
        result = NSZeroRect;
    }

    return (result);
}
