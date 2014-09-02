//
//  BBUHelpView.m
//  image-uploader
//
//  Created by Boris Bügling on 02/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUHelpView.h"

@interface BBUHelpView ()

@property (nonatomic) NSTextField* helpLabel;

@end

#pragma mark -

@implementation BBUHelpView

-(NSString *)helpText {
    return self.helpLabel.stringValue;
}

-(instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithRed:60.0/255.0
                                                     green:60.0/255.0
                                                      blue:60.0/255.0
                                                     alpha:1.0].CGColor;

        self.helpLabel = [[NSTextField alloc] initWithFrame:CGRectMake(10.0, 0.0, frameRect.size.width - 20.0, 80.0)];
        self.helpLabel.alignment = NSCenterTextAlignment;
        self.helpLabel.bordered = NO;
        self.helpLabel.drawsBackground = NO;
        self.helpLabel.editable = NO;
        self.helpLabel.font = [NSFont systemFontOfSize:25.0];
        self.helpLabel.textColor = [NSColor whiteColor];
        [self addSubview:self.helpLabel];

        NSImageView* logo = [[NSImageView alloc] initWithFrame:CGRectMake(0.0, 100.0, frameRect.size.width, frameRect.size.height)];
        logo.image = [NSImage imageNamed:@"contentful_logo_big"];
        [self addSubview:logo];
    }
    return self;
}

-(void)setHelpText:(NSString *)helpText {
    self.helpLabel.stringValue = helpText;
}

@end
