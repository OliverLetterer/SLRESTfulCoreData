//
//  SLAttributeMappingTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

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

- (void)testThatAttributeMappingHasRegisterAllAttributesByDefault
{
    expect([self.attributeMapping isAttributeNameRegistered:@"someValue"]).to.beTruthy();
}

- (void)testThatAttributeMappingUnregistersAttributes
{
    [self.attributeMapping unregisterAttributeName:@"someValue"];
    expect([self.attributeMapping isAttributeNameRegistered:@"someValue"]).to.beFalsy();
}

- (void)testThatAttributeMappingRegistersCustomMapping
{
    [self.attributeMapping registerAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
}

- (void)testThatAttributeMappingRegistersNamingConventionsWithSingleWords
{
    [self.attributeMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"identifier");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"id");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtBeginningWithMultipleWords
{
    [self.attributeMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"id_value"]).to.equal(@"identifierValue");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"identifierValue"]).to.equal(@"id_value");
}

- (void)testThatAttributeMappingRegistersNamingConventionsInTheMiddleWithMultipleWords
{
    [self.attributeMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_id_bar"]).to.equal(@"fooIdentifierBar");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooIdentifierBar"]).to.equal(@"foo_id_bar");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtTheEndWithMultipleWorks
{
    [self.attributeMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_bar_id"]).to.equal(@"fooBarIdentifier");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooBarIdentifier"]).to.equal(@"foo_bar_id");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWords
{
    [self.attributeMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_url_bar"]).to.equal(@"fooURLBar");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooURLBar"]).to.equal(@"foo_url_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWorks
{
    [self.attributeMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_bar_url"]).to.equal(@"fooBarURL");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooBarURL"]).to.equal(@"foo_bar_url");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.attributeMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_urll_bar"]).to.equal(@"fooUrllBar");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooURLLBar"]).to.equal(@"foo_urll_bar");
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_lurl_bar"]).to.equal(@"fooLurlBar");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooLURLBar"]).to.equal(@"foo_lurl_bar");
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_lurll_bar"]).to.equal(@"fooLurllBar");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooLURLLBar"]).to.equal(@"foo_lurll_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.attributeMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_bar_urll"]).to.equal(@"fooBarUrll");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooBarURLL"]).to.equal(@"foo_bar_urll");
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_bar_lurl"]).to.equal(@"fooBarLurl");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooBarLURL"]).to.equal(@"foo_bar_lurl");
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_bar_lurll"]).to.equal(@"fooBarLurll");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooBarLURLL"]).to.equal(@"foo_bar_lurll");
}

- (void)testThatAttributeMappingRegistersDefaultAttributeMappings
{
    [SLAttributeMapping registerDefaultAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someURL");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
    
    [SLAttributeMapping unregisterDefaultAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).will.equal(@"someUrl");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_url");
}

- (void)testThatInstanceAttributeMappingBindStrongerThanDefaultAttributeMappings
{
    [SLAttributeMapping registerDefaultAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
    [self.attributeMapping registerAttribute:@"someValue" forJSONObjectKeyPath:@"some_url"];
    [self.attributeMapping registerAttribute:@"someURL" forJSONObjectKeyPath:@"some_value"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_url"]).to.equal(@"someValue");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someURL"]).to.equal(@"some_value");
    
    [SLAttributeMapping unregisterDefaultAttribute:@"someURL" forJSONObjectKeyPath:@"some_url"];
}

- (void)testThatAttributeMappingRegistersDefaultNamingConventions
{
    [SLAttributeMapping registerDefaultObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_id"]).to.equal(@"someIdentifier");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someIdentifier"]).to.equal(@"some_id");
    
    [SLAttributeMapping unregisterDefaultObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"some_id"]).to.equal(@"someId");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"someIdentifier"]).to.equal(@"some_identifier");
}

- (void)testThatInstanceNamingConventionsBindStrongerThanDefaultAttributeMappings
{
    [SLAttributeMapping registerDefaultObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    [self.attributeMapping registerObjcNamingConvention:@"value" forJSONNamingConvention:@"id"];
    [self.attributeMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"value"];
    
    expect([self.attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"id"]).to.equal(@"value");
    expect([self.attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"identifier"]).to.equal(@"value");
    
    [SLAttributeMapping unregisterDefaultObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
}

@end
