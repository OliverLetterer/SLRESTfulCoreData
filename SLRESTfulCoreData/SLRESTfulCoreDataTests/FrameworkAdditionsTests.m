//
//  SLRESTfulCoreDataFrameworkAdditionsTests.m
//  SLRESTfulCoreData
//
//  The MIT License (MIT)
//  Copyright (c) 2013 Oliver Letterer, Sparrow-Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "FrameworkAdditionsTests.h"
#import "SLRESTfulCoreData.h"
#import "TTEntity1.h"

@implementation SLRESTfulCoreDataFrameworkAdditionsTests

- (void)setUp
{
    [super setUp];
    
}

- (void)tearDown
{
    [super tearDown];
    
}

// All code under test must be linked into the Unit Test bundle
- (void)testCamelizing
{
    NSString *string = @"this_is_a_test";
    NSString *expectedResult = @"thisIsATest";
    
    STAssertEqualObjects(string.stringByCamelizingString, expectedResult, @"camelizing not working.");
}

- (void)testUnderscoring
{
    NSString *string = @"thisIsATest";
    NSString *expectedResult = @"this_is_a_test";
    STAssertEqualObjects(string.stringByUnderscoringString, expectedResult, @"underscoring not working.");
    
    string = @"GHAPIV3Repository";
    expectedResult = @"ghapiv3_repository";
    STAssertEqualObjects(string.stringByUnderscoringString, expectedResult, @"underscoring not working.");
    
    string = @"OliverIdentifierLetterer";
    expectedResult = @"oliver_identifier_letterer";
    STAssertEqualObjects(string.stringByUnderscoringString, expectedResult, @"underscoring not working.");
    
    string = @"Oliver_id_Letterer";
    expectedResult = @"oliver_id_letterer";
    STAssertEqualObjects(string.stringByUnderscoringString, expectedResult, @"underscoring not working.");
}

@end
