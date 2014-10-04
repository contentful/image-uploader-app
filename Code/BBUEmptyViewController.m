//
//  BBUEmptyViewController.m
//  image-uploader
//
//  Created by Boris Bügling on 23/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUAppStyle.h"
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
    self.view.layer.backgroundColor = [BBUAppStyle defaultStyle].backgroundColor.CGColor;

    for (NSView *aSubview in self.view.subviews) {
        [aSubview unregisterDraggedTypes];
    }
}

- (IBAction)browseClicked:(NSButton *)sender {
    if (self.browseAction) {
        self.browseAction(sender);
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
