//
//  NSManagedObject+SLRESTfulCoreData.m
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

#import "NSManagedObject+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataQueryInterface.h"
#import "NSManagedObject+SLRESTfulCoreDataSetup.h"
#import "NSManagedObject+SLRESTfulCoreDataHelpers.h"
#import "NSError+SLRESTfulCoreData.h"
#import "SLObjectConverter.h"
#import "SLObjectDescription.h"
#import "SLAttributeMapping.h"
#import <objc/message.h>

char *const SLRESTfulCoreDataBackgroundQueueNameKey;
char *const SLRESTfulCoreDataDefaultBackgroundQueueKey;
char *const SLRESTfulCoreDataMainThreadActionKey;
char *const SLRESTfulCoreDataBackgroundThreadActionKey;



@implementation NSManagedObject (SLRESTfulCoreData)

+ (NSManagedObjectContext *)mainThreadManagedObjectContext
{
    SLRESTfulCoreDataManagedObjectContextBlock action = [self defaultMainThreadManagedObjectContextAction];
    
    if (action) {
        return action();
    }
    
    [NSException raise:NSInternalInconsistencyException format:@"%@ does not recognize selector %@", self, NSStringFromSelector(_cmd)];
    return nil;
}

+ (SLRESTfulCoreDataManagedObjectContextBlock)defaultMainThreadManagedObjectContextAction
{
    return objc_getAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataMainThreadActionKey);
}

+ (void)registerDefaultMainThreadManagedObjectContextWithAction:(SLRESTfulCoreDataManagedObjectContextBlock)action
{
    objc_setAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataMainThreadActionKey,
                             action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    SLRESTfulCoreDataManagedObjectContextBlock action = [self defaultBackgroundThreadManagedObjectContextAction];
    
    if (action) {
        return action();
    }
    
    [NSException raise:NSInternalInconsistencyException format:@"%@ does not recognize selector %@", self, NSStringFromSelector(_cmd)];
    return nil;
}

+ (SLRESTfulCoreDataManagedObjectContextBlock)defaultBackgroundThreadManagedObjectContextAction
{
    return objc_getAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataBackgroundThreadActionKey);
}

+ (void)registerDefaultBackgroundThreadManagedObjectContextWithAction:(SLRESTfulCoreDataManagedObjectContextBlock)action
{
    objc_setAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataBackgroundThreadActionKey,
                             action, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue
{
    id<SLRESTfulCoreDataBackgroundQueue> backgroundQueue = objc_getAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataDefaultBackgroundQueueKey);
    
    if (backgroundQueue) {
        return backgroundQueue;
    }
    
    NSAssert(NO, @"you must implement +[NSManagedObject backgroundQueue] for %@ or set a background queue via +[NSManagedObject setDefaultBackgroundQueue:]", self);
    return nil;
}

+ (void)setDefaultBackgroundQueue:(id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue
{
    objc_setAssociatedObject([NSManagedObject class], &SLRESTfulCoreDataDefaultBackgroundQueueKey,
                             backgroundQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)updatedObjectWithRawJSONDictionary:(NSDictionary *)rawDictionary
                            inManagedObjectContext:(NSManagedObjectContext *)context
{
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    SLObjectConverter *objectConverter = [self objectConverter];
    
    if (![rawDictionary isKindOfClass:NSDictionary.class]) {
        NSLog(@"WARNING: JSON Object is not a NSDictionary (%@)", rawDictionary);
        return nil;
    }
    
    Class modelClass = [objectConverter subclassForRawJSONDictionary:rawDictionary] ?: self;
    NSString *uniqueKeyForJSONDictionary = [self objectDescription].uniqueIdentifierOfJSONObjects;
    
    NSString *modelClassName = NSStringFromClass(modelClass);
    NSString *managedObjectUniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:modelClassName];
    id JSONObjectID = rawDictionary[uniqueKeyForJSONDictionary];
    id managedObjectID = [objectConverter managedObjectObjectFromJSONObjectObject:JSONObjectID
                                                        forManagedObjectAttribute:managedObjectUniqueKey];
    
    if (!managedObjectID) {
        NSLog(@"WARNING: JSON Object did not have an id (%@)", rawDictionary);
        return nil;
    }
    
    NSAssert([[self attributeNames] containsObject:managedObjectUniqueKey], @"no unique key attribute found to %@. tried to map %@ to %@", self, uniqueKeyForJSONDictionary, managedObjectUniqueKey);
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:[self mainThreadManagedObjectContext]];
    NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectUniqueKey];
    
    NSAssert(attributeDescription != nil, @"no attributeDescription found for %@[%@]", self, managedObjectUniqueKey);
    
    if (attributeDescription.attributeType == NSStringAttributeType) {
        request.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", managedObjectUniqueKey, managedObjectID];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", managedObjectUniqueKey, managedObjectID];
    }
    
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request
                                              error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);
    
    NSManagedObject *object = nil;
    if (objects.count > 0) {
        object = objects[0];
    } else {
        object = [NSEntityDescription insertNewObjectForEntityForName:modelClassName
                                               inManagedObjectContext:context];
    }
    
    [object updateWithRawJSONDictionary:rawDictionary];
    
    return object;
}

- (void)updateWithRawJSONDictionary:(NSDictionary *)rawDictionary
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self.class)
                                                         inManagedObjectContext:self.managedObjectContext];
    NSDictionary *attributesByName = [entityDescription attributesByName];
    
    NSArray *attributes = [self.class attributeNames];
    SLObjectConverter *objectConverter = [self.class objectConverter];
    SLAttributeMapping *attributeMapping = [self.class attributeMapping];
    
    // update my attributes
    for (NSString *attributeName in attributes) {
        NSString *JSONObjectKeyPath = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:attributeName];
        id rawJSONObject = [rawDictionary valueForKeyPath:JSONObjectKeyPath];
        
        id myValue = [objectConverter managedObjectObjectFromJSONObjectObject:rawJSONObject
                                                    forManagedObjectAttribute:attributeName];
        
        NSAttributeDescription *attributeDescription = attributesByName[attributeName];
        
        if (myValue || attributeDescription.isOptional) {
            [self setValue:myValue forKey:attributeName];
        }
    }
    
    // update my relationships
    NSDictionary *relationshipsByName = entityDescription.relationshipsByName;
    
    for (NSString *relationshipName in relationshipsByName) {
        NSRelationshipDescription *relationship = relationshipsByName[relationshipName];
        Class destinationClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);
        NSString *uniqueJSONObjectIdentifier = [destinationClass objectDescription].uniqueIdentifierOfJSONObjects;
        NSString *uniqueManagedObjectIdentifier = [[destinationClass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:uniqueJSONObjectIdentifier];
        
        if (!relationship.isToMany) {
            // to one relationship
            
            // first check if there is an XXX_id for the foreign object
            NSString *JSONObjectKeyForDestinationIdentifier = [[destinationClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:[relationshipName stringByAppendingString:uniqueManagedObjectIdentifier.capitalizedString]];
            
            id uniqueIdentifier = [[destinationClass objectConverter] managedObjectObjectFromJSONObjectObject:rawDictionary[JSONObjectKeyForDestinationIdentifier]
                                                                                    forManagedObjectAttribute:uniqueManagedObjectIdentifier];
            if (uniqueIdentifier) {
                id relationshipEntity = [destinationClass objectWithRemoteIdentifier:uniqueIdentifier inManagedObjectContext:self.managedObjectContext];
                [self setValue:relationshipEntity forKey:relationshipName];
            }
            
            NSString *destinationDictionaryKey = [[destinationClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:relationshipName];
            id destinationDictionary = rawDictionary[destinationDictionaryKey];
            
            if ([destinationDictionary isKindOfClass:[NSDictionary class]]) {
                id relationshipEntity = [destinationClass updatedObjectWithRawJSONDictionary:destinationDictionary
                                                                      inManagedObjectContext:self.managedObjectContext];
                [self setValue:relationshipEntity forKey:relationshipName];
            }
        }
        
        NSRelationshipDescription *inverseRelationship = relationship.inverseRelationship;
        
        // update all existing objects with reference this object with its unique identifier
        if (!inverseRelationship.isToMany) {
            NSString *attributeName = [inverseRelationship.name stringByAppendingString:uniqueManagedObjectIdentifier.capitalizedString];
            NSAttributeDescription *attributeDescription = relationship.destinationEntity.attributesByName[attributeName];
            
            if (!attributeDescription) {
                continue;
            }
            
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:relationship.destinationEntity.managedObjectClassName];
            
            if (attributeDescription.attributeType == NSStringAttributeType) {
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", attributeName, [self valueForKey:uniqueManagedObjectIdentifier]];
            } else {
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", attributeName, [self valueForKey:uniqueManagedObjectIdentifier]];
            }
            
            NSError *error = nil;
            NSArray *matchingEntities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            NSAssert(error == nil, @"error while fetching entities which should be updated for this remote object: %@", error);
            
            for (id entity in matchingEntities) {
                [entity setValue:self forKey:inverseRelationship.name];
            }
        }
    }
}

- (NSDictionary *)rawJSONDictionary
{
    SLAttributeMapping *attributeMapping = [self.class attributeMapping];
    SLObjectConverter *objectConverter = [self.class objectConverter];
    
    NSMutableDictionary *rawJSONDictionary = [NSMutableDictionary dictionary];
    
    for (NSString *attributeName in [self.class attributeNames]) {
        id value = [self valueForKey:attributeName];
        
        if (value) {
            NSString *JSONObjectKeyPath = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:attributeName];
            id JSONObjectValue = [objectConverter JSONObjectObjectFromManagedObjectObject:value
                                                                forManagedObjectAttribute:attributeName];
            
            if (!JSONObjectValue) {
                continue;
            }
            
            __block NSMutableDictionary *currentDictionary = rawJSONDictionary;
            
            NSArray *JSONObjectKeyPaths = [JSONObjectKeyPath componentsSeparatedByString:@"."];
            NSUInteger count = JSONObjectKeyPaths.count;
            [JSONObjectKeyPaths enumerateObjectsUsingBlock:^(NSString *JSONObjectKey, NSUInteger idx, BOOL *stop) {
                if (idx == count - 1) {
                    currentDictionary[JSONObjectKey] = JSONObjectValue;
                } else {
                    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                    
                    currentDictionary[JSONObjectKey] = dictionary;
                    currentDictionary = dictionary;
                }
            }];
        }
    }
    
    return rawJSONDictionary;
}

- (NSArray *)updateObjectsForRelationship:(NSString *)relationship
                           withJSONObject:(id)JSONObject
                                  fromURL:(NSURL *)URL
                   deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
                                    error:(NSError *__autoreleasing *)error
{
    NSManagedObjectContext *context = [self.class mainThreadManagedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self.class)
                                                         inManagedObjectContext:context];
    
    NSMutableArray *updatedObjects = [NSMutableArray array];
    
    // get relationship description, name of destination entity and the name of the invers relation.
    NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[relationship];
    NSAssert(relationshipDescription != nil, @"There is no relationship %@ for %@", relationship, self.class);
    
    NSString *destinationClassName = relationshipDescription.destinationEntity.managedObjectClassName;
    NSAssert(destinationClassName != nil, @"no managedObjectClassName specified for destinationEntity %@", relationshipDescription.destinationEntity);
    NSString *inverseRelationshipName = relationshipDescription.inverseRelationship.name;
    NSAssert(inverseRelationshipName != nil, @"no inverseRelationshipName specified for relationshipDescription %@", relationshipDescription);
    NSParameterAssert(error);
    
    NSRelationshipDescription *inverseRelationship = relationshipDescription.inverseRelationship;
    NSAssert(inverseRelationship != nil, @"%@ does not have an inverse", relationship);
    
    // update attributes based in relationship type
    if (relationshipDescription.isToMany) {
        // is a 1-to-many relation
        if (![JSONObject isKindOfClass:NSArray.class]) {
            // make sure JSONObject has correct class
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }
        NSArray *JSONObjectsArray = JSONObject;
        
        // enumerate raw JSON objects and update destination entity with these.
        for (NSDictionary *rawDictionary in JSONObjectsArray) {
            if (![rawDictionary isKindOfClass:NSDictionary.class]) {
                // make sure JSONObject has correct class
                *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
                return nil;
            }
            
            id object = [NSClassFromString(destinationClassName) updatedObjectWithRawJSONDictionary:rawDictionary inManagedObjectContext:self.managedObjectContext];
            
            if (inverseRelationship.isToMany) {
                NSString *name = [inverseRelationshipName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                                  withString:[inverseRelationshipName substringToIndex:1].uppercaseString];
                
                NSString *selectorName = [NSString stringWithFormat:@"add%@Object:", name];
                SEL selector = NSSelectorFromString(selectorName);
                
                objc_msgSend(object, selector, self);
            } else {
                [object setValue:self forKey:inverseRelationshipName];
            }
            
            if (object) {
                [updatedObjects addObject:object];
            } else {
                *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
                return nil;
            }
        }
    } else {
        if (![JSONObject isKindOfClass:NSDictionary.class]) {
            // make sure JSONObject has correct class
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }
        
        // update destination entity with JSON object.
        id object = [NSClassFromString(destinationClassName) updatedObjectWithRawJSONDictionary:JSONObject inManagedObjectContext:self.managedObjectContext];
        [self setValue:object forKey:relationship];
        
        if (object) {
            [updatedObjects addObject:object];
        } else {
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }
    }
    
    if (deleteEveryOtherObject && relationshipDescription.isToMany) {
        NSMutableSet *deletionSet = [[self valueForKey:relationship] mutableCopy];
        for (id object in updatedObjects) {
            [deletionSet removeObject:object];
        }
        
        for (id object in deletionSet) {
            [self.managedObjectContext deleteObject:object];
        }
    }
    
    NSError *saveError = nil;
    if (![self.managedObjectContext save:&saveError]) {
        *error = saveError;
    }
    
    return updatedObjects;
}

@end
