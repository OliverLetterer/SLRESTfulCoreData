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

@interface SLSubclassOfEntity1 : SLEntity1 @end
@implementation SLSubclassOfEntity1 @end



@interface SLRESTfulCoreDataSetupTests : SenInterfaceTestCase

@end



@implementation SLRESTfulCoreDataSetupTests

- (void)testThatEachNSManagedObjectSubclassReturnsItsOwnMappingModel
{
    expect([SLEntity1 attributeMapping]).toNot.beNil();
    expect([SLSubclassOfEntity1 attributeMapping]).toNot.beNil();
    
    expect([SLEntity1 attributeMapping]).toNot.equal([SLSubclassOfEntity1 attributeMapping]);
}

- (void)testThatSubclassesAttributesBindStrongerThanParentClassesAttributes
{
    [SLEntity1 registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [SLSubclassOfEntity1 registerAttributeName:@"someValue" forJSONObjectKeyPath:@"some_url"];
    [SLSubclassOfEntity1 registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_value"];
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someValue");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_value");
    
    [[SLEntity1 attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [[SLSubclassOfEntity1 attributeMapping] removeAttribute:@"someValue" forJSONObjectKeyPath:@"some_url"];
    [[SLSubclassOfEntity1 attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_value"];
}

- (void)testThatSubclassesNamingConventionsBindStrongerThanParentClassesAttributes
{
    [SLEntity1 registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [SLSubclassOfEntity1 registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"wuff"];
    [SLSubclassOfEntity1 registerObjcNamingConvention:@"wuff" forJSONNamingConvention:@"id"];
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"wuff");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"wuff");
    
    [[SLEntity1 attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [[SLSubclassOfEntity1 attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"identifier"];
    [[SLSubclassOfEntity1 attributeMapping] unregisterObjcNamingConvention:@"id" forJSONNamingConvention:@"id"];
}

- (void)testThatSubclassesInheritAttributeMappingFromParentClass
{
    [SLEntity1 registerAttributeName:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [SLSubclassOfEntity1 registerAttributeName:@"someURLValue" forJSONObjectKeyPath:@"some_url_value"];
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url_value"]).to.equal(@"someURLValue");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURLValue"]).to.equal(@"some_url_value");
    
    [[SLEntity1 attributeMapping] removeAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [[SLSubclassOfEntity1 attributeMapping] removeAttribute:@"someURLValue" forJSONObjectKeyPath:@"some_url_value"];
}

- (void)testThatSubclassesInveritNamingConventionsFromParentClass
{
    [SLEntity1 registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [SLSubclassOfEntity1 registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"identifier");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"id");
    
    expect([[SLSubclassOfEntity1 attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([[SLSubclassOfEntity1 attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
    
    [[SLEntity1 attributeMapping] unregisterObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [[SLSubclassOfEntity1 attributeMapping] unregisterObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
}

@end
