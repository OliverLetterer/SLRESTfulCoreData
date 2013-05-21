//
//  SLRESTfulCoreDataNSStringCategoryTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 21.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLRESTfulCoreDataNSStringCategoryTests : SenTestCase

@end


@implementation SLRESTfulCoreDataNSStringCategoryTests

- (void)testThatStringCamelizes
{
    NSString *string = @"this_is_a_test";
    NSString *expectedResult = @"thisIsATest";
    
    expect(string.stringByCamelizingString).to.equal(expectedResult);
}

- (void)testThatStringUnderscores
{
    NSString *string = @"thisIsATest";
    NSString *expectedResult = @"this_is_a_test";
    
    expect(string.stringByUnderscoringString).to.equal(expectedResult);
}

- (void)testThatStringUnderscoresWithLowercaseIdentity
{
    NSString *string = @"Oliver_id_Letterer";
    NSString *expectedResult = @"oliver_id_letterer";
    
    expect(string.stringByUnderscoringString).to.equal(expectedResult);
}

- (void)testThatStringUnderscoresWithNumbers
{
    NSString *string = @"GHAPIV3Repository";
    NSString *expectedResult = @"ghapiv3_repository";
    
    expect(string.stringByUnderscoringString).to.equal(expectedResult);
}

- (void)testThatStringUnderscoresCapitalizedString
{
    NSString *string = @"OliverIdentifierLetterer";
    NSString *expectedResult = @"oliver_identifier_letterer";
    
    expect(string.stringByUnderscoringString).to.equal(expectedResult);
}

@end
