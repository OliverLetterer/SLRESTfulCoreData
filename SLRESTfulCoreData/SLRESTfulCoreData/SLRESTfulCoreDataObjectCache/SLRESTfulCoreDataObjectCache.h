//
//  SLRESTfulCoreDataObjectCache.h
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 31.07.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import <CoreData/CoreData.h>


/**
 @abstract  <#abstract comment#>
 */
@interface SLRESTfulCoreDataObjectCache : NSObject

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

- (id)objectOfClass:(Class)class withRemoteIdentifier:(id)identifier;
- (NSDictionary *)indexedObjectsOfClass:(Class)class withRemoteIdentifiers:(NSSet *)identifiers;

- (void)prepopulateCacheWithObjects:(NSSet *)managedObjects;

@end



/**
 @abstract  Singleton category
 */
@interface SLRESTfulCoreDataObjectCache (Singleton)

+ (SLRESTfulCoreDataObjectCache *)sharedCacheForManagedObjectContext:(NSManagedObjectContext *)context;

@end
