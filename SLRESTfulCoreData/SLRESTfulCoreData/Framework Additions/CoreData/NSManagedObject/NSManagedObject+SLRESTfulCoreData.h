//
//  NSManagedObject+SLRESTfulCoreData.h
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

#import "SLRESTfulCoreDataBackgroundQueue.h"
#import <CoreData/CoreData.h>

@class SLAttributeMapping, SLObjectConverter;

typedef NSManagedObjectContext *(^SLRESTfulCoreDataManagedObjectContextBlock)(void);



@interface NSManagedObject (SLRESTfulCoreData)

/**
 @warning: You need to overwrite this method and return an NSManagedObjectContext for the main thread here.
 */
+ (NSManagedObjectContext *)mainThreadManagedObjectContext;
+ (SLRESTfulCoreDataManagedObjectContextBlock)defaultMainThreadManagedObjectContextAction;
+ (void)registerDefaultMainThreadManagedObjectContextWithAction:(SLRESTfulCoreDataManagedObjectContextBlock)action;

/**
 @warning: You need to overwrite this method and return an NSManagedObjectContext for a background thread here, which will perform all the heavy lifting.
 */
+ (NSManagedObjectContext *)backgroundThreadManagedObjectContext;
+ (SLRESTfulCoreDataManagedObjectContextBlock)defaultBackgroundThreadManagedObjectContextAction;
+ (void)registerDefaultBackgroundThreadManagedObjectContextWithAction:(SLRESTfulCoreDataManagedObjectContextBlock)action;

/**
 By default, this methods looks for a class which name starts with this classes prefix and end with BackgoundQueue.
 
 TTEntity1 will look for a background queue TTBackgroundQueue. Overwrite for custom behaviour.
 */
+ (id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue;

/**
 Sets a default background queue which will be returned from `+[NSManagedObject backgroundQueue]`.
 */
+ (void)setDefaultBackgroundQueue:(id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue;

/**
 Searches for an existing entity with id given in dictionary and updates attributes or created new one with given attributes.
 */
+ (instancetype)updatedObjectWithRawJSONDictionary:(NSDictionary *)rawDictionary
                            inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Updates the actual instance with the given JSON dictionary;
 */
- (void)updateWithRawJSONDictionary:(NSDictionary *)dictionary;

/**
 converts self into a JSON object.
 */
- (NSDictionary *)rawJSONDictionary;

/**
 Updates objects of relationship with objects from a JSON object.
 @return The updated objects.
 */
- (NSArray *)updateObjectsForRelationship:(NSString *)relationship
                           withJSONObject:(id)JSONObject
                                  fromURL:(NSURL *)URL
                   deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
                                    error:(NSError **)error;

@end
