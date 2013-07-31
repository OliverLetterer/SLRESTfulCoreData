//
//  SLRESTfulCoreDataObjectCacheTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 31.07.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity2 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unregisteredAttribute;
@end



@interface SLRESTfulCoreDataObjectCacheTests : SenTestCase @end

@implementation SLRESTfulCoreDataObjectCacheTests

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

- (void)testThatCacheReturnsACachedObject
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:context];
    
    entity.identifier = @5;
    
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    SLRESTfulCoreDataObjectCache *cache = [[SLRESTfulCoreDataObjectCache alloc] initWithManagedObjectContext:context];
    
    SLEntity2 *cachedEntitiy1 = [cache objectOfClass:[SLEntity2 class] withRemoteIdentifier:@5];
    expect(cachedEntitiy1).to.equal(entity);
}

- (void)testThatSecondObjectCacheQueryACachedObjectFaster
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:context];
    
    entity.identifier = @5;
    
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    SLRESTfulCoreDataObjectCache *cache = [[SLRESTfulCoreDataObjectCache alloc] initWithManagedObjectContext:context];
    
    NSDate *start1 = [NSDate date];
    SLEntity2 *cachedEntitiy1 = [cache objectOfClass:[SLEntity2 class] withRemoteIdentifier:@5];
    NSTimeInterval time1 = [[NSDate date] timeIntervalSinceDate:start1];
    
    NSDate *start2 = [NSDate date];
    SLEntity2 *cachedEntitiy2 = [cache objectOfClass:[SLEntity2 class] withRemoteIdentifier:@5];
    NSTimeInterval time2 = [[NSDate date] timeIntervalSinceDate:start2];
    
    expect(cachedEntitiy1).to.equal(cachedEntitiy2);
    expect(time2).to.beLessThan(time1);
}

- (void)testThatObjectsGetRemoveFromCacheOnceDelegate
{
    NSManagedObjectContext *context = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class])
                                                      inManagedObjectContext:context];
    
    entity.identifier = @5;
    
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    SLRESTfulCoreDataObjectCache *cache = [[SLRESTfulCoreDataObjectCache alloc] initWithManagedObjectContext:context];
    NSString *cachedKey = @"SLEntity2#5";
    NSCache *internalCache = [cache valueForKey:@"internalCache"];
    
    SLEntity2 *cachedEntitiy1 = [cache objectOfClass:[SLEntity2 class] withRemoteIdentifier:@5];
    expect(cachedEntitiy1).to.equal(entity);
    
    expect([internalCache objectForKey:cachedKey]).toNot.beNil();
    
    [context deleteObject:entity];
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    expect([internalCache objectForKey:cachedKey]).to.beNil();
}

@end
