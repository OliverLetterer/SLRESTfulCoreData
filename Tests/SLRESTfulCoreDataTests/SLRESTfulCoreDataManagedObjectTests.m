//
//  SLRESTfulCoreDataManagedObjectTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity5Child1 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@end

@implementation SLEntity5Child1
@dynamic identifier;

+ (void)initialize
{
    [self registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
}

@end



@interface SLEntity5 : NSManagedObject
@property (nonatomic, strong) NSNumber *floatNumber;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) SLEntity5Child1 *child;
@end

@implementation SLEntity5
@dynamic floatNumber, string, date, dictionary, identifier, child;

+ (void)initialize
{
    [self registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [self registerValueTransformer:[[SLIdentityValueTransformer alloc] initWithExpectedClass:[NSDictionary class]] forManagedObjectAttributeName:@"dictionary"];
}

@end

@interface SLEntity5Subclass : SLEntity5 @end
@implementation SLEntity5Subclass @end



@interface SLRESTfulCoreDataManagedObjectTests : SenTestCase

@end



@implementation SLRESTfulCoreDataManagedObjectTests

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

- (void)testThatUpdatedObjectWithRawJSONDictionaryCreatesNewInstancesIfNonAlreadyExist
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    NSDictionary *dictionary = @{
                                 @"id": @2,
                                 @"float_number": @1337,
                                 @"string": @"blubb",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    SLEntity5 *newEntity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary
                                                  inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(newEntity).toNot.beNil();
    expect(newEntity).toNot.equal(entity);
    
    expect(newEntity.identifier).to.equal(2);
    expect(newEntity.floatNumber).to.equal(@1337);
    expect(newEntity.string).to.equal(@"blubb");
    expect(newEntity.date.timeIntervalSince1970).to.equal(now.timeIntervalSince1970);
    expect(newEntity.dictionary).to.equal(dictionary[@"dictionary"]);
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryUpdatesAnExistingInstances
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @1;
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @1337,
                                 @"string": @"blubb",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    SLEntity5 *newEntity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary
                                                  inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();
    
    expect(newEntity.identifier).to.equal(1);
    expect(newEntity.floatNumber).to.equal(@1337);
    expect(newEntity.string).to.equal(@"blubb");
    expect(newEntity.date.timeIntervalSince1970).to.equal(now.timeIntervalSince1970);
    expect(newEntity.dictionary).to.equal(dictionary[@"dictionary"]);
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryDoesntTouchValuesWhichAreNotBeingUpdates
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @1;
    entity.string = @"maFooBar";
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @1337,
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    SLEntity5 *newEntity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary
                                                  inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();
    
    expect(newEntity.string).to.equal(@"maFooBar");
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryClearesValuesForNullUpdates
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @1;
    entity.string = @"maFooBar";
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @1337,
                                 @"string": [NSNull null],
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    SLEntity5 *newEntity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary
                                                  inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();
    
    expect(newEntity.string).to.beNil();
}

- (void)testThatManagedObjectDoesntUpdateWithoutIdentifier
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    NSDictionary *dictionary = @{
                                 @"float_number": @1337,
                                 @"string": [NSNull null],
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    SLEntity5 *newEntity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary
                                                  inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(newEntity).to.beNil();
}

- (void)testThatManagedObjectConvertsItselfIntoAnJSONObject
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    entity.identifier = @1;
    entity.string = @"maFooBar";
    entity.date = now;
    entity.floatNumber = @3.5f;
    entity.dictionary = @{ @"key": @"value" };
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    
    
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @3.5f,
                                 @"string": @"maFooBar",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };
    
    expect(entity.rawJSONDictionary).to.equal(dictionary);
}

- (void)testThatUpdatedObjectHasCorrectSubclass
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @13371337,
                                 @"string": @"maFooBar"
                                 };
    
    [[SLEntity5 objectConverter] registerSubclass:[SLEntity5Subclass class] forManagedObjectAttributeName:@"floatNumber" withValue:@13371337];
    SLEntity5 *entity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    expect(entity.class).to.equal([SLEntity5Subclass class]);
}

- (void)testThatManagedObjectUpdatesOneToOneRelationshipsWithJSONObjectIdentifier
{
    SLEntity5Child1 *child = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5Child1 class])
                                                           inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    child.identifier = @5;
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"child_id": @5
                                 };
    
    SLEntity5 *entity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    expect(entity.child).to.equal(child);
}

#warning implement
- (void)testThatManagedObjectUpdatesOneToOneRelationshipsWithDifferentUniqueJSONObjectIdentifier
{
    
}

- (void)testThatManagedObjectUpdatesOneToOneRelationshipsWithJSONObject
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"child": @{
                                         @"id": @4
                                         }
                                 };
    
    SLEntity5 *entity = [SLEntity5 updatedObjectWithRawJSONDictionary:dictionary inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    expect(entity.child.identifier).to.equal(4);
}

#warning implement
- (void)testThatManagedObjectUpdatesManyToOneRelationshipsWithJSONObject
{
    
}

#warning implement
- (void)testThatManagedObjectUpdatesManyToOneRelationshipsWithJSONObjectIdentifier
{
    
}

#warning implement
- (void)testThatManagedObjectUpdatesOneToManyRelationshipsWithJSONObject
{
    
}

#warning implement
- (void)testThatManagedObjectUpdatesOneToManyRelationshipsWithJSONObjectIdentifier
{
    
}

@end
