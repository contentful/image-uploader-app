//
//  NSButton+Contentful.h
//  image-uploader
//
//  Created by Boris Bügling on 04/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSButton (Contentful)

+(instancetype)primaryContentfulButton;

-(void)bbu_setPrimaryButtonTitle:(NSString*)title;

@end
