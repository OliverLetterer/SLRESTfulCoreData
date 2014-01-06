//
//  SLRESTfulCoreDataQueryInterfaceTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 21.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@class SLEntity6;
static id backgroundQueue;



@interface SLEntity6Child : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) SLEntity6 *parent;
@end

@implementation SLEntity6Child
@dynamic identifier, parent;

+ (id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue
{
    return backgroundQueue;
}

+ (void)initialize
{
    [self registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [self registerCRUDBaseURL:[NSURL URLWithString:@"/path"]];
}

@end



@interface SLEntity6 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSSet *children;
@end

@interface SLEntity6 (CoreDataGeneratedAccessors)
- (void)childrenWithCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;
- (void)addChildrenObject:(SLEntity6Child *)object withCompletionHandler:(void(^)(SLEntity6Child *object, NSError *error))completionHandler;
- (void)deleteChildrenObject:(SLEntity6Child *)object withCompletionHandler:(void(^)(NSError *error))completionHandler;
@end

@implementation SLEntity6
@dynamic identifier, name, children;

+ (id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue
{
    return backgroundQueue;
}

+ (void)initialize
{
    [self registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [self registerCRUDBaseURL:[NSURL URLWithString:@"/path"]];
    [self registerCRUDBaseURL:[NSURL URLWithString:@"/:id/children"] forRelationship:@"children"];
}

@end



@interface SLRESTfulCoreDataQueryInterfaceTests : SenTestCase

@end



@implementation SLRESTfulCoreDataQueryInterfaceTests

- (void)setUp
{
    NSManagedObjectModel *model = [SLTestDataStore sharedInstance].managedObjectModel;
    
    for (NSEntityDescription *entity in model.entities) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity.name];
        
        NSError *error = nil;
        NSArray *objects = [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, @"");
        
        for (NSManagedObject *object in objects) {
            [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext deleteObject:object];
        }
    }
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
}

- (void)testThatQueryInterfaceFetchesSingleObject
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];

    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block SLEntity6 *fetchedEntity = nil;

    void(^getRequestImplementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];

        completionHandler(@{@"id": @5, @"name": @"oli"}, nil);
    };

    [[[backgroundQueue stub] andDo:getRequestImplementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [SLEntity6 fetchObjectFromURL:URL completionHandler:^(id fetchedObject, NSError *error) {
        fetchedEntity = fetchedObject;
    }];

    expect(fetchedEntity).willNot.beNil();

    expect(fetchedEntity.class).to.equal([SLEntity6 class]);
    expect(fetchedEntity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(fetchedEntity.identifier).to.equal(5);
    expect(fetchedEntity.name).to.equal(@"oli");
}

- (void)testThatQueryInterfaceFetchesSingleObjectWithJSONPrefix
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];

    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block SLEntity6 *fetchedEntity = nil;

    void(^getRequestImplementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];

        NSDictionary *result = @{ @"entity": @{@"id": @5, @"name": @"oli"} };

        NSString *key = nil;

        for (NSString *threadKey in [NSThread currentThread].threadDictionary) {
            if ([threadKey hasPrefix:NSStringFromClass([SLTestBackgroundQueue class])]) {
                key = threadKey;
                break;
            }
        }
        SLRESTfulCoreDataBackgroundQueueResponseObjectTransformer transformer = [NSThread currentThread].threadDictionary[key];
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];

        completionHandler(transformer(result), nil);
    };

    [[[backgroundQueue stub] andDo:getRequestImplementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [SLEntity6 registerJSONPrefix:@"entity"];
    [SLEntity6 registerPluralizedJSONPrefix:@"entities"];
    
    [SLEntity6 fetchObjectFromURL:URL completionHandler:^(id fetchedObject, NSError *error) {
        fetchedEntity = fetchedObject;
    }];

    [SLEntity6 registerJSONPrefix:nil];
    [SLEntity6 registerPluralizedJSONPrefix:nil];

    expect(fetchedEntity).willNot.beNil();

    expect(fetchedEntity.class).to.equal([SLEntity6 class]);
    expect(fetchedEntity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(fetchedEntity.identifier).to.equal(5);
    expect(fetchedEntity.name).to.equal(@"oli");
}

- (void)testThatQueryInterfaceFetchesMultipleObjectsWithAPIReturningADictionary
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block NSArray *fetchedEntities = nil;
    
    void(^getRequestImplementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        
        completionHandler(@{@"id": @5, @"name": @"oli"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:getRequestImplementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [SLEntity6 fetchObjectsFromURL:URL completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        fetchedEntities = fetchedObjects;
    }];
    
    expect(fetchedEntities).willNot.beNil();
    expect(fetchedEntities.count).to.equal(1);
    
    SLEntity6 *entity = fetchedEntities[0];
    
    expect(entity.class).to.equal([SLEntity6 class]);
    expect(entity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(entity.identifier).to.equal(5);
    expect(entity.name).to.equal(@"oli");
}

- (void)testThatQueryInterfaceFetchesMultipleObjectsWithAPIReturningAnArray
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];

    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block NSArray *fetchedEntities = nil;

    void(^getRequestImplementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];

        completionHandler(@[ @{@"id": @5, @"name": @"oli"} ], nil);
    };

    [[[backgroundQueue stub] andDo:getRequestImplementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [SLEntity6 fetchObjectsFromURL:URL completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        fetchedEntities = fetchedObjects;
    }];

    expect(fetchedEntities).willNot.beNil();
    expect(fetchedEntities.count).to.equal(1);

    SLEntity6 *entity = fetchedEntities[0];

    expect(entity.class).to.equal([SLEntity6 class]);
    expect(entity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(entity.identifier).to.equal(5);
    expect(entity.name).to.equal(@"oli");
}

- (void)testThatQueryInterfaceFetchesMultipleObjectsWithAPIReturningAnArrayWithJSONPrefix
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];

    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block NSArray *fetchedEntities = nil;

    void(^getRequestImplementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];

        NSDictionary *result = @{ @"entities": @[ @{@"id": @5, @"name": @"oli"} ] };
        NSString *key = nil;

        for (NSString *threadKey in [NSThread currentThread].threadDictionary) {
            if ([threadKey hasPrefix:NSStringFromClass([SLTestBackgroundQueue class])]) {
                key = threadKey;
                break;
            }
        }
        SLRESTfulCoreDataBackgroundQueueResponseObjectTransformer transformer = [NSThread currentThread].threadDictionary[key];
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];

        completionHandler(transformer(result), nil);
    };

    [[[backgroundQueue stub] andDo:getRequestImplementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [SLEntity6 registerJSONPrefix:@"entity"];
    [SLEntity6 registerPluralizedJSONPrefix:@"entities"];

    [SLEntity6 fetchObjectsFromURL:URL completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        fetchedEntities = fetchedObjects;
    }];

    [SLEntity6 registerJSONPrefix:nil];
    [SLEntity6 registerPluralizedJSONPrefix:nil];

    expect(fetchedEntities).willNot.beNil();
    expect(fetchedEntities.count).to.equal(1);

    SLEntity6 *entity = fetchedEntities[0];

    expect(entity.class).to.equal([SLEntity6 class]);
    expect(entity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(entity.identifier).to.equal(5);
    expect(entity.name).to.equal(@"oli");
}

- (void)testThatQueryInterfaceFetchesFetchesObjectsForRelationship
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    NSURL *URL = [NSURL URLWithString:@"/5/children"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        
        completionHandler(@[ @{ @"id": @7 } ], nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block NSArray *fetchedEntities = nil;
    
    [entity fetchObjectsForRelationship:@"children" fromURL:URL completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        fetchedEntities = fetchedObjects;
    }];
    
    expect(fetchedEntities).willNot.beNil();
    expect(fetchedEntities.count).to.equal(1);
    expect(entity.children.count).to.equal(1);
    
    SLEntity6Child *childEntity = fetchedEntities[0];
    
    expect(childEntity.class).to.equal([SLEntity6Child class]);
    expect(childEntity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(childEntity.identifier).to.equal(7);
    expect(childEntity.parent).to.equal(entity);
}

- (void)testThatQueryInterfaceFetchesPOSTsToURL
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block NSDictionary *postDictionary = nil;
    NSDictionary *expectedDictionary = @{ @"id": @5, @"name": @"oli" };
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&completionHandler atIndex:4];
        
        postDictionary = dictionary;
        completionHandler(@{@"id": @5, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] postJSONObject:OCMOCK_ANY toURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block SLEntity6 *newEntity = nil;
    
    [entity postToURL:URL completionHandler:^(id JSONObject, NSError *error) {
        newEntity = JSONObject;
    }];
    
    expect(newEntity).willNot.beNil();
    expect(newEntity == entity).to.beTruthy();
    expect(newEntity.name).to.equal(@"new_name");
    expect(postDictionary).to.equal(expectedDictionary);
}

- (void)testThatQueryInterfacePUTsToURL
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    NSURL *URL = [NSURL URLWithString:@"/path"];
    __block NSDictionary *putDictionary = nil;
    NSDictionary *expectedDictionary = @{ @"id": @5, @"name": @"oli" };
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&completionHandler atIndex:4];
        
        putDictionary = dictionary;
        completionHandler(@{@"id": @5, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] putJSONObject:OCMOCK_ANY toURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block SLEntity6 *newEntity = nil;
    
    [entity putToURL:URL completionHandler:^(id JSONObject, NSError *error) {
        newEntity = JSONObject;
    }];
    
    expect(newEntity).willNot.beNil();
    expect(newEntity == entity).to.beTruthy();
    expect(newEntity.name).to.equal(@"new_name");
    expect(putDictionary).to.equal(expectedDictionary);
}

- (void)testThatQueryInterfaceDELETEsToURL
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    NSURL *URL = [NSURL URLWithString:@"/path"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        void(^__unsafe_unretained completionHandler)(NSError *error);
        [invocation getArgument:&completionHandler atIndex:3];
        
        completionHandler(nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] deleteRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block BOOL completionHandlerCalled = NO;
    
    [entity deleteToURL:URL completionHandler:^(NSError *error) {
        completionHandlerCalled = YES;
    }];
    
    expect(completionHandlerCalled).will.beTruthy();
    expect(entity.isDeleted).to.beTruthy();
}

- (void)testUpdateWithCompletionHandler
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [[SLEntity6 objectDescription].CRUDBaseURL URLByAppendingPathComponent:@"/5"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&argumentURL atIndex:2];
        [invocation getArgument:&completionHandler atIndex:3];
        
        URL = argumentURL;
        completionHandler(@{@"id": @5, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block SLEntity6 *newEntity = nil;
    
    [entity updateWithCompletionHandler:^(id JSONObject, NSError *error) {
        newEntity = JSONObject;
    }];
    
    expect(newEntity).willNot.beNil();
    expect(newEntity == entity).to.beTruthy();
    expect(newEntity.name).to.equal(@"new_name");
    expect(URL).to.equal(expectedURL);
}

- (void)testCreateWithCompletionHandler
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [SLEntity6 objectDescription].CRUDBaseURL;
    
    __block NSDictionary *postDictionary = nil;
    NSDictionary *expectedDictionary = @{ @"id": @0, @"name": @"oli" };
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&argumentURL atIndex:3];
        [invocation getArgument:&completionHandler atIndex:4];
        
        postDictionary = dictionary;
        URL = argumentURL;
        completionHandler(@{@"id": @5, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] postJSONObject:OCMOCK_ANY toURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @0;
    entity.name = @"oli";
    
    __block SLEntity6 *newEntity = nil;
    
    [entity createWithCompletionHandler:^(id JSONObject, NSError *error) {
        newEntity = JSONObject;
    }];
    
    expect(newEntity).willNot.beNil();
    expect(newEntity == entity).to.beTruthy();
    expect(newEntity.name).to.equal(@"new_name");
    expect(newEntity.identifier).to.equal(5);
    expect(postDictionary).to.equal(expectedDictionary);
    expect(URL).to.equal(expectedURL);
}

- (void)testSaveWithCompletionHandler
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [[SLEntity6 objectDescription].CRUDBaseURL URLByAppendingPathComponent:@"/5"];
    
    __block NSDictionary *putDictionary = nil;
    NSDictionary *expectedDictionary = @{ @"id": @5, @"name": @"oli" };
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&argumentURL atIndex:3];
        [invocation getArgument:&completionHandler atIndex:4];
        
        putDictionary = dictionary;
        URL = argumentURL;
        completionHandler(@{@"id": @5, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] putJSONObject:OCMOCK_ANY toURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block SLEntity6 *newEntity = nil;
    
    [entity saveWithCompletionHandler:^(id JSONObject, NSError *error) {
        newEntity = JSONObject;
    }];
    
    expect(newEntity).willNot.beNil();
    expect(newEntity == entity).to.beTruthy();
    expect(newEntity.name).to.equal(@"new_name");
    expect(putDictionary).to.equal(expectedDictionary);
    expect(URL).to.equal(expectedURL);
}

- (void)testDeleteWithCompletionHandler
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [[SLEntity6 objectDescription].CRUDBaseURL URLByAppendingPathComponent:@"/5"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(NSError *error);
        
        [invocation getArgument:&argumentURL atIndex:2];
        [invocation getArgument:&completionHandler atIndex:3];
        
        URL = argumentURL;
        completionHandler(nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] deleteRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block BOOL completionHandlerCalled = NO;
    
    [entity deleteWithCompletionHandler:^(NSError *error) {
        completionHandlerCalled = YES;
    }];
    
    expect(completionHandlerCalled).will.beTruthy();
    expect(entity.isDeleted).to.beTruthy();
    expect(URL).to.equal(expectedURL);
}

- (void)testThatQueryInterfaceFetchesForRelationshipDynamicallyAtRuntime
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [NSURL URLWithString:@"/5/children"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&argumentURL atIndex:2];
        [invocation getArgument:&completionHandler atIndex:3];
        
        URL = argumentURL;
        completionHandler(@[ @{ @"id": @7 } ], nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] getRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    __block NSArray *fetchedEntities = nil;
    
    [entity childrenWithCompletionHandler:^(NSArray *fetchedObjects, NSError *error) {
        fetchedEntities = fetchedObjects;
    }];
    
    expect(fetchedEntities).willNot.beNil();
    expect(fetchedEntities.count).to.equal(1);
    expect(entity.children.count).to.equal(1);
    
    SLEntity6Child *childEntity = fetchedEntities[0];
    
    expect(childEntity.class).to.equal([SLEntity6Child class]);
    expect(childEntity.managedObjectContext).to.equal([SLTestDataStore sharedInstance].mainThreadManagedObjectContext);
    expect(childEntity.identifier).to.equal(7);
    expect(URL).to.equal(expectedURL);
    expect(childEntity.parent).to.equal(entity);
}

- (void)testThatQueryInterfaceIntroducesDynamicPOSTImplementationForRelationshipAtRuntime
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSDictionary *postDictionary = nil;
    NSDictionary *expectedDictionary = @{ @"id": @0 };
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [NSURL URLWithString:@"/5/children"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *dictionary = nil;
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(id JSONObject, NSError *error);
        
        [invocation getArgument:&dictionary atIndex:2];
        [invocation getArgument:&argumentURL atIndex:3];
        [invocation getArgument:&completionHandler atIndex:4];
        
        postDictionary = dictionary;
        URL = argumentURL;
        completionHandler(@{@"id": @7, @"name": @"new_name"}, nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] postJSONObject:OCMOCK_ANY toURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    SLEntity6Child *childEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6Child class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    childEntity.identifier = @0;
    
    __block SLEntity6Child *fetchedChildEntity = nil;
    
    [entity addChildrenObject:childEntity withCompletionHandler:^(SLEntity6Child *object, NSError *error) {
        fetchedChildEntity = object;
    }];
    
    expect(fetchedChildEntity).willNot.beNil();
    
    expect(entity.children.count).to.equal(1);
    expect(childEntity == fetchedChildEntity).to.beTruthy();
    expect(childEntity.identifier).to.equal(7);
    expect(childEntity.parent).to.equal(entity);
    expect(URL).to.equal(expectedURL);
    expect(postDictionary).to.equal(expectedDictionary);
}

- (void)testThatQueryInterfaceIntroducesDynamicDELETEImplementationForRelationshipAtRuntime
{
    backgroundQueue = [OCMockObject partialMockForObject:[SLTestBackgroundQueue new]];
    
    __block NSURL *URL = nil;
    NSURL *expectedURL = [NSURL URLWithString:@"/5/children/7"];
    
    void(^implementation)(NSInvocation *invocation) = ^(NSInvocation *invocation) {
        __unsafe_unretained NSURL *argumentURL = nil;
        void(^__unsafe_unretained completionHandler)(NSError *error);
        
        [invocation getArgument:&argumentURL atIndex:2];
        [invocation getArgument:&completionHandler atIndex:3];
        
        URL = argumentURL;
        completionHandler(nil);
    };
    
    [[[backgroundQueue stub] andDo:implementation] deleteRequestToURL:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @5;
    entity.name = @"oli";
    
    SLEntity6Child *childEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6Child class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    childEntity.identifier = @7;
    childEntity.parent = entity;
    
    __block BOOL completionHandlerCalled = NO;
    
    [entity deleteChildrenObject:childEntity withCompletionHandler:^(NSError *error) {
        completionHandlerCalled = YES;
    }];
    
    expect(completionHandlerCalled).will.beTruthy();
    
    expect(entity.children.count).to.equal(0);
    expect(childEntity.isDeleted).to.beTruthy();
    expect(URL).to.equal(expectedURL);
}

@end
