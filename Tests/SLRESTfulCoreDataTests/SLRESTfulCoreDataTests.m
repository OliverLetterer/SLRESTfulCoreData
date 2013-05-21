//
//  SLRESTfulCoreDataTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"
#import "SLRESTfulCoreData.h"



__attribute__((constructor))
void SLRESTfulCoreDataTestsInitialize(void)
{
    [NSManagedObject registerDefaultMainThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    }];
    
    [NSManagedObject registerDefaultBackgroundThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestDataStore sharedInstance].backgroundThreadManagedObjectContext;
    }];
}



@implementation SLTestDataStore

- (NSString *)managedObjectModelName
{
    return @"TestDataStore";
}

@end



@implementation SLTestBackgroundQueue

+ (id<SLRESTfulCoreDataBackgroundQueue>)sharedQueue
{
    [NSException raise:NSInternalInconsistencyException format:@"%@ does not recognize selector %@", self, NSStringFromSelector(_cmd)];
    return nil;
}

- (void)getRequestToURL:(NSURL *)URL
      completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)deleteRequestToURL:(NSURL *)URL
         completionHandler:(void(^)(NSError *error))completionHandler
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)postJSONObject:(id)JSONObject
                 toURL:(NSURL *)URL
     completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)putJSONObject:(id)JSONObject
                toURL:(NSURL *)URL
    completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    [self doesNotRecognizeSelector:_cmd];
}

@end
