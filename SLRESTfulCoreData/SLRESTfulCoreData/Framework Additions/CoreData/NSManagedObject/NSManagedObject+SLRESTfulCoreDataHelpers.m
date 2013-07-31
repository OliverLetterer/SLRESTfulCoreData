//
//  NSManagedObject+SLRESTfulCoreDataHelpers.m
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

#import "NSManagedObject+SLRESTfulCoreDataHelpers.h"
#import "NSManagedObject+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataSetup.h"

#import "SLRESTfulCoreDataObjectCache.h"

#import "SLAttributeMapping.h"
#import "SLObjectDescription.h"
#import "SLObjectConverter.h"



@implementation NSManagedObject (SLRESTfulCoreDataHelpers)

+ (NSArray *)registeredAttributeNames
{
    NSManagedObjectContext *context = [self mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self)
                                                         inManagedObjectContext:context];
    
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    
    NSArray *allAttributes = entityDescription.attributesByName.allKeys;
    NSMutableArray *registeredAttributes = [NSMutableArray arrayWithCapacity:allAttributes.count];
    
    [allAttributes enumerateObjectsUsingBlock:^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
        if ([attributeMapping isAttributeNameRegistered:attributeName]) {
            [registeredAttributes addObject:attributeName];
        }
    }];
    
    return registeredAttributes;
}

+ (instancetype)objectWithRemoteIdentifier:(id)identifier inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [[SLRESTfulCoreDataObjectCache sharedCacheForManagedObjectContext:context] objectOfClass:self withRemoteIdentifier:identifier];
}

@end
