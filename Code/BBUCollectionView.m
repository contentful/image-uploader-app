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
        self.draggingEnabled = YES;
    }
    return self;
}

#pragma mark - NSDraggingDestination

-(void)draggingEnded:(id<NSDraggingInfo>)sender {
    if (![self isValidDraggingInfo:sender]) {
        return;
    }

    NSMutableArray* draggedImages = [@[] mutableCopy];

    [sender enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationConcurrent
        forView:self
        classes:[NSArray arrayWithObject:[NSPasteboardItem class]]
        searchOptions:nil
        usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
            BBUDraggedFile* file = [[BBUDraggedFile alloc] initWithPasteboardItem:draggingItem.item];

            if (file.image) {
                [draggedImages addObject:file];
            }
        }];

    if ([self.draggingDelegate respondsToSelector:@selector(collectionView:didDragFiles:)]) {
        [self.draggingDelegate collectionView:self didDragFiles:draggedImages];
    }
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([self isValidDraggingInfo:sender] && [sender draggingSourceOperationMask] & NSDragOperationCopy) {
        return NSDragOperationCopy;
    }

    return NSDragOperationNone;
}

-(BOOL)isValidDraggingInfo:(id<NSDraggingInfo>)sender {
    NSPasteboard* pastboard = [sender draggingPasteboard];
    NSURL* url = [NSURL URLFromPasteboard:pastboard];

    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];

    return exists && !isDirectory;
}

-(void)mouseUp:(NSEvent *)theEvent {
    [super mouseUp:theEvent];

    NSPoint locationInView = NSMakePoint(theEvent.locationInWindow.x - self.frame.origin.x, self.window.frame.size.height - self.frame.origin.y - theEvent.locationInWindow.y);
    locationInView.y += self.documentVisibleRect.origin.y;

    for (JNWCollectionViewCell* cell in self.visibleCells) {
        if (NSPointInRect(locationInView, cell.frame)) {
            return;
        }
    }

    [self deselectAllItems];
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    return [self isValidDraggingInfo:sender];
}

-(void)setDraggingEnabled:(BOOL)draggingEnabled {
    _draggingEnabled = draggingEnabled;

    if (draggingEnabled) {
        NSMutableArray* draggedTypes = [[NSImage imagePasteboardTypes] mutableCopy];
        [draggedTypes addObjectsFromArray:[NSImage imageFileTypes]];
        [draggedTypes addObject:NSFilenamesPboardType];
        [self registerForDraggedTypes:draggedTypes];
    } else {
        [self unregisterDraggedTypes];
    }
}

@end
