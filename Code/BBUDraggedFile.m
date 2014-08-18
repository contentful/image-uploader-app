//
//  BBUDraggedFile.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUDraggedFile.h"

@implementation BBUDraggedFile

-(NSString *)description {
    return [NSString stringWithFormat:@"BBUDraggedFile with name '%@', attributes %@",
            self.originalFileName, self.fileAttributes];
}

@end
