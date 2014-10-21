//
//  AssetInfoPersistenceTest.m
//  Uploader Tests
//
//  Created by Boris Bügling on 10/10/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ContentfulManagementAPI/ContentfulManagementAPI.h>
#import <OCMock/OCMock.h>
#import <Realm/Realm.h>
#import <XCTest/XCTest.h>

#import "AsyncTesting.h"
#import "BBUDraggedFile.h"

static NSString* const AssetIdentifier = @"5HWe4IkwEgQcy4ygM6CqYo";
static NSString* const SpaceIdentifier = @"fsnczri66h17";

@interface AssetInfoPersistenceTest : XCTestCase

@property (nonatomic, readonly) NSURL* temporaryURL;

@end

#pragma mark -

@implementation AssetInfoPersistenceTest

@synthesize temporaryURL = _temporaryURL;

#pragma mark -

-(id)assetMockWithIdentifier:(NSString*)identifier {
    id i = [CMAAsset new];

    [i setValue:@{ @"id": identifier } forKey:@"sys"];

    return i;
}

-(id)assetMock {
    return [self assetMockWithIdentifier:AssetIdentifier];
}

-(id)draggedFileMockWithAsset:(BOOL)hasAsset
                       broken:(BOOL)broken
                        error:(BOOL)hasError
                         path:(BOOL)hasOriginalPath {
    NSURL* imageURL = self.temporaryURL;
    id mock = OCMPartialMock([[BBUDraggedFile alloc] initWithURL:imageURL]);

    if (broken) {
        OCMStub([mock asset]).andReturn(hasAsset ? [self assetMockWithIdentifier:@"foo"] : nil);
    } else {
        OCMStub([mock asset]).andReturn(hasAsset ? [self assetMock] : nil);
    }

    OCMStub([mock space]).andReturn(hasAsset ? [self spaceMock] : nil);

    NSError* error = [NSError errorWithDomain:@"blah" code:404 userInfo:@{}];
    OCMStub([mock error]).andReturn(hasError ? error : nil);
    OCMStub([mock originalPath]).andReturn(hasOriginalPath ? imageURL.path : nil);

    return mock;
}

-(id)draggedFileMockWithAsset:(BOOL)hasAsset error:(BOOL)hasError path:(BOOL)hasOriginalPath {
    return [self draggedFileMockWithAsset:hasAsset broken:NO error:hasError path:hasOriginalPath];
}

-(id)spaceMock {
    id mock = OCMClassMock(CMASpace.class);

    OCMStub([mock identifier]).andReturn(SpaceIdentifier);

    return mock;
}

-(void)setUp {
    NSString* path = [[RLMRealm defaultRealmPath] stringByDeletingLastPathComponent];

    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil]) {
        [[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:file]
                                                   error:nil];
    }

    [RLMRealm useInMemoryDefaultRealm];

    [[NSFileManager defaultManager] copyItemAtURL:[[NSBundle mainBundle] URLForImageResource:@"Check"] toURL:self.temporaryURL error:nil];
}

-(NSURL*)temporaryURL {
    if (!_temporaryURL) {
        NSString *fileName = [NSString stringWithFormat:@"%@_%@",
                              [[NSProcessInfo processInfo] globallyUniqueString], @"image.tiff"];
        _temporaryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                                stringByAppendingPathComponent:fileName]];
    }

    return _temporaryURL;
}

-(void)testBasic {
    __block BBUDraggedFile* file = [self draggedFileMockWithAsset:YES error:NO path:YES];
    [file writeToPersistentStore];

    StartBlock();

    [BBUDraggedFile fetchAllFilesFromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        XCTAssertEqual(1, array.count, @"");
        file = array.firstObject;

        EndBlock();
    }];

    WaitUntilBlockCompletes();

    XCTAssertNotNil(file, @"");
    XCTAssertNotNil(file.image, @"");
}

-(void)testError {
    __block BBUDraggedFile* file = [self draggedFileMockWithAsset:NO error:YES path:YES];
    [file writeToPersistentStore];

    StartBlock();

    [BBUDraggedFile fetchAllFilesFromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        XCTAssertEqual(1, array.count, @"");
        file = array.firstObject;

        EndBlock();
    }];

    WaitUntilBlockCompletes();

    XCTAssertNotNil(file, @"");
    XCTAssertNil(file.asset, @"");
    XCTAssertNotNil(file.error, @"");
}

-(void)testNothing {
    BBUDraggedFile* file = [self draggedFileMockWithAsset:NO error:NO path:NO];
    [file writeToPersistentStore];

    StartBlock();

    [BBUDraggedFile fetchAllFilesFromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        XCTAssertEqual(0, array.count, @"");

        EndBlock();
    }];

    WaitUntilBlockCompletes();
}

-(void)testInvalidAsset {
    BBUDraggedFile* file = [self draggedFileMockWithAsset:YES broken:YES error:NO path:YES];
    [file writeToPersistentStore];

    StartBlock();

    [BBUDraggedFile fetchAllFilesFromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        XCTAssertEqual(0, array.count, @"");

        EndBlock();
    }];

    WaitUntilBlockCompletes();
}

-(void)testFileNotAvailableLocally {
    __block BBUDraggedFile* file = [self draggedFileMockWithAsset:YES error:NO path:YES];
    [file writeToPersistentStore];
    [[NSFileManager defaultManager] removeItemAtURL:self.temporaryURL error:nil];

    StartBlock();

    [BBUDraggedFile fetchAllFilesFromPersistentStoreWithCompletionHandler:^(NSArray *array) {
        XCTAssertEqual(1, array.count, @"");
        file = array.firstObject;

        EndBlock();
    }];

    WaitUntilBlockCompletes();

    XCTAssertNotNil(file, @"");
    XCTAssertNotNil(file.image, @"");
}

@end
