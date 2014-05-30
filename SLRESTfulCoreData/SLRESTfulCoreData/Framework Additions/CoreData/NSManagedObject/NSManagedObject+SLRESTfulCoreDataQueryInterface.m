//
//  NSManagedObject+SLRESTfulCoreDataQueryInterface.m
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

#import "NSManagedObject+SLRESTfulCoreDataQueryInterface.h"
#import "NSManagedObject+SLRESTfulCoreData.h"
#import "SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataHelpers.h"
#import <objc/message.h>

static void deleteObjectsWithoutRemoteIDs(NSManagedObjectContext *context, Class class, NSArray *remoteIDs)
{
    SLAttributeMapping *attributeMapping = [class attributeMapping];
    NSString *idKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:[class objectDescription].uniqueIdentifierOfJSONObjects];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(class)];
    request.predicate = [NSPredicate predicateWithFormat:@"NOT (%K IN %@)", idKey, remoteIDs];

    NSError *error = nil;
    NSArray *objectsToBeDeleted = [context executeFetchRequest:request error:&error];
    NSCAssert(error == nil, @"error while fetching: %@", error);

    for (id object in objectsToBeDeleted) {
        [context deleteObject:object];
    }
}

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}



@implementation NSManagedObject (SLRESTfulCoreDataQueryInterface)

+ (void)load
{
    class_swizzleSelector(object_getClass(self), @selector(resolveInstanceMethod:), @selector(__SLRESTfulCoreDataResolveInstanceMethod:));
    class_swizzleSelector(object_getClass(self), @selector(resolveInstanceMethod:), @selector(_resolveCRUDBasedRelationshipInstanceMethod:));
}

+ (BOOL)_resolveCRUDBasedRelationshipInstanceMethod:(SEL)sel
{
    if ([self _resolveCRUDBasedRelationshipInstanceMethod:sel]) {
        return YES;
    }

    NSString *selectorName = NSStringFromSelector(sel);

    if (![selectorName hasSuffix:@"withCompletionHandler:"]) {
        return NO;
    }

    NSMutableString *mutableSelectorName = selectorName.mutableCopy;
    NSUInteger colonCount = [mutableSelectorName replaceOccurrencesOfString:@":" withString:@"." options:NSLiteralSearch range:NSMakeRange(0, mutableSelectorName.length)];

    if (colonCount != 2) {
        return NO;
    }

    // CoreData is creating for the entity SLEntity1 an new subclass SLEntity1_SLEntity1 and KVO an additional NSKeyValueObserving_SLEntity1_SLEntity1
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    NSUInteger firstColonPosition = [selectorName rangeOfString:@":"].location;
    NSString *firstSelectorPart = [selectorName substringToIndex:firstColonPosition];

    if (![firstSelectorPart hasSuffix:@"Object"]) {
        return NO;
    }

    __block NSEntityDescription *entityDescription = nil;

    if ([NSThread currentThread].isMainThread) {
        entityDescription = [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:[class mainThreadManagedObjectContext]];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            entityDescription = [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:[class mainThreadManagedObjectContext]];
        });
    }

    NSUInteger objectLength = @"Object".length;
    NSString *firstSelectorPartWithoutObject = [firstSelectorPart stringByReplacingCharactersInRange:NSMakeRange(firstSelectorPart.length - objectLength, objectLength) withString:@""];

    if ([firstSelectorPartWithoutObject hasPrefix:@"add"]) {
        // addFloorsObject:withCompletionHandler:
        NSString *relationshipName = [firstSelectorPartWithoutObject substringFromIndex:3];
        relationshipName = [relationshipName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[relationshipName substringToIndex:1].lowercaseString];

        NSRelationshipDescription *relationship = entityDescription.relationshipsByName[relationshipName];
        if (!relationship) {
            NSLog(@"%@: relationship %@ was not found", class, relationshipName);
            return NO;
        }

        NSParameterAssert(relationship.inverseRelationship);
        NSString *inverseRelationshipName = relationship.inverseRelationship.name;

        Class destinationEntityClass = NSClassFromString(relationship.destinationEntity.name);
        NSURL *CRUDBaseURL = [[class objectDescription] CRUDBaseURLForRelationship:relationshipName];

        if (!CRUDBaseURL) {
            NSLog(@"No CRUDBaseURL found for %@, relationship: %@", class, relationshipName);
            return NO;
        }

        NSString *name = [[destinationEntityClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:inverseRelationshipName];
        CRUDBaseURL = [NSURL URLWithString:[CRUDBaseURL.absoluteString stringByReplacingOccurrencesOfString:@":" withString:[NSString stringWithFormat:@":%@.", name]]];

        IMP implementation = imp_implementationWithBlock(^(NSManagedObject *blockSelf, NSManagedObject *object, void(^completionHandler)(id object, NSError *error)) {
            [object setValue:blockSelf forKey:inverseRelationshipName];

            [object postToURL:CRUDBaseURL completionHandler:^(NSManagedObject *updatedObject, NSError *error) {
                if (error) {
                    if (completionHandler) {
                        completionHandler(nil, error);
                    }
                    return;
                }

                NSManagedObjectContext *context = [class backgroundThreadManagedObjectContext];
                [context performBlock:^(NSArray *objects) {
                    NSManagedObject *updatedObject = objects[0];
                    NSManagedObject *blockSelf = objects[1];

                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:context];
                    NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[relationshipName];
                    NSAssert(relationshipDescription != nil, @"");

                    if (relationshipDescription.isToMany) {
                        NSString *selectorName = [firstSelectorPart stringByAppendingString:@":"];
                        ((void(*)(id, SEL, id))objc_msgSend)(blockSelf, NSSelectorFromString(selectorName), updatedObject);
                    } else {
                        [updatedObject setValue:blockSelf forKey:relationshipDescription.name];
                    }

                    NSError *saveError = nil;
                    [context save:&saveError];
                    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                    [[class mainThreadManagedObjectContext] performBlock:^(NSArray *objects) {
                        if (completionHandler) {
                            completionHandler(objects[0], nil);
                        }
                    } withObject:@[ updatedObject ]];
                } withObject:@[ updatedObject, blockSelf ]];
            }];
        });

        class_addMethod(self, sel, implementation, "v@:@@");

        return YES;
    } else if ([firstSelectorPartWithoutObject hasPrefix:@"delete"]) {
        // deleteFloorsObject:withCompletionHandler:
        NSString *relationshipName = [firstSelectorPartWithoutObject substringFromIndex:6];
        relationshipName = [relationshipName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[relationshipName substringToIndex:1].lowercaseString];

        NSRelationshipDescription *relationship = entityDescription.relationshipsByName[relationshipName];
        if (!relationship) {
            NSLog(@"%@: relationship %@ was not found", class, relationshipName);
            return NO;
        }

        NSParameterAssert(relationship.inverseRelationship);
        NSString *inverseRelationshipName = relationship.inverseRelationship.name;

        Class destinationEntityClass = NSClassFromString(relationship.destinationEntity.name);
        NSURL *CRUDBaseURL = [[class objectDescription] CRUDBaseURLForRelationship:relationshipName];

        if (!CRUDBaseURL) {
            NSLog(@"No CRUDBaseURL found for %@, relationship: %@", class, relationshipName);
            return NO;
        }

        NSString *name = [[destinationEntityClass attributeMapping] convertManagedObjectAttributeToJSONObjectAttribute:inverseRelationshipName];
        CRUDBaseURL = [NSURL URLWithString:[CRUDBaseURL.absoluteString stringByReplacingOccurrencesOfString:@":" withString:[NSString stringWithFormat:@":%@.", name]]];
        CRUDBaseURL = [CRUDBaseURL URLByAppendingPathComponent:[NSString stringWithFormat:@":%@", [destinationEntityClass objectDescription].uniqueIdentifierOfJSONObjects]];

        IMP implementation = imp_implementationWithBlock(^(NSManagedObject *blockSelf, NSManagedObject *object, void(^completionHandler)(NSError *error)) {
            [object setValue:blockSelf forKey:inverseRelationshipName];
            [object deleteToURL:CRUDBaseURL completionHandler:completionHandler];
        });

        class_addMethod(self, sel, implementation, "v@:@@");

        return YES;
    }

    return NO;
}

+ (BOOL)__SLRESTfulCoreDataResolveInstanceMethod:(SEL)sel
{
    if ([self __SLRESTfulCoreDataResolveInstanceMethod:sel]) {
        return YES;
    }

    NSString *selectorName = NSStringFromSelector(sel);

    if (![selectorName hasSuffix:@"WithCompletionHandler:"]) {
        return NO;
    }

    if ([selectorName rangeOfString:@":"].location != selectorName.length - 1) {
        return NO;
    }

    // CoreData is creating for the entity SLEntity1 an new subclass SLEntity1_SLEntity1 and KVO an additional NSKeyValueObserving_SLEntity1_SLEntity1
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    NSString *className = NSStringFromClass(class);

    NSRange range = [selectorName rangeOfString:@"WithCompletionHandler:"];
    NSString *relationship = [selectorName substringToIndex:range.location];

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:className
                                                         inManagedObjectContext:[class mainThreadManagedObjectContext]];
    NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[relationship];

    if (!relationshipDescription) {
        return NO;
    }

    NSURL *CRUDBaseURL = [[class objectDescription] CRUDBaseURLForRelationship:relationship];

    if (!CRUDBaseURL) {
        NSLog(@"No CRUDBaseURL found for %@, relationship: %@", className, relationship);
        return NO;
    }

    BOOL isToMany = relationshipDescription.isToMany;

    IMP implementation = imp_implementationWithBlock(^(NSManagedObject *blockSelf, void(^completionHandler)(NSArray *objects, NSError *error)) {
        [blockSelf fetchObjectsForRelationship:relationship fromURL:CRUDBaseURL completionHandler:^(NSArray *fetchedObjects, NSError *error) {
            if (!completionHandler) {
                return;
            }

            if (isToMany) {
                completionHandler(fetchedObjects, error);
            } else {
                completionHandler(fetchedObjects.lastObject, error);
            }
        }];
    });

    class_addMethod(self, sel, implementation, "v@:@");

    return YES;
}

+ (void)fetchObjectFromURL:(NSURL *)URL
         completionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler
{
    NSString *jsonPrefix = [self objectDescription].jsonPrefix;
    if (jsonPrefix) {
        [[self backgroundQueue] registerResponseObjectTransformerForNextRequest:^id(NSDictionary *object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                return object[jsonPrefix];
            }

            return object;
        }];
    }

    [self fetchObjectsFromURL:URL deleteEveryOtherObject:NO completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        if (!completionHandler) {
            return;
        }

        if (error) {
            completionHandler(nil, error);
            return;
        }

        completionHandler(fetchedObjects.lastObject, nil);
    }];
}

+ (void)fetchObjectsFromURL:(NSURL *)URL
          completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    [self fetchObjectsFromURL:URL
       deleteEveryOtherObject:YES
            completionHandler:completionHandler];
}

+ (void)fetchObjectsFromURL:(NSURL *)URL
     deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
          completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    // send request to given URL
    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidStartNotification object:nil];

    NSString *pluralizedJSONPrefix = [self objectDescription].pluralizedJSONPrefix;
    if (pluralizedJSONPrefix) {
        [[self backgroundQueue] registerResponseObjectTransformerForNextRequest:^id(NSDictionary *object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                return object[pluralizedJSONPrefix];
            }

            return object;
        }];
    }

    [[self backgroundQueue] getRequestToURL:URL
                          completionHandler:^(id JSONObject, NSError *error)
     {
         NSMutableArray *fetchedObjectIDs = [NSMutableArray array];

         if (error != nil) {
             // check for error
             [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         }

         // success for now
         NSManagedObjectContext *backgroundContext = [self backgroundThreadManagedObjectContext];

         [backgroundContext performBlock:^{

             void(^successBlock)(NSArray *objects) = ^(NSArray *objects) {
                 NSManagedObjectContext *mainThreadContext = [self mainThreadManagedObjectContext];
                 [mainThreadContext performBlock:^(NSArray *objects) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];
                     if (completionHandler) {
                         completionHandler(objects, nil);
                     }
                 } withObject:objects];
             };

             void(^failureBlock)(NSError *error) = ^(NSError *error) {
                 dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];
                     if (completionHandler) {
                         completionHandler(nil, error);
                     }
                 });
             };

             NSMutableArray *updatedObjects = [NSMutableArray array];

             if ([JSONObject isKindOfClass:NSArray.class]) {
                 // convert all JSON objects into NSManagedObjects
                 for (NSDictionary *rawDictionary in JSONObject) {
                     if (![rawDictionary isKindOfClass:NSDictionary.class]) {
                         failureBlock([NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL]);
                         return;
                     }

                     id object = [self updatedObjectWithRawJSONDictionary:rawDictionary inManagedObjectContext:backgroundContext];
                     if (object) {
                         [updatedObjects addObject:object];
                     } else {
                         failureBlock([NSError SLRESTfulCoreDataErrorBecauseJSONObjectDidNotConvertInManagedObject:JSONObject fromURL:URL]);
                         return;
                     }

                     NSNumber *JSONObjectID = rawDictionary[[self objectDescription].uniqueIdentifierOfJSONObjects];
                     if (JSONObjectID) {
                         [fetchedObjectIDs addObject:JSONObjectID];
                     }
                 }
             } else if ([JSONObject isKindOfClass:NSDictionary.class]) {
                 id object = [self updatedObjectWithRawJSONDictionary:JSONObject inManagedObjectContext:backgroundContext];

                 if (object) {
                     [updatedObjects addObject:object];

                     NSNumber *JSONObjectID = JSONObject[[self objectDescription].uniqueIdentifierOfJSONObjects];
                     if (JSONObjectID) {
                         [fetchedObjectIDs addObject:JSONObjectID];
                     }
                 } else {
                     failureBlock([NSError SLRESTfulCoreDataErrorBecauseJSONObjectDidNotConvertInManagedObject:JSONObject fromURL:URL]);
                     return;
                 }
             } else {
                 // object is not supported
                 failureBlock([NSError SLRESTfulCoreDataErrorBecauseBackgroundQueueReturnedUnexpectedJSONObject:JSONObject fromURL:URL]);
                 return;
             }

             if (deleteEveryOtherObject) {
                 // now delete every object not returned from the API
                 deleteObjectsWithoutRemoteIDs(backgroundContext, self, fetchedObjectIDs);
             }

             NSError *saveError = nil;
             if (![backgroundContext save:&saveError]) {
                 failureBlock(saveError);
             } else {
                 successBlock(updatedObjects);
             }
         }];
     }];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship
                            fromURL:(NSURL *)URL
                  completionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    [self fetchObjectsForRelationship:relationship
                              fromURL:URL
               deleteEveryOtherObject:YES
                    completionHandler:completionHandler];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship
                            fromURL:(NSURL *)URL
             deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
                  completionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    if (self.isInserted || self.hasChanges) {
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error while saving: %@", saveError);
    }

    NSRelationshipDescription *relationshipDescription = self.entity.relationshipsByName[relationship];
    NSString *pluralizedJSONPrefix = [NSClassFromString(relationshipDescription.destinationEntity.name) objectDescription].pluralizedJSONPrefix;
    NSString *jsonPrefix = [NSClassFromString(relationshipDescription.destinationEntity.name) objectDescription].jsonPrefix;

    if (relationshipDescription.isToMany && pluralizedJSONPrefix) {
        [[self.class backgroundQueue] registerResponseObjectTransformerForNextRequest:^id(NSDictionary *object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                return object[pluralizedJSONPrefix];
            }

            return object;
        }];
    } else if (!relationshipDescription.isToMany && jsonPrefix) {
        [[self.class backgroundQueue] registerResponseObjectTransformerForNextRequest:^id(NSDictionary *object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                return object[jsonPrefix];
            }

            return object;
        }];
    }

    // send request to given URL
    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidStartNotification object:nil];

    [[self.class backgroundQueue] getRequestToURL:[URL URLBySubstitutingAttributesWithManagedObject:self]
                                completionHandler:^(id JSONObject, NSError *error)
     {
         if (error) {
             // check for error
             [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

             if (completionHandler) {
                 completionHandler(nil, error);
             }
             return;
         } else {
             // success for now
             NSManagedObjectID *objectID = self.objectID;
             NSManagedObjectContext *backgroundContext = [self.class backgroundThreadManagedObjectContext];

             [backgroundContext performBlock:^{
                 NSManagedObject *backgroundSelf = [backgroundContext objectWithID:objectID];
                 NSError *error = nil;

                 NSArray *updatedObjects = [backgroundSelf updateObjectsForRelationship:relationship
                                                                         withJSONObject:JSONObject
                                                                                fromURL:URL
                                                                 deleteEveryOtherObject:deleteEveryOtherObject
                                                                                  error:&error];

                 NSManagedObjectContext *mainThreadContext = [self.class mainThreadManagedObjectContext];
                 [mainThreadContext performBlock:^(NSArray *objects) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                     if (completionHandler) {
                         completionHandler(objects, error);
                     }
                 } withObject:updatedObjects];
             }];
         }
     }];
}

- (void)postToURL:(NSURL *)URL completionHandler:(void (^)(id JSONObject, NSError *error))completionHandler
{
    if (self.isInserted || self.hasChanges) {
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error while saving: %@", saveError);
    }

    NSDictionary *rawJSONDictionary = self.rawJSONDictionary;

    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidStartNotification object:nil];

    NSString *jsonPrefix = [NSClassFromString(self.entity.name) objectDescription].jsonPrefix;
    if (jsonPrefix) {
        [[self.class backgroundQueue] registerRequestObjectTransformerForNextRequest:^id(id object) {
            return @{ jsonPrefix: object };
        }];
    }

    [[self.class backgroundQueue] postJSONObject:rawJSONDictionary
                                           toURL:[URL URLBySubstitutingAttributesWithManagedObject:self]
                               completionHandler:^(id JSONObject, NSError *error) {
                                   if (error) {
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                                       if (completionHandler) {
                                           completionHandler(self, error);
                                       }
                                   } else {
                                       NSManagedObjectID *objectID = self.objectID;

                                       NSManagedObjectContext *context = [self.class backgroundThreadManagedObjectContext];
                                       [context performBlock:^{
                                           NSManagedObject *backgroundSelf = [context objectWithID:objectID];
                                           if (backgroundSelf.managedObjectContext && !backgroundSelf.isDeleted) {
                                               [backgroundSelf updateWithRawJSONDictionary:JSONObject relationshipUpdateLevel:[[self class] objectDescription].relationshipUpdateLevel];
                                           }

                                           NSError *saveError = nil;
                                           [context save:&saveError];
                                           NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                                           dispatch_async(dispatch_get_main_queue(), ^(void) {
                                               [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                                               if (completionHandler) {
                                                   completionHandler(self, nil);
                                               }
                                           });
                                       }];
                                   }
                               }];
}

- (void)putToURL:(NSURL *)URL completionHandler:(void (^)(id JSONObject, NSError *error))completionHandler
{
    if (self.isInserted || self.hasChanges) {
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error while saving: %@", saveError);
    }

    NSDictionary *rawJSONDictionary = self.rawJSONDictionary;

    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidStartNotification object:nil];

    NSString *jsonPrefix = [NSClassFromString(self.entity.name) objectDescription].jsonPrefix;
    if (jsonPrefix) {
        [[self.class backgroundQueue] registerRequestObjectTransformerForNextRequest:^id(id object) {
            return @{ jsonPrefix: object };
        }];
    }

    [[self.class backgroundQueue] putJSONObject:rawJSONDictionary
                                          toURL:[URL URLBySubstitutingAttributesWithManagedObject:self]
                              completionHandler:^(id JSONObject, NSError *error) {
                                  if (error) {
                                      [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                                      if (completionHandler) {
                                          completionHandler(self, error);
                                      }
                                  } else {
                                      NSManagedObjectID *objectID = self.objectID;

                                      NSManagedObjectContext *context = [self.class backgroundThreadManagedObjectContext];
                                      [context performBlock:^{
                                          NSManagedObject *backgroundSelf = [context objectWithID:objectID];
                                          if (backgroundSelf.managedObjectContext && !backgroundSelf.isDeleted) {
                                            [backgroundSelf updateWithRawJSONDictionary:JSONObject relationshipUpdateLevel:[[self class] objectDescription].relationshipUpdateLevel];
                                          }

                                          NSError *saveError = nil;
                                          [context save:&saveError];

                                          dispatch_async(dispatch_get_main_queue(), ^(void) {
                                              [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                                              if (completionHandler) {
                                                  completionHandler(self, saveError);
                                              }
                                          });
                                      }];
                                  }
                              }];
}

- (void)deleteToURL:(NSURL *)URL completionHandler:(void (^)(NSError *error))completionHandler
{
    URL = [URL URLBySubstitutingAttributesWithManagedObject:self];
    NSDictionary *rawJSONDictionary = self.rawJSONDictionary;
    Class class = self.class;

    NSManagedObjectContext *context = self.managedObjectContext;
    [context deleteObject:self];

    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidStartNotification object:nil];

    [[self.class backgroundQueue] deleteRequestToURL:URL completionHandler:^(NSError *error) {
        if (error) {
            NSManagedObjectContext *backgroundContext = [class backgroundThreadManagedObjectContext];
            [backgroundContext performBlock:^{
                [class updatedObjectWithRawJSONDictionary:rawJSONDictionary inManagedObjectContext:backgroundContext];

                NSError *saveError = nil;
                [backgroundContext save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

                    if (completionHandler) {
                        completionHandler(error);
                    }
                });
            }];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SLRESTfulCoreDataRemoteOperationDidFinishNotification object:nil];

            if (completionHandler) {
                completionHandler(saveError);
            }
        }
    }];
}

- (void)updateWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (self.isInserted || self.hasChanges) {
        NSError *saveError = nil;
        [self.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error while saving: %@", saveError);
    }

    NSURL *CRUDBaseURL = [self.class objectDescription].CRUDBaseURL;
    NSParameterAssert(CRUDBaseURL);

    CRUDBaseURL = [CRUDBaseURL URLByAppendingPathComponent:[@":" stringByAppendingString:[[self.class objectDescription] uniqueIdentifierOfJSONObjects]]];
    CRUDBaseURL = [CRUDBaseURL URLBySubstitutingAttributesWithManagedObject:self];

    [self.class fetchObjectFromURL:CRUDBaseURL completionHandler:completionHandler];
}

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSURL *CRUDBaseURL = [self.class objectDescription].CRUDBaseURL;
    NSParameterAssert(CRUDBaseURL);

    [self postToURL:CRUDBaseURL completionHandler:completionHandler];
}

- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSURL *CRUDBaseURL = [self.class objectDescription].CRUDBaseURL;
    NSParameterAssert(CRUDBaseURL);

    CRUDBaseURL = [CRUDBaseURL URLByAppendingPathComponent:[@":" stringByAppendingString:[[self.class objectDescription] uniqueIdentifierOfJSONObjects]]];

    [self putToURL:CRUDBaseURL completionHandler:completionHandler];
}

- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSURL *CRUDBaseURL = [self.class objectDescription].CRUDBaseURL;
    NSParameterAssert(CRUDBaseURL);

    CRUDBaseURL = [CRUDBaseURL URLByAppendingPathComponent:[@":" stringByAppendingString:[[self.class objectDescription] uniqueIdentifierOfJSONObjects]]];
    
    [self deleteToURL:CRUDBaseURL completionHandler:completionHandler];
}

@end
