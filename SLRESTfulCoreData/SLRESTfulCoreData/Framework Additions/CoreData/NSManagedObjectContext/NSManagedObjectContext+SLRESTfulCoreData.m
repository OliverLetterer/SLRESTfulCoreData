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

static NSArray *arrayByCollectiongObjects(NSArray *array, id(^collector)(id object))
{
    NSCParameterAssert(collector);
    
    NSMutableArray *finalArray = [NSMutableArray arrayWithCapacity:array.count];
    
    for (id obj in array) {
        id object = collector(obj);
        
        if (object) {
            [finalArray addObject:object];
        }
    }
    
    return finalArray;
}

static NSArray *managedObjectIDCollector(NSArray *objects)
{
    return arrayByCollectiongObjects(objects, ^id(id object) {
        if ([object isKindOfClass:[NSArray class]]) {
            return managedObjectIDCollector(object);
        } else if ([object isKindOfClass:[NSManagedObject class]]) {
            return [(NSManagedObject *)object objectID];
        }
        
        NSCAssert(NO, @"%@ is unsupported by SLRESTfulCoreDataManagedObjectIDCollector", object);
        return nil;
    });
}

static NSArray *managedObjectCollector(NSArray *objectIDs, NSManagedObjectContext *context)
{
    return arrayByCollectiongObjects(objectIDs, ^id(id object) {
        if ([object isKindOfClass:[NSArray class]]) {
            return managedObjectCollector(object, context);
        } else if ([object isKindOfClass:[NSManagedObjectID class]]) {
            return [context objectWithID:object];
        }
        
        NSCAssert(NO, @"%@ is unsupported by SLRESTfulCoreDataManagedObjectIDCollector", object);
        return nil;
    });
}



@implementation NSManagedObjectContext (SLRESTfulCoreData)

- (void)performBlock:(void (^)(NSArray *objects))block withObjectIDs:(NSArray *)objectIDs
{
    NSParameterAssert(block);
    
    [self performBlock:^{
        NSArray *objects = managedObjectCollector(objectIDs, self);
        block(objects);
    }];
}

- (void)performBlock:(void (^)(NSArray *objects))block withObjects:(NSArray *)objects
{
    [self performBlock:block withObjectIDs:managedObjectIDCollector(objects)];
}

@end
