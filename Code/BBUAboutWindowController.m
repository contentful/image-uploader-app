//
//  BBUAboutWindowController.m
//  image-uploader
//
//  Created by Boris Bügling on 29/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAboutWindowController.h"
#import "BBUAppStyle.h"

@interface BBUAboutWindowController ()

@property (nonatomic) IBOutlet NSTextView* infoTextLabel;
@property (nonatomic) IBOutlet NSTextField* versionLabel;

@end

#pragma mark -

@implementation BBUAboutWindowController

- (void)awakeFromNib {
    [super awakeFromNib];

    NSView* contentView = self.window.contentView;
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor.CGColor;

    self.versionLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@", nil), [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]];

    NSString* path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
    NSData* rtfData = [NSData dataWithContentsOfFile:path];
    NSAttributedString* string = [[NSAttributedString alloc] initWithRTF:rtfData
                                                      documentAttributes:nil];

    [[self.infoTextLabel textStorage] setAttributedString:string];
}

-(instancetype)init {
    return [self initWithWindowNibName:NSStringFromClass([self class])];
}

@end
