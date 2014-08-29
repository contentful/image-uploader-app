//
//  NSView+Geometry.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "NSView+Geometry.h"

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

@implementation NSView (Geometry)

-(void)setX:(CGFloat)x {
    self.frame = NSMakeRect(x, self.y, self.width, self.height);
}

-(void)setY:(CGFloat)y {
    self.frame = NSMakeRect(self.x, y, self.width, self.height);
}

-(void)setWidth:(CGFloat)width {
    self.frame = NSMakeRect(self.x, self.y, width, self.height);
}

-(void)setHeight:(CGFloat)height {
    self.frame = NSMakeRect(self.x, self.y, self.width, height);
}

#pragma mark -

-(CGFloat)x {
    return self.frame.origin.x;
}

-(CGFloat)y {
    return self.frame.origin.y;
}

-(CGFloat)width {
    return self.frame.size.width;
}

-(CGFloat)height {
    return self.frame.size.height;
}

@end
