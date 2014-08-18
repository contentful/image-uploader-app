//
//  NSView+Geometry.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "NSView+Geometry.h"

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
