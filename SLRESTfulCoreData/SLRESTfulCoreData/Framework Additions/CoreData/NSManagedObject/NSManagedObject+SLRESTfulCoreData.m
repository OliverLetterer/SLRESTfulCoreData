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
#import "SLRESTfulCoreDataObjectCache.h"

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
    return [self updatedObjectWithRawJSONDictionary:rawDictionary
                            relationshipUpdateLevel:[self objectDescription].relationshipUpdateLevel
                             inManagedObjectContext:context];
}

+ (instancetype)updatedObjectWithRawJSONDictionary:(NSDictionary *)rawDictionary
                           relationshipUpdateLevel:(NSInteger)relationshipUpdateLevel
                            inManagedObjectContext:(NSManagedObjectContext *)context
{
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    SLObjectConverter *objectConverter = [self objectConverter];

    if (![rawDictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"WARNING: JSON Object is not a NSDictionary (%@)", rawDictionary);
        return nil;
    }

    Class modelClass = [objectConverter subclassForRawJSONDictionary:rawDictionary] ?: self;
    NSString *uniqueKeyForJSONDictionary = [self objectDescription].uniqueIdentifierOfJSONObjects;

    NSString *modelClassName = NSStringFromClass(modelClass);
    NSString *managedObjectUniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];

    id JSONObjectID = rawDictionary[uniqueKeyForJSONDictionary];
    id managedObjectID = [objectConverter managedObjectObjectFromJSONObjectObject:JSONObjectID
                                                        forManagedObjectAttribute:managedObjectUniqueKey];

    if (!managedObjectID) {
        NSLog(@"WARNING: JSON Object did not have an id (%@)", rawDictionary);
        return nil;
    }

    NSManagedObject *object = [self objectWithRemoteIdentifier:managedObjectID inManagedObjectContext:context];
    if (!object) {
        object = [NSEntityDescription insertNewObjectForEntityForName:modelClassName
                                               inManagedObjectContext:context];
    }

    [object updateWithRawJSONDictionary:rawDictionary relationshipUpdateLevel:relationshipUpdateLevel];

    return object;
}

- (void)updateWithRawJSONDictionary:(NSDictionary *)rawDictionary
{
    if (!self.managedObjectContext || self.isDeleted) {
        return;
    }

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self.class)
                                                         inManagedObjectContext:self.managedObjectContext];
    NSDictionary *attributesByName = [entityDescription attributesByName];

    NSArray *attributes = [self.class registeredAttributeNames];
    SLObjectConverter *objectConverter = [self.class objectConverter];
    SLAttributeMapping *attributeMapping = [self.class attributeMapping];
    BOOL checksAttributesForEqualityBeforeAssigning = objectConverter.checksAttributesForEqualityBeforeAssigning;

    for (NSString *attributeName in attributes) {
        NSString *JSONObjectKeyPath = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:attributeName];
        id rawJSONObject = [rawDictionary valueForKeyPath:JSONObjectKeyPath];

        if (!rawJSONObject) {
            continue;
        }

        if ([rawJSONObject isEqual:[NSNull null]]) {
            if (checksAttributesForEqualityBeforeAssigning) {
                if ([self valueForKey:attributeName]) {
                    [self setValue:nil forKey:attributeName];
                }
            } else {
                [self setValue:nil forKey:attributeName];
            }
            continue;
        }

        id myValue = [objectConverter managedObjectObjectFromJSONObjectObject:rawJSONObject
                                                    forManagedObjectAttribute:attributeName];

        NSAttributeDescription *attributeDescription = attributesByName[attributeName];

        if (myValue || attributeDescription.isOptional) {
            if (checksAttributesForEqualityBeforeAssigning) {
                id previousValue = [self valueForKey:attributeName];

                if (![myValue isEqual:previousValue]) {
                    [self setValue:myValue forKey:attributeName];
                }
            } else {
                [self setValue:myValue forKey:attributeName];
            }
        }
    }
}

- (void)updateRelationshipsWithRawJSONDictionary:(NSDictionary *)rawDictionary
                         relationshipUpdateLevel:(NSInteger)relationshipUpdateLevel
{
    if (!self.managedObjectContext) {
        return;
    }

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self.class)
                                                         inManagedObjectContext:self.managedObjectContext];
    SLAttributeMapping *attributeMapping = [self.class attributeMapping];
    SLObjectConverter *objectConverter = [self.class objectConverter];
    BOOL checksAttributesForEqualityBeforeAssigning = objectConverter.checksAttributesForEqualityBeforeAssigning;

    if (relationshipUpdateLevel <= 0) {
        return;
    }

    NSDictionary *relationshipsByName = entityDescription.relationshipsByName;

    for (NSString *relationshipName in relationshipsByName) {
        NSRelationshipDescription *relationship = relationshipsByName[relationshipName];
        NSAssert(relationship.inverseRelationship != nil, @"No inverseRelationship found for relationship %@ on %@", relationshipName, self.class);

        Class destinationClass = NSClassFromString(relationship.destinationEntity.managedObjectClassName);
        NSString *uniqueJSONObjectIdentifier = [destinationClass objectDescription].uniqueIdentifierOfJSONObjects;
        NSString *uniqueManagedObjectIdentifier = [[destinationClass attributeMapping] convertJSONObjectAttributeToManagedObjectAttribute:uniqueJSONObjectIdentifier];

        NSString *JSONRelationshipName = [[destinationClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:relationshipName];
        NSString *myRelationshipName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:relationshipName];
        NSString *JSONObjectKeyForDestinationIdentifier = [[destinationClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:relationshipName].mutableCopy;
        JSONObjectKeyForDestinationIdentifier = [JSONObjectKeyForDestinationIdentifier stringByAppendingFormat:@"_%@", uniqueJSONObjectIdentifier];

        id relationshipObject = rawDictionary[JSONRelationshipName] ?: rawDictionary[myRelationshipName];

        if (relationshipObject) {
            // directly update relationship if present
            NSURL *dummyURL = [NSURL URLWithString:@""];
            NSError *error = nil;

            [self updateObjectsForRelationship:relationshipName withJSONObject:relationshipObject fromURL:dummyURL deleteEveryOtherObject:YES relationshipUpdateLevel:relationshipUpdateLevel - 1 error:&error];
        } else if (rawDictionary[JSONObjectKeyForDestinationIdentifier] && !relationship.isToMany) {
            id uniqueIdentifier = [[destinationClass objectConverter] managedObjectObjectFromJSONObjectObject:rawDictionary[JSONObjectKeyForDestinationIdentifier]
                                                                                    forManagedObjectAttribute:uniqueManagedObjectIdentifier];
            if (uniqueIdentifier) {
                id relationshipEntity = [destinationClass objectWithRemoteIdentifier:uniqueIdentifier inManagedObjectContext:self.managedObjectContext];

                if (checksAttributesForEqualityBeforeAssigning) {
                    if (relationshipEntity != [self valueForKey:relationshipName]) {
                        [self setValue:relationshipEntity forKey:relationshipName];
                    }
                } else {
                    [self setValue:relationshipEntity forKey:relationshipName];
                }
            }

            NSString *destinationDictionaryKey = [[destinationClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:relationshipName];
            id destinationDictionary = rawDictionary[destinationDictionaryKey];

            if ([destinationDictionary isKindOfClass:[NSDictionary class]]) {
                id relationshipEntity = [destinationClass updatedObjectWithRawJSONDictionary:destinationDictionary
                                                                     relationshipUpdateLevel:relationshipUpdateLevel - 1
                                                                      inManagedObjectContext:self.managedObjectContext];

                if (checksAttributesForEqualityBeforeAssigning) {
                    if ([self valueForKey:relationshipName] != relationshipEntity) {
                        [self setValue:relationshipEntity forKey:relationshipName];
                    }
                } else {
                    [self setValue:relationshipEntity forKey:relationshipName];
                }
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
                if (checksAttributesForEqualityBeforeAssigning) {
                    if ([entity valueForKey:inverseRelationship.name] != self) {
                        [entity setValue:self forKey:inverseRelationship.name];
                    }
                } else {
                    [entity setValue:self forKey:inverseRelationship.name];
                }
            }
        }
    }
}

- (void)updateWithRawJSONDictionary:(NSDictionary *)rawDictionary
            relationshipUpdateLevel:(NSInteger)relationshipUpdateLevel
{
    [self updateWithRawJSONDictionary:rawDictionary];
    [self updateRelationshipsWithRawJSONDictionary:rawDictionary relationshipUpdateLevel:relationshipUpdateLevel];
}

- (NSDictionary *)rawJSONDictionary
{
    SLAttributeMapping *attributeMapping = [self.class attributeMapping];
    SLObjectConverter *objectConverter = [self.class objectConverter];

    NSMutableDictionary *rawJSONDictionary = [NSMutableDictionary dictionary];

    for (NSString *attributeName in [self.class registeredAttributeNames]) {
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
    return [self updateObjectsForRelationship:relationship withJSONObject:JSONObject fromURL:URL deleteEveryOtherObject:deleteEveryOtherObject relationshipUpdateLevel:[self.class objectDescription].relationshipUpdateLevel error:error];
}

- (NSArray *)updateObjectsForRelationship:(NSString *)relationship
                           withJSONObject:(id)JSONObject
                                  fromURL:(NSURL *)URL
                   deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
                  relationshipUpdateLevel:(NSInteger)relationshipUpdateLevel
                                    error:(NSError *__autoreleasing *)error
{
    if (!self.managedObjectContext) {
        return @[];
    }

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(self.class)
                                                         inManagedObjectContext:self.managedObjectContext];

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

    Class destinationClass = NSClassFromString(destinationClassName);
    SLObjectDescription *destinationDescription = [destinationClass objectDescription];
    NSString *destinationObjectUniqueJSONObjectKeyPath = destinationDescription.uniqueIdentifierOfJSONObjects;

    // update attributes based in relationship type
    if (relationshipDescription.isToMany) {
        if (![JSONObject isKindOfClass:[NSArray class]]) {
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }

        NSArray *JSONObjectsArray = JSONObject;

        // grab each unique identifier from JSONObjectsArray
        NSMutableSet *allUniqueIdentifiers = [NSMutableSet setWithCapacity:JSONObjectsArray.count];

        for (NSDictionary *rawDictionary in JSONObjectsArray) {
            if (![rawDictionary isKindOfClass:NSDictionary.class]) {
                // make sure JSONObject has correct class
                *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
                return nil;
            }

            NSString *uniqueIdentifier = rawDictionary[destinationDescription.uniqueIdentifierOfJSONObjects];

            if (uniqueIdentifier) {
                [allUniqueIdentifiers addObject:uniqueIdentifier];
            }
        }

        NSDictionary *indexedObjects = [[SLRESTfulCoreDataObjectCache sharedCacheForManagedObjectContext:self.managedObjectContext] indexedObjectsOfClass:destinationClass withRemoteIdentifiers:allUniqueIdentifiers];

        // enumerate raw JSON objects and update destination entity with these.
        for (NSDictionary *rawDictionary in JSONObjectsArray) {
            id identifier = rawDictionary[destinationObjectUniqueJSONObjectKeyPath];
            id object = indexedObjects[identifier];

            if (object) {
                [object updateWithRawJSONDictionary:rawDictionary relationshipUpdateLevel:relationshipUpdateLevel];
            } else {
                object = [destinationClass updatedObjectWithRawJSONDictionary:rawDictionary relationshipUpdateLevel:relationshipUpdateLevel inManagedObjectContext:self.managedObjectContext];
            }

            BOOL checksAttributesForEqualityBeforeAssigning = [destinationClass objectConverter].checksAttributesForEqualityBeforeAssigning;

            if (inverseRelationship.isToMany) {
                NSString *name = [inverseRelationshipName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                                  withString:[inverseRelationshipName substringToIndex:1].uppercaseString];

                NSString *selectorName = [NSString stringWithFormat:@"add%@Object:", name];
                SEL selector = NSSelectorFromString(selectorName);

                ((void(*)(id, SEL, id))objc_msgSend)(object, selector, self);
            } else {
                if (checksAttributesForEqualityBeforeAssigning) {
                    if ([object valueForKey:inverseRelationshipName] != self) {
                        [object setValue:self forKey:inverseRelationshipName];
                    }
                } else {
                    [object setValue:self forKey:inverseRelationshipName];
                }
            }

            if (object) {
                [updatedObjects addObject:object];
            } else {
                *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
                return nil;
            }
        }
    } else {
        if (![JSONObject isKindOfClass:[NSDictionary class]]) {
            // make sure JSONObject has correct class
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }

        // update destination entity with JSON object.
        id object = [destinationClass updatedObjectWithRawJSONDictionary:JSONObject relationshipUpdateLevel:relationshipUpdateLevel - 1 inManagedObjectContext:self.managedObjectContext];
        [self setValue:object forKey:relationship];

        if (object) {
            [updatedObjects addObject:object];
        } else {
            *error = [NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL];
            return nil;
        }
    }

    if (relationshipDescription.isToMany) {
        NSMutableSet *deletionSet = [[self valueForKey:relationship] mutableCopy];
        for (id object in updatedObjects) {
            [deletionSet removeObject:object];
        }

        for (id object in deletionSet) {
            if (deleteEveryOtherObject) {
                [self.managedObjectContext deleteObject:object];
            } else {
                NSString *name = [relationship stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                       withString:[relationship substringToIndex:1].uppercaseString];
                
                NSString *selectorName = [NSString stringWithFormat:@"remove%@Object:", name];
                SEL selector = NSSelectorFromString(selectorName);
                
                ((void(*)(id, SEL, id))objc_msgSend)(self, selector, object);
            }
        }
    }
    
    NSError *saveError = nil;
    if (![self.managedObjectContext save:&saveError]) {
        *error = saveError;
    }
    
    return updatedObjects;
}

@end
