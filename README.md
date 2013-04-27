# SLRESTfulCoreData

[![Build Status](https://travis-ci.org/OliverLetterer/SLRESTfulCoreData.png)](https://travis-ci.org/OliverLetterer/SLRESTfulCoreData)

SLRESTfulCoreData let's you map your REST API to your CoreData model in minutes. Checkout [this](http://sparrow-labs.github.io/2013/04/22/introducing_slrestfulcoredata.html) blog post for getting started.

## Getting started

### Providing the necessary data
For SLRESTfulCoreData to work, you need to implement `+[NSManagedObject mainThreadManagedObjectContext]`, `+[NSManagedObject backgroundThreadManagedObjectContext]` and `+[NSManagedObject backgroundQueue]`:

```
+ (NSManagedObjectContext *)mainThreadManagedObjectContext
{
    return <#a NSManagedObjectContext of NSMainQueueConcurrencyType type#>;
}

+ (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    return <#a NSManagedObjectContext of NSPrivateQueueConcurrencyType type#>;
}

+ (id<SLRESTfulCoreDataBackgroundQueue>)backgroundQueue
{
    return <#an instance conforming to SLRESTfulCoreDataBackgroundQueue#>;
}
```

* For a quick start, check out [CTDataStoreManager](https://github.com/ebf/CTDataStoreManager) for an easy way to provide these NSManagedObjectContext instances and the [GitHubAPI Sample project](https://github.com/OliverLetterer/GitHubAPI) on how to implement the background queue conforming to:

```
@protocol SLRESTfulCoreDataBackgroundQueue <NSObject>

+ (id<SLRESTfulCoreDataBackgroundQueue>)sharedQueue;

/**
 Sends a get request to a given URL.
 */
- (void)getRequestToURL:(NSURL *)URL
      completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler;

- (void)deleteRequestToURL:(NSURL *)URL
         completionHandler:(void(^)(NSError *error))completionHandler;

- (void)postJSONObject:(id)JSONObject
                 toURL:(NSURL *)URL
     completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler;

- (void)putJSONObject:(id)JSONObject
                toURL:(NSURL *)URL
    completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler;

@end
```

As a convenience, you can also call 

```
[NSManagedObject setDefaultBackgroundQueue:[GHBackgroundQueue sharedInstance]];
        
[NSManagedObject registerDefaultBackgroundThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
	return [GHDataStoreManager sharedInstance].backgroundThreadContext;
}];
        
[NSManagedObject registerDefaultMainThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
	return [GHDataStoreManager sharedInstance].mainThreadContext;
}];
```

in an appropriate place.

### Attribute mappings

