//
//  NSButton+Contentful.m
//  image-uploader
//
//  Created by Boris Bügling on 04/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
#import "NSButton+Contentful.h"

@implementation NSButton (Contentful)

+(instancetype)primaryContentfulButton {
    NSButton* button = [[NSButton alloc] initWithFrame:NSMakeRect(0.0, 0.0, 100.0, 40.0)];
    button.alignment = NSLeftTextAlignment;
    button.bordered = NO;
    button.font = [BBUAppStyle defaultStyle].titleFont;
    [button.cell setBackgroundColor:[BBUAppStyle defaultStyle].primaryButtonColor];
    return button;
}

#pragma mark -

-(void)bbu_setPrimaryButtonTitle:(NSString*)title {
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                   attributes:nil];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:titleRange];
    [self setAttributedTitle:colorTitle];
}

@end
