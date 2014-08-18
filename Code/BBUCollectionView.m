//
//  BBUCollectionView.m
//  image-uploader
//
//  Created by Boris Bügling on 18/08/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "BBUCollectionView.h"
#import "BBUDraggedFile.h"

@implementation BBUCollectionView

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSMutableArray* draggedTypes = [[NSImage imagePasteboardTypes] mutableCopy];
        [draggedTypes addObjectsFromArray:[NSImage imageFileTypes]];
        [draggedTypes addObject:NSFilenamesPboardType];
        [self registerForDraggedTypes:draggedTypes];
    }
    return self;
}

#pragma mark - NSDraggingDestination

-(void)draggingEnded:(id<NSDraggingInfo>)sender {
    NSMutableArray* draggedImages = [@[] mutableCopy];

    [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
        forView:self
        classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
        searchOptions:nil
        usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
            NSPasteboardItem* item = draggingItem.item;
            NSString* urlString = [item stringForType:(NSString*)kUTTypeFileURL];
            NSURL* url = [NSURL URLWithString:urlString];

            BBUDraggedFile* file = [BBUDraggedFile new];
            file.fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path
                                                                                   error:nil];
            file.image = [[NSImage alloc] initWithContentsOfURL:url];
            file.originalFileName = url.path.lastPathComponent;
            [draggedImages addObject:file];
        }];

    if ([self.draggingDelegate respondsToSelector:@selector(collectionView:didDragFiles:)]) {
        [self.draggingDelegate collectionView:self didDragFiles:draggedImages];
    }
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]] &&
        [sender draggingSourceOperationMask] & NSDragOperationCopy) {
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    return [NSImage canInitWithPasteboard:[sender draggingPasteboard]];
}

@end
