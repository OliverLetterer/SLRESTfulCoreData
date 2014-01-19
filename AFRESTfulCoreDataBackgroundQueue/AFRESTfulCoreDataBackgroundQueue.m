//
//  AFRESTfulCoreDataBackgroundQueue.m
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

#import "AFRESTfulCoreDataBackgroundQueue.h"
#import <objc/message.h>
#import <objc/runtime.h>



@implementation AFRESTfulCoreDataBackgroundQueue

#pragma mark - AFHTTPClient

- (instancetype)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        self.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:0];
        self.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:0];

        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        self.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    }
    return self;
}

#pragma mark - SLRESTfulCoreDataBackgroundQueue

+ (id<SLRESTfulCoreDataBackgroundQueue>)sharedQueue
{
    NSAssert([self class] != [AFRESTfulCoreDataBackgroundQueue sharedQueue], @"AFRESTfulCoreDataBackgroundQueue is an abstract superclass. You need to subclass this class and implement +[YouSubclass sharedInstance].");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

    if (class_respondsToSelector(objc_getMetaClass(class_getName([self class])), @selector(sharedInstance))) {
        return ((id(*)(id, SEL))objc_msgSend)([self class], @selector(sharedInstance));
    }

#pragma clang diagnostic pop

    [NSException raise:NSInternalInconsistencyException format:@"You need to implement +[%@ sharedInstance] and return a singleton instance there in order for AFRESTfulCoreDataBackgroundQueue to work.", NSStringFromClass(self)];

    return nil;
}

- (void)getRequestToURL:(NSURL *)URL
      completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    NSString *URLString = URL.absoluteString;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:NULL];

    NSString *key = [self _responseObjectTransformerKey];
    SLRESTfulCoreDataBackgroundQueueObjectTransformer responseObjectTransformer = [NSThread currentThread].threadDictionary[key];
    [[NSThread currentThread].threadDictionary removeObjectForKey:key];

    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completionHandler) {
            completionHandler(responseObjectTransformer ? responseObjectTransformer(responseObject) : responseObject, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];

    [self.operationQueue addOperation:requestOperation];
}

- (void)deleteRequestToURL:(NSURL *)URL
         completionHandler:(void(^)(NSError *error))completionHandler
{
    NSString *URLString = URL.absoluteString;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:NULL];

    NSDictionary *JSONObject = @{};
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:NULL];

    [request setHTTPBody:JSONData];
    [request setValue:[NSString stringWithFormat:@"%d", JSONData.length] forHTTPHeaderField:@"Content-Length"];

    AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completionHandler) {
            completionHandler(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];

    [self.operationQueue addOperation:requestOperation];
}

- (void)postJSONObject:(id)JSONObject
                 toURL:(NSURL *)URL
     completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    [self postJSONObject:JSONObject toURL:URL withSetupHandler:NULL completionHandler:completionHandler];
}

- (void)postJSONObject:(id)JSONObject
                 toURL:(NSURL *)URL
      withSetupHandler:(void(^)(NSMutableURLRequest *request))setupHandler
     completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    JSONObject = JSONObject ?: @{};

    SLRESTfulCoreDataBackgroundQueueObjectTransformer requestObjectTransformer = ({
        NSString *key = [self _requestObjectTransformerKey];

        SLRESTfulCoreDataBackgroundQueueObjectTransformer objectTransformer = [NSThread currentThread].threadDictionary[key];
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];

        objectTransformer;
    });

    if (requestObjectTransformer) {
        JSONObject = requestObjectTransformer(JSONObject);
    }

    NSString *URLString = URL.absoluteString;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:NULL];

    NSError *error = nil;
    NSData *JSONData = [NSData data];

    if (JSONObject) {
        JSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&error];
    }

    NSString *key = [self _responseObjectTransformerKey];
    SLRESTfulCoreDataBackgroundQueueObjectTransformer responseObjectTransformer = [NSThread currentThread].threadDictionary[key];
    [[NSThread currentThread].threadDictionary removeObjectForKey:key];

    if (error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    } else {
        [request setHTTPBody:JSONData];
        [request setValue:[NSString stringWithFormat:@"%d", JSONData.length] forHTTPHeaderField:@"Content-Length"];

        if (setupHandler) {
            setupHandler(request);
        }

        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (completionHandler) {
                completionHandler(responseObjectTransformer ? responseObjectTransformer(responseObject) : responseObject, nil);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }];

        [self.operationQueue addOperation:requestOperation];
    }
}

- (void)putJSONObject:(id)JSONObject
                toURL:(NSURL *)URL
    completionHandler:(void(^)(id JSONObject, NSError *error))completionHandler
{
    JSONObject = JSONObject ?: @{};

    SLRESTfulCoreDataBackgroundQueueObjectTransformer requestObjectTransformer = ({
        NSString *key = [self _requestObjectTransformerKey];

        SLRESTfulCoreDataBackgroundQueueObjectTransformer objectTransformer = [NSThread currentThread].threadDictionary[key];
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];

        objectTransformer;
    });

    if (requestObjectTransformer) {
        JSONObject = requestObjectTransformer(JSONObject);
    }

    NSString *URLString = URL.absoluteString;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:NULL];

    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:&error];

    SLRESTfulCoreDataBackgroundQueueObjectTransformer responseObjectTransformer = ({
        NSString *key = [self _responseObjectTransformerKey];

        SLRESTfulCoreDataBackgroundQueueObjectTransformer objectTransformer = [NSThread currentThread].threadDictionary[key];
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];

        objectTransformer;
    });

    if (error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    } else {
        [request setHTTPBody:JSONData];

        AFHTTPRequestOperation *requestOperation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (completionHandler) {
                completionHandler(responseObjectTransformer ? responseObjectTransformer(responseObject) : responseObject, nil);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }];

        [self.operationQueue addOperation:requestOperation];
    }
}

- (void)registerResponseObjectTransformerForNextRequest:(SLRESTfulCoreDataBackgroundQueueObjectTransformer)responseObjectTransformer
{
    NSParameterAssert(responseObjectTransformer);

    NSString *key = [self _responseObjectTransformerKey];

    if (![NSThread currentThread].threadDictionary[key]) {
        [NSThread currentThread].threadDictionary[key] = responseObjectTransformer;
    }
}

- (void)registerRequestObjectTransformerForNextRequest:(SLRESTfulCoreDataBackgroundQueueObjectTransformer)requestObjectTransformer
{
    NSParameterAssert(requestObjectTransformer);

    NSString *key = [self _requestObjectTransformerKey];

    if (![NSThread currentThread].threadDictionary[key]) {
        [NSThread currentThread].threadDictionary[key] = requestObjectTransformer;
    }
}

#pragma mark - Private method implementation ()

- (NSString *)_responseObjectTransformerKey
{
    return [NSString stringWithFormat:@"%@ResponseObjectTransformerKey", NSStringFromClass(self.class)];
}

- (NSString *)_requestObjectTransformerKey
{
    return [NSString stringWithFormat:@"%@RequestObjectTransformerKey", NSStringFromClass(self.class)];
}

@end
