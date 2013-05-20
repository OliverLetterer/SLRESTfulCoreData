//
//  SLRESTfulCoreDataSetupTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity1 : NSManagedObject @end
@implementation SLEntity1 @end

@interface SLEntity1Subclass : SLEntity1 @end
@implementation SLEntity1Subclass @end



@interface SLRESTfulCoreDataSetupTests : SenTestCase

@end



@implementation SLRESTfulCoreDataSetupTests

- (void)setUp
{
    
}

- (void)testThatEachNSManagedObjectSubclassReturnsItsOwnMappingModel
{
    expect([SLEntity1 attributeMapping]).toNot.beNil();
    expect([SLEntity1Subclass attributeMapping]).toNot.beNil();
    
    expect([SLEntity1 attributeMapping]).toNot.equal([SLEntity1Subclass attributeMapping]);
}

- (void)testThatSubclassesAttributesBindStrongerThanParentClassesAttributes
{
    [SLEntity1 registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [SLEntity1Subclass registerAttributeName:@"someValue" forJSONObjectKeyPath:@"some_url"];
    [SLEntity1Subclass registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_value"];
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someValue");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_value");
    
    [[SLEntity1 attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [[SLEntity1Subclass attributeMapping] removeAttribute:@"someValue" forJSONObjectKeyPath:@"some_url"];
    [[SLEntity1Subclass attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_value"];
}

- (void)testThatSubclassesNamingConventionsBindStrongerThanParentClassesAttributes
{
    [SLEntity1 registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [SLEntity1Subclass registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"wuff"];
    [SLEntity1Subclass registerObjcNamingConvention:@"wuff" forJSONNamingConvention:@"id"];
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"wuff");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"wuff");
    
    [[SLEntity1 attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [[SLEntity1Subclass attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"identifier"];
    [[SLEntity1Subclass attributeMapping] unregisterObjcNamingConvention:@"id" forJSONNamingConvention:@"id"];
}

- (void)testThatSubclassesInheritAttributeMappingFromParentClass
{
    [SLEntity1 registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [SLEntity1Subclass registerAttributeName:@"someURLValue" forJSONObjectKeyPath:@"some_url_value"];
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url_value"]).to.equal(@"someURLValue");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURLValue"]).to.equal(@"some_url_value");
    
    [[SLEntity1 attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [[SLEntity1Subclass attributeMapping] removeAttribute:@"someURLValue" forJSONObjectKeyPath:@"some_url_value"];
}

- (void)testThatSubclassesInveritNamingConventionsFromParentClass
{
    [SLEntity1 registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [SLEntity1Subclass registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"identifier");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"id");
    
    expect([[SLEntity1Subclass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([[SLEntity1Subclass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
    
    [[SLEntity1 attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [[SLEntity1Subclass attributeMapping] unregisterObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
}

@end
