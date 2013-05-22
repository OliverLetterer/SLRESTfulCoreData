//
//  SLRESTfulCoreDataNSManagedObjectContextCategoryTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 22.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity2 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unregisteredAttribute;
@end



@interface SLRESTfulCoreDataNSManagedObjectContextCategoryTests : SenTestCase
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;
@end
@implementation SLRESTfulCoreDataNSManagedObjectContextCategoryTests

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
    
    self.mainContext = [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    self.backgroundContext = [SLTestDataStore sharedInstance].backgroundThreadManagedObjectContext;
}

- (void)testPerformBlockWithSingleObject
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class]) inManagedObjectContext:self.mainContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [self.mainContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    __block BOOL success = NO;
    
    [self.backgroundContext performBlock:^(SLEntity2 *object) {
        success = [object.identifier isEqual:@1];
    } withObject:entity];
    
    expect(success).will.beTruthy();
}

- (void)testPerformBlockWithSingleManagedObjectID
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class]) inManagedObjectContext:self.mainContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [self.mainContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    __block BOOL success = NO;
    
    [self.backgroundContext performBlock:^(SLEntity2 *object) {
        success = [object.identifier isEqual:@1];
    } withObject:entity.objectID];
    
    expect(success).will.beTruthy();
}

- (void)testPerformBlockWithSingleArrayOfObjects
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class]) inManagedObjectContext:self.mainContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [self.mainContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    __block BOOL success = NO;
    
    [self.backgroundContext performBlock:^(NSArray *objects) {
        success = objects.count == 1 && [[objects[0] identifier] isEqual:@1];
    } withObject:@[ entity ]];
    
    expect(success).will.beTruthy();
}

- (void)testPerformBlockWithNestedArrays
{
    SLEntity2 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity2 class]) inManagedObjectContext:self.mainContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [self.mainContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    __block BOOL success = NO;
    
    [self.backgroundContext performBlock:^(NSArray *objects) {
        SLEntity2 *entity1 = objects[0];
        SLEntity2 *entity2 = objects[1];
        SLEntity2 *entity3 = objects[2][0];
        
        success = [entity1.identifier isEqual:@1] && [entity2.identifier isEqual:@1] && [entity3.identifier isEqual:@1];
    } withObject:@[ entity, entity.objectID, @[ entity ] ]];
    
    expect(success).will.beTruthy();
}

@end
