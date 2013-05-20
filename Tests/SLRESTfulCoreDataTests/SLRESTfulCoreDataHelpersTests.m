//
//  SLRESTfulCoreDataHelpersTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity2 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unregisteredAttribute;
@end

@implementation SLEntity2
@dynamic identifier, name, unregisteredAttribute;

+ (void)load
{
    [self unregisterAttributeName:@"unregisteredAttribute"];
    [self registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
}

@end



@interface SLEntity3 : NSManagedObject
@property (nonatomic, strong) NSString *someValue;
@end

@implementation SLEntity3
@dynamic someValue;

+ (void)load
{
    [self registerUniqueIdentifierOfJSONObjects:@"someValue"];
}

@end



@interface SLRESTfulCoreDataHelpersTests : SenTestCase

@end



@implementation SLRESTfulCoreDataHelpersTests

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

- (void)testThatRegisteredAttributeNamesOnlyReturnsRegisteredAttriutes
{
    NSArray *registeredAttributeNames = @[ @"identifier", @"name" ];
    expect([SLEntity2 registeredAttributeNames]).to.equal(registeredAttributeNames);
}

- (void)testThatObjectWithRemoteIdentifierDoesntReturnNonExistingObject
{
    SLEntity2 *fetchedEntity = [SLEntity2 objectWithRemoteIdentifier:@5 inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(fetchedEntity).to.beNil();
}

- (void)testThatObjectWithRemoteIdentifierReturnsCorrectObject
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    entity.identifier = @5;
    
    SLEntity2 *entity2 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    entity2.identifier = @6;
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    
    
    SLEntity2 *fetchedEntity = [SLEntity2 objectWithRemoteIdentifier:@5 inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(fetchedEntity).toNot.beNil();
    expect(fetchedEntity).to.equal(entity);
    expect(fetchedEntity == entity).to.beTruthy();
}

- (void)testThatObjectWithRemoteIdentifierReturnsObjectFromMainThreadContext
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:context];
    
    entity.identifier = @5;
    
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    
    
    SLEntity2 *fetchedEntity = [SLEntity2 objectWithRemoteIdentifier:@5 inManagedObjectContext:context];
    expect(fetchedEntity.managedObjectContext).to.equal(context);
}

- (void)testThatObjectWithRemoteIdentifierReturnsObjectFromBackgroundThreadContext
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].backgroundThreadManagedObjectContext;
    
    [context performBlockAndWait:^{
        SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                          inManagedObjectContext:context];
        
        entity.identifier = @5;
        
        NSError *saveError = nil;
        [context save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
        
        SLEntity2 *fetchedEntity = [SLEntity2 objectWithRemoteIdentifier:@5 inManagedObjectContext:context];
        expect(fetchedEntity.managedObjectContext).to.equal(context);
    }];
}

- (void)testThatObjectWithRemoteIdentifierWorksWithCustomUniqueKey
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    SLEntity3 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity3 class])
                                                      inManagedObjectContext:context];
    
    entity.someValue = @"Hallo";
    
    SLEntity3 *entity2 = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity3 class])
                                                       inManagedObjectContext:context];
    
    entity2.someValue = @"Hallo2";
    
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    
    
    SLEntity3 *fetchedEntity = [SLEntity3 objectWithRemoteIdentifier:@"Hallo" inManagedObjectContext:context];
    expect(fetchedEntity.managedObjectContext).to.equal(context);
}

@end
