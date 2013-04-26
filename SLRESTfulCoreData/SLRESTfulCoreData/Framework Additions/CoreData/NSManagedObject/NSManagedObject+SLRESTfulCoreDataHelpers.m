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
#import "SLAttributeMapping.h"
#import "SLObjectDescription.h"
#import "SLObjectConverter.h"



@implementation NSManagedObject (SLRESTfulCoreDataHelpers)

+ (NSArray *)attributeNames
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
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    SLObjectConverter *objectConverter = [self objectConverter];
    
    NSString *uniqueKeyForJSONDictionary = [self objectDescription].uniqueIdentifierOfJSONObjects;
    NSString *managedObjectUniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];
    
    id managedObjectID = [objectConverter managedObjectObjectFromJSONObjectObject:identifier
                                                        forManagedObjectAttribute:managedObjectUniqueKey];
    
    if (!managedObjectID) {
        NSLog(@"WARNING: cannot convert JSON object %@ into CoreData object", identifier);
        return nil;
    }
    
    NSAssert([[self attributeNames] containsObject:managedObjectUniqueKey], @"no unique key attribute found to %@. tried to map %@ to %@", self, uniqueKeyForJSONDictionary, managedObjectUniqueKey);
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:[self mainThreadManagedObjectContext]];
    NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectUniqueKey];
    
    NSAssert(attributeDescription != nil, @"no attributeDescription found for %@[%@]", self, managedObjectUniqueKey);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self)];
    
    if (attributeDescription.attributeType == NSStringAttributeType) {
        request.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", managedObjectUniqueKey, managedObjectID];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", managedObjectUniqueKey, managedObjectID];
    }
    
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);
    
    if (objects.count > 0) {
        return objects[0];
    }
    
    return nil;
}

@end
