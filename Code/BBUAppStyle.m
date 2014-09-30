//
//  BBUAppStyle.m
//  image-uploader
//
//  Created by Boris Bügling on 24/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"

@implementation BBUAppStyle

+(instancetype)defaultStyle {
    static dispatch_once_t once;
    static BBUAppStyle *defaultStyle;
    dispatch_once(&once, ^ {
        defaultStyle = [BBUAppStyle new];
    });
    return defaultStyle;
}

#pragma mark -

-(NSColor*)backgroundColor {
    return [NSColor colorWithRed:60.0/255.0
                           green:60.0/255.0
                            blue:60.0/255.0
                           alpha:1.0];
}

-(NSColor*)darkBackgroundColor {
    return [NSColor colorWithRed:37.0/255.0
                           green:39.0/255.0
                            blue:42.0/255.0
                           alpha:1.0];
}

-(NSColor*)informationColor {
    return [NSColor colorWithCalibratedRed:0.800 green:0.761 blue:0.463 alpha:1.000];
}

-(NSColor*)lightBackgroundColor {
    return [NSColor colorWithRed:83.0/255.0
                           green:90.0/255.0
                            blue:98.0/255.0
                           alpha:1.0];
}

-(NSColor*)primaryButtonColor {
    return [NSColor colorWithCalibratedRed:0.271 green:0.506 blue:0.847 alpha:1.000];
}

-(NSColor*)selectionColor {
    return [NSColor colorWithRed:77.0/255.0
                           green:81.0/255.0
                            blue:87.0/255.0
                           alpha:1.0];
}

-(NSFont*)subtitleFont {
    return [NSFont fontWithName:@"Lucida Grande" size:11.0];
}

-(NSColor*)textColor {
    return [NSColor colorWithRed:139.0/255.0
                           green:139.0/255.0
                            blue:139.0/255.0
                           alpha:1.0];
}

-(NSFont*)titleFont {
    return [NSFont fontWithName:@"Lucida Grande" size:13.0];
}

@end
