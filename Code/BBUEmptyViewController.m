//
//  BBUEmptyViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 23/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUEmptyViewController.h"
#import "CMAClient+SharedClient.h"

@interface BBUEmptyViewController ()

@property (weak) IBOutlet NSTextField *spaceLabel;

@end

#pragma mark -

@implementation BBUEmptyViewController

-(void)awakeFromNib {
    [super awakeFromNib];

    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithRed:60.0/255.0
                                                      green:60.0/255.0
                                                       blue:60.0/255.0
                                                      alpha:1.0].CGColor;

    for (NSView *aSubview in self.view.subviews) {
        [aSubview unregisterDraggedTypes];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kContentfulSpaceChanged object:nil];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spaceChanged:) name:kContentfulSpaceChanged object:nil];
    }
    return self;
}

-(void)spaceChanged:(NSNotification*)note {
    NSString* name = [note.userInfo[kContentfulSpaceChanged] name];
    self.spaceLabel.stringValue = [NSString stringWithFormat:@"to %@ space", name];
}

@end
