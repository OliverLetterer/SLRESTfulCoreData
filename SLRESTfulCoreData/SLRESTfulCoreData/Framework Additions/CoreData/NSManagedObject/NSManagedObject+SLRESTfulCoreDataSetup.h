//
//  NSManagedObject+SLRESTfulCoreDataSetup.h
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

#import <CoreData/CoreData.h>

@class SLAttributeMapping, SLObjectConverter, SLObjectDescription;



@interface NSManagedObject (SLRESTfulCoreDataSetup)

/**
 Returns a unique instance for each subclass.
 */
+ (SLAttributeMapping *)attributeMapping;

/**
 Returns a unique instance for each subclass.
 */
+ (SLObjectConverter *)objectConverter;

/**
 Object containing description for this NSManagedObjects subclass
 */
+ (SLObjectDescription *)objectDescription;

/**
 Registers a mapping between a CoreData attribute and a corresponding key path of a JSON object, with which this object will be updated.
 The default lookup is attributeName.
 
 @warning: Call in +[NSManagedObjectSubclass initialize].
 */
+ (void)registerAttributeName:(NSString *)attributeName
         forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath;

/**
 Calls +[NSManagedObject registerAttributeName:key forJSONObjectKeyPath:value] for each key value pair in `attributeMapping`.
 */
+ (void)registerAttributeMapping:(NSDictionary *)attributeMapping;

/**
 Excludes attribute name from JSON object mapping an causes attributeName to not be set in updateWithRawJSONDictionary:.
 */
+ (void)unregisterAttributeName:(NSString *)attributeName;

/**
 Register a CRUD base URL for a given relationship.
 
 SLRESTfulCoreData implements a dynamic getter for each relationship at runtime.
 For an Entity Entity1 which has a has_many relationship with Entity2 named `entities`, the SLRESTfulCoreData runtime will implement a method
 -[Entity1 entitiesWithCompletionHandler:] which will be implemented as
 
 - (void)entitiesWithCompletionHandler:(void(^)(NSArray *entities, NSError *error))completionHandler
 {
 [self fetchObjectsForRelationship:@"entities" fromURL:CRUDBaseURL completionHandler:completionHandler];
 }
 
 if you don't call this method, the default CRUDBaseURL of the destination entity (Entity2 in the above example) will be used.
 
 SLRESTfulCoreData also creates `addEntitiesObject:withCompletionHandler:` and `deleteEntitiesObject:withCompletionHandler:`, which will POST or DELETE the corresponding entity.
 */
+ (void)registerCRUDBaseURL:(NSURL *)CRUDBaseURL forRelationship:(NSString *)relationship;

/**
 base URL for all default CRUD operations.
 
 Example: if CRUDBaseURL is equal to http://0.0.0.0:3000/api/objects/:object.id/childs, the runtime will provide the following generated methods for you:
 
 -[NSManagedObject updateWithCompletionHandler:]    => GET      http://0.0.0.0:3000/api/objects/:object.id/childs/:id
 -[NSManagedObject createWithCompletionHandler:]    => POST     http://0.0.0.0:3000/api/objects/:object.id/childs
 -[NSManagedObject saveWithCompletionHandler:]      => PUT      http://0.0.0.0:3000/api/objects/:object.id/childs/:id
 -[NSManagedObject deleteWithCompletionHandler:]    => DELETE   http://0.0.0.0:3000/api/objects/:object.id/childs/:id
 */
+ (void)registerCRUDBaseURL:(NSURL *)CRUDBaseURL;

/**
 Registers a custom subclass for a value of an attribute.
 */
+ (void)registerSubclass:(Class)subclass forManagedObjectAttributeName:(NSString *)managedObjectAttributeName withValue:(id)value;

/**
 Registers a NSValueTransformer for a managed object attribute name which will be used for converting `transformable` attributes to and from a JSON object.
 
 `transformedValue:` must transform a value from a json object to a core data object.
 `reverseTransformedValue:` must transform a value from a core data object to a json object.
 */
+ (void)registerValueTransformer:(NSValueTransformer *)valueTransformer forManagedObjectAttributeName:(NSString *)managedObjectAttributeName;

/**
 Registers a naming convention. Registering identifier with id will cause all _id_ appearences to be replaced with _identifier_. printer_id will then be automatically converted into printerIdentifier.
 */
+ (void)registerObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention;

/**
 Changes the default key, under which the unique identifier in a json object can be found. default is @"id".
 */
+ (void)registerUniqueIdentifierOfJSONObjects:(NSString *)uniqueIdentifier;

/**
 Registers the timezone in which the API returns dates for this object.
 */
+ (void)registerTimezone:(NSTimeZone *)timezone;

@end
