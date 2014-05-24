//
//  NSManagedObjectContext+SLRESTfulCoreData.m
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

#import "NSManagedObjectContext+SLRESTfulCoreData.h"
#import "SLRESTfulCoreData.h"

static id managedObjectIDCollector(id object)
{
    if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
        
        for (id managedObject in array) {
            [newArray addObject:managedObjectIDCollector(managedObject)];
        }
        
        return newArray;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = object;
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
        
        for (id key in dictionary) {
            newDictionary[key] = managedObjectIDCollector(dictionary[key]);
        }
        
        return newDictionary;
    } else if ([object isKindOfClass:[NSManagedObject class]]) {
        return [object objectID];
    } else if ([object isKindOfClass:[NSManagedObjectID class]]) {
        return object;
    } else if (!object) {
        return nil;
    }
    
    NSCAssert(NO, @"%@ is unsupported by performBlock:withObject:", object);
    return nil;
}

static id managedObjectCollector(id objectIDs, NSManagedObjectContext *context)
{
    if ([objectIDs isKindOfClass:[NSArray class]]) {
        NSArray *array = objectIDs;
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
        
        for (id object in array) {
            [newArray addObject:managedObjectCollector(object, context)];
        }
        
        return newArray;
    } else if ([objectIDs isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = objectIDs;
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
        
        for (id key in dictionary) {
            newDictionary[key] = managedObjectCollector(dictionary[key], context);
        }
        
        return newDictionary;
    } else if ([objectIDs isKindOfClass:[NSManagedObjectID class]]) {
        NSError *error = nil;
        NSManagedObject *managedObject = [context existingObjectWithID:objectIDs error:&error];
        NSCAssert(error == nil, @"error in managedObjectCollector: %@. Make sure to only use performBlock:withObjects: with _saved_ managed objects.", error);

        return managedObject;
    } else if (!objectIDs) {
        return nil;
    }
    
    NSCAssert(NO, @"%@ is unsupported by performBlock:withObject:", objectIDs);
    return nil;
}



@implementation NSManagedObjectContext (SLRESTfulCoreData)

- (void)__SLRESTfulCoreDataPerformBlock:(void (^)(id object))block withObjectIDs:(id)objectIDs
{
    NSParameterAssert(block);
    
    [self performBlock:^{
        block(managedObjectCollector(objectIDs, self));
    }];
}

- (void)performBlock:(void (^)(id object))block withObject:(id)object
{
    [self __SLRESTfulCoreDataPerformBlock:block withObjectIDs:managedObjectIDCollector(object)];
}

@end
