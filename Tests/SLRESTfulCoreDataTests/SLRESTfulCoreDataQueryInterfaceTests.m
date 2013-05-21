//
//  SLRESTfulCoreDataQueryInterfaceTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 21.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

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
    
}

- (void)testThatQueryInterfaceFetchesMultipleObjects
{
    
}

- (void)testThatQueryInterfaceFetchesFetchesObjectsForRelationship
{
    
}

- (void)testThatQueryInterfaceFetchesPOSTsToURL
{
    
}

- (void)testThatQueryInterfacePUTsToURL
{
    
}

- (void)testThatQueryInterfaceDELETEsToURL
{
    
}

- (void)testUpdateWithCompletionHandler
{
    
}

- (void)testCreateWithCompletionHandler
{
    
}

- (void)testSaveWithCompletionHandler
{
    
}

- (void)testDeleteWithCompletionHandler
{
    
}

- (void)testThatQueryInterfaceFetchesForRelationshipDynamicallyAtRuntime
{
    
}

@end
