//
//  SLObjectConverterTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity4 : NSManagedObject
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSArray *array;
@end

@implementation SLEntity4
@dynamic number, string, date, array;

@end

@interface SLEntity4Subclass : SLEntity4 @end
@implementation SLEntity4Subclass @end



@interface SLObjectConverterTests : SenTestCase

@property (nonatomic, strong) SLObjectConverter *objectConverter;

@end



@implementation SLObjectConverterTests

- (void)setUp
{
    self.objectConverter = [[SLObjectConverter alloc] initWithManagedObjectClassName:NSStringFromClass([SLEntity4 class])];
}

- (void)testThatObjectConverterTransformsValidStringValues
{
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@"stringValue" forManagedObjectAttribute:@"string"]).to.equal(@"stringValue");
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:@"stringValue" forManagedObjectAttribute:@"string"]).to.equal(@"stringValue");
}

- (void)testThatObjectConverterTransformsValidNumberValues
{
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@5 forManagedObjectAttribute:@"number"]).to.equal(@5);
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:@5 forManagedObjectAttribute:@"number"]).to.equal(@5);
}

- (void)testThatObjectConverterDoesntTransformsInvalidStringValues
{
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@5 forManagedObjectAttribute:@"string"]).to.beNil();
}

- (void)testThatObjectConverterDoesntTransformsInvalidNumberValues
{
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@"stringValue" forManagedObjectAttribute:@"number"]).to.beNil();
}

- (void)testThatObjectConverterTransformsValidDateValues
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    expect([[self.objectConverter managedObjectObjectFromJSONObjectObject:stringValue forManagedObjectAttribute:@"date"] timeIntervalSince1970]).to.equal([now timeIntervalSince1970]);
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:now forManagedObjectAttribute:@"date"]).to.equal(stringValue);
}

- (void)testThatObjectConverterDoesntTransformsInvalidDateValues
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *stringValue = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:stringValue];
    
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@5 forManagedObjectAttribute:@"date"]).to.beNil();
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:now forManagedObjectAttribute:@"date"]).to.equal(stringValue);
}

- (void)testThatObjectConverterRegistersValueTransformer
{
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@[] forManagedObjectAttribute:@"array"]).to.beNil();
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:@[] forManagedObjectAttribute:@"array"]).to.beNil();
    
    [self.objectConverter registerValueTransformer:[[SLIdentityValueTransformer alloc] initWithExpectedClass:[NSArray class]] forManagedObjectAttributeName:@"array"];
    
    expect([self.objectConverter managedObjectObjectFromJSONObjectObject:@[] forManagedObjectAttribute:@"array"]).to.equal(@[]);
    expect([self.objectConverter JSONObjectObjectFromManagedObjectObject:@[] forManagedObjectAttribute:@"array"]).to.equal(@[]);
}

- (void)testThatObjectConverterReturnsNilForNoMatchingRegisteredSubclass
{
    NSDictionary *testAttributes = @{
                                     @"string": @"useSubclass"
                                     };
    
    expect([self.objectConverter subclassForRawJSONDictionary:testAttributes]).to.beNil();
}

- (void)testThatObjectConverterReturnsCorrectRegisteredSubclass
{
    NSDictionary *testAttributes = @{
                                     @"string": @"useSubclass"
                                     };
    
    [self.objectConverter registerSubclass:[SLEntity4Subclass class] forManagedObjectAttributeName:@"string" withValue:@"useSubclass"];
    expect([self.objectConverter subclassForRawJSONDictionary:testAttributes]).to.equal([SLEntity4Subclass class]);
}

@end
