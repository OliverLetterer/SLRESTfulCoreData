//
//  NSManagedObject+SLRESTfulCoreDataQueryInterface.h
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



@interface NSManagedObject (SLRESTfulCoreDataQueryInterface)

/**
 Fetches a single object.
 */
+ (void)fetchObjectFromURL:(NSURL *)URL
         completionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler;

/**
 Calls +[NSManagedObject fetchObjectsFromURL:URL deleteEveryOtherObject:YES completionHandler:completionHandler].
 */
+ (void)fetchObjectsFromURL:(NSURL *)URL
          completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

/**
 Fetches an array of objects or a single object for this class and stores it in core data. URL is expected to return an NSArray with NSDictionaries which contain the JSON object.
 
 @param deleteEveryOtherObject: If YES, each object that is not returned by the API will be deleted from the data base
 */
+ (void)fetchObjectsFromURL:(NSURL *)URL
     deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
          completionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler;

/**
 Calls -[NSManagedObject fetchObjectsForRelationship:relationship fromURL:URL deleteEveryOtherObject:YES completionHandler:completionHandler].
 */
- (void)fetchObjectsForRelationship:(NSString *)relationship
                            fromURL:(NSURL *)URL
                  completionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler;

/**
 Fetches objects from a URL for a given relationship.
 
 URL support substitution of object specific attributes:
 http://0.0.0.0:3000/api/object/:some_id/relationship
 where :some_id will be substituted with the content of the attribute from this self with someID or whatever mapping was specified.
 
 Supported relationships are 1-to-many and 1-to-1.
 */
- (void)fetchObjectsForRelationship:(NSString *)relationship
                            fromURL:(NSURL *)URL
             deleteEveryOtherObject:(BOOL)deleteEveryOtherObject
                  completionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)postToURL:(NSURL *)URL completionHandler:(void (^)(id JSONObject, NSError *error))completionHandler;
- (void)putToURL:(NSURL *)URL completionHandler:(void (^)(id JSONObject, NSError *error))completionHandler;
- (void)deleteToURL:(NSURL *)URL completionHandler:(void (^)(NSError *error))completionHandler;

/**
 CRUD methods available if CRUD base URL has been registered
 */
- (void)updateWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler;

@end
