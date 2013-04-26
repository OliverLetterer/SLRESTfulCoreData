//
//  Entity1.m
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

#import "TTEntity1.h"
#import "SLRESTfulCoreData.h"
#import "SLRESTfulCoreDataSharedManagedObjectContext.h"

@implementation TTEntity1

@dynamic identifier;
@dynamic someDate;
@dynamic someNumber;
@dynamic someStrangeString;
@dynamic someString;
@dynamic unregisteredValue, printerIdentifier, keyPathValue;

+ (void)initialize
{
    [self unregisterAttributeName:@"unregisteredValue"];
    [self registerAttributeName:@"someStrangeString" forJSONObjectKeyPath:@"some_super_strange_string"];
    
    [self registerAttributeName:@"keyPathValue" forJSONObjectKeyPath:@"key_path_value.second_string_key"];
    
    [self registerObjcNamingConvention:@"oliverLetterer" forJSONNamingConvention:@"oli_lett"];
}

+ (NSManagedObjectContext *)mainThreadManagedObjectContext
{
    return [SLRESTfulCoreDataSharedManagedObjectContext sharedInstance].managedObjectContext;
}

+ (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    return [SLRESTfulCoreDataSharedManagedObjectContext sharedInstance].managedObjectContext;
}

@end
