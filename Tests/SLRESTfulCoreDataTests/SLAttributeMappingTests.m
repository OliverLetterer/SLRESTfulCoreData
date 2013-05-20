//
//  SLAttributeMappingTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreData.h"

@interface SLAttributeMappingTests : SenTestCase

@property (nonatomic, strong) SLAttributeMapping *attributeMapping;

@end



@implementation SLAttributeMappingTests

- (void)setUp
{
    self.attributeMapping = [[SLAttributeMapping alloc] initWithManagedObjectClassName:NSStringFromClass([NSManagedObject class])];
}

- (void)testJSONToObjcAttributeConvertionWithSingleWord
{
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"attribute"]).to.equal(@"attribute");
}

- (void)testObjcToJSONAttributeConvertionWithSingleWord
{
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"attribute"]).to.equal(@"attribute");
}

- (void)testJSONToObjcAttributeConvertionWithMultipleWord
{
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"attribute_value"]).to.equal(@"attributeValue");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleWord
{
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"attributeValue"]).to.equal(@"attribute_value");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleUppercaseWord
{
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"attributeValueURL"]).to.equal(@"attribute_value_url");
}

@end
