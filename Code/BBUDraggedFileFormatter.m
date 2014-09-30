//
//  BBUDraggedFileFormatter.m
//  image-uploader
//
//  Created by Boris Bügling on 29/09/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUDraggedFile.h"
#import "BBUDraggedFileFormatter.h"

@implementation BBUDraggedFileFormatter

-(NSString *)stringForObjectValue:(id)obj {
    if ([obj isKindOfClass:BBUDraggedFile.class]) {
        BBUDraggedFile* draggedFile = (BBUDraggedFile*)obj;
        return [NSString stringWithFormat:@"%@, %@, %@", draggedFile.fileType, [NSByteCountFormatter stringFromByteCount:draggedFile.numberOfBytes countStyle:NSByteCountFormatterCountStyleFile], [NSDateFormatter localizedStringFromDate:draggedFile.mtime dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle]];
    }

    if ([obj isKindOfClass:NSArray.class]) {
        NSUInteger totalNumberOfBytes = 0;
        for (BBUDraggedFile* draggedFile in obj) {
            totalNumberOfBytes += draggedFile.numberOfBytes;
        }

        return [NSString stringWithFormat:NSLocalizedString(@"%@ total size", nil), [NSByteCountFormatter stringFromByteCount:totalNumberOfBytes countStyle:NSByteCountFormatterCountStyleFile]];
    }

    return [super stringForObjectValue:obj];
}

@end
