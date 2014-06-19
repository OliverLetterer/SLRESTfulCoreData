//
//  SLRESTfulCoreDataObjectCache.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 31.07.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataObjectCache.h"
#import "SLAttributeMapping.h"
#import "SLObjectConverter.h"
#import "SLObjectDescription.h"

#import "NSManagedObject+SLRESTfulCoreDataSetup.h"
#import "NSManagedObject+SLRESTfulCoreDataHelpers.h"

#import <objc/runtime.h>

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



@implementation NSManagedObject (SLRESTfulCoreDataObjectCache)

+ (void)load
{
    class_swizzleSelector(self, @selector(prepareForDeletion), @selector(__SLRESTfulCoreDataObjectCachePrepareForDeletion));
}

- (void)__SLRESTfulCoreDataObjectCachePrepareForDeletion
{
    [self __SLRESTfulCoreDataObjectCachePrepareForDeletion];

    [[SLRESTfulCoreDataObjectCache sharedCacheForManagedObjectContext:self.managedObjectContext] removeManagedObject:self];
}

@end

@interface SLRESTfulCoreDataObjectCache ()

@property (nonatomic, strong) NSCache *internalCache;

@end





@implementation SLRESTfulCoreDataObjectCache

#pragma mark - Initialization

- (NSCache *)internalCache
{
    if (!_internalCache) {
        _internalCache = [[NSCache alloc] init];
    }

    return _internalCache;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    if (self = [super init]) {
        _managedObjectContext = context;
    }
    return self;
}

- (id)objectOfClass:(Class)class withRemoteIdentifier:(id)identifier
{
    if (!identifier) {
        return nil;
    }

    while ([class class] != class) {
        class = [class class];
    }

    NSString *cachedKey = [self _cachedKeyForClass:class withRemoteIdentifier:identifier];
    id cachedManagedObject = [self.internalCache objectForKey:cachedKey];

    if (cachedManagedObject) {
        return cachedManagedObject;
    }

    NSAssert([class isSubclassOfClass:[NSManagedObject class]], @"class %@ must be a subclass of NSManagedObject", class);
    NSManagedObjectContext *context = self.managedObjectContext;

    SLAttributeMapping *attributeMapping = [class attributeMapping];
    SLObjectConverter *objectConverter = [class objectConverter];

    NSString *uniqueKeyForJSONDictionary = [class objectDescription].uniqueIdentifierOfJSONObjects;
    NSString *managedObjectUniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];

    id managedObjectID = [objectConverter managedObjectObjectFromJSONObjectObject:identifier
                                                        forManagedObjectAttribute:managedObjectUniqueKey];

    if (!managedObjectID) {
        return nil;
    }

    NSAssert([[class registeredAttributeNames] containsObject:managedObjectUniqueKey], @"no unique key attribute found to %@. tried to map %@ to %@", class, uniqueKeyForJSONDictionary, managedObjectUniqueKey);
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:context];
    NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectUniqueKey];

    NSAssert(attributeDescription != nil, @"no attributeDescription found for %@[%@]", class, managedObjectUniqueKey);

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(class)];

    if (attributeDescription.attributeType == NSStringAttributeType) {
        request.predicate = [NSPredicate predicateWithFormat:@"%K LIKE %@", managedObjectUniqueKey, managedObjectID];
    } else {
        request.predicate = [NSPredicate predicateWithFormat:@"%K == %@", managedObjectUniqueKey, managedObjectID];
    }

    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);

    if (objects.count > 0) {
        NSManagedObject *managedObject = objects.firstObject;

        [self.internalCache setObject:managedObject forKey:cachedKey];
        return objects.firstObject;
    }

    return nil;
}

- (NSDictionary *)indexedObjectsOfClass:(Class)class withRemoteIdentifiers:(NSSet *)identifiers
{
    if (identifiers.count == 0) {
        return @{};
    }

    while ([class class] != class) {
        class = [class class];
    }

    NSMutableDictionary *indexedObjects = [NSMutableDictionary dictionaryWithCapacity:identifiers.count];
    NSMutableSet *identifiersToFetch = [NSMutableSet setWithCapacity:identifiers.count];

    for (id identifier in identifiers) {
        NSString *key = [self _cachedKeyForClass:class withRemoteIdentifier:identifier];

        id cachedObject = [self.internalCache objectForKey:key];

        if (cachedObject) {
            indexedObjects[identifier] = cachedObject;
        } else {
            [identifiersToFetch addObject:identifier];
        }
    }

    NSAssert([class isSubclassOfClass:[NSManagedObject class]], @"class %@ must be a subclass of NSManagedObject", class);
    NSManagedObjectContext *context = self.managedObjectContext;

    SLAttributeMapping *attributeMapping = [class attributeMapping];

    NSString *uniqueKeyForJSONDictionary = [class objectDescription].uniqueIdentifierOfJSONObjects;
    NSString *managedObjectUniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(class) inManagedObjectContext:context];
    __unused NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectUniqueKey];

    NSAssert(attributeDescription != nil, @"no attributeDescription found for %@[%@]", class, managedObjectUniqueKey);

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(class)];
    request.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", managedObjectUniqueKey, identifiersToFetch];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);

    for (NSManagedObject *managedObject in fetchedObjects) {
        id identifier = [managedObject valueForKey:managedObjectUniqueKey];
        NSString *cacheKey = [self _cachedKeyForClass:class withRemoteIdentifier:identifier];

        [self.internalCache setObject:managedObject forKey:cacheKey];

        indexedObjects[identifier] = managedObject;
    }

    return [indexedObjects copy];
}

- (void)prepopulateCacheWithObjects:(NSSet *)managedObjects
{
    NSMutableDictionary *uniqueKeyCache = [NSMutableDictionary dictionary];

    for (NSManagedObject *object in managedObjects) {
        Class class = NSClassFromString(object.entity.name);
        NSString *uniqueKey = uniqueKeyCache[object.entity.name];

        if (!uniqueKey) {
            SLAttributeMapping *attributeMapping = [class attributeMapping];

            NSString *uniqueKeyForJSONDictionary = [class objectDescription].uniqueIdentifierOfJSONObjects;
            uniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];

            uniqueKeyCache[object.entity.name] = uniqueKey;
        }

        id identifier = [object valueForKey:uniqueKey];
        if (identifier && object) {
            NSString *cacheKey = [self _cachedKeyForClass:class withRemoteIdentifier:identifier];
            [self.internalCache setObject:object forKey:cacheKey];
        }
    }
}

- (void)removeManagedObject:(NSManagedObject *)managedObject
{
    Class class = NSClassFromString(managedObject.entity.name);
    NSParameterAssert(class);

    SLAttributeMapping *attributeMapping = [class attributeMapping];

    NSString *uniqueKeyForJSONDictionary = [class objectDescription].uniqueIdentifierOfJSONObjects;
    NSString *uniqueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:uniqueKeyForJSONDictionary];

    if (![managedObject respondsToSelector:NSSelectorFromString(uniqueKey)]) {
        return;
    }

    id identifier = [managedObject valueForKey:uniqueKey];

    NSString *cachedKey = [self _cachedKeyForClass:class withRemoteIdentifier:identifier];
    [self.internalCache removeObjectForKey:cachedKey];
}

#pragma mark - Private category implementation ()

- (NSString *)_cachedKeyForClass:(Class)class withRemoteIdentifier:(id)identifier
{
    while ([class class] != class) {
        class = [class class];
    }

    return [NSString stringWithFormat:@"%@#%@", NSStringFromClass(class), identifier];
}

@end



#pragma mark - Singleton implementation

@implementation SLRESTfulCoreDataObjectCache (Singleton)

+ (SLRESTfulCoreDataObjectCache *)sharedCacheForManagedObjectContext:(NSManagedObjectContext *)context
{
    SLRESTfulCoreDataObjectCache *cache = objc_getAssociatedObject(context, _cmd);

    if (!cache) {
        cache = [[SLRESTfulCoreDataObjectCache alloc] initWithManagedObjectContext:context];
        objc_setAssociatedObject(context, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return cache;
}

@end
