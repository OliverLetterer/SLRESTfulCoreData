//
//  SLRESTfulCoreData.h
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

#import "NSArray+SLRESTfulCoreData.h"
#import "NSError+SLRESTfulCoreData.h"
#import "NSString+SLRESTfulCoreData.h"
#import "NSURL+SLRESTfulCoreData.h"

#import "NSManagedObject+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataQueryInterface.h"
#import "NSManagedObject+SLRESTfulCoreDataSetup.h"
#import "NSManagedObject+SLRESTfulCoreDataHelpers.h"

#import "NSManagedObjectContext+SLRESTfulCoreData.h"

#import "SLAttributeMapping.h"
#import "SLObjectConverter.h"
#import "SLObjectDescription.h"
#import "SLRESTfulCoreDataBackgroundQueue.h"

#import "SLBlockValueTransformer.h"
#import "SLJSONStringValueTransformer.h"
#import "SLIdentityValueTransformer.h"
#import "SLRGBHexStringValueTransformer.h"

extern NSString *const SLRESTfulCoreDataRemoteOperationDidStartNotification;
extern NSString *const SLRESTfulCoreDataRemoteOperationDidFinishNotification;

static inline NSArray *SLRESTfulCoreDataManagedObjectIDCollector(NSArray *objects)
{
    return [objects SLArrayByCollectionObjectsWithCollector:^id(id object, NSUInteger index, BOOL *stop) {
        if ([object isKindOfClass:[NSArray class]]) {
            return SLRESTfulCoreDataManagedObjectIDCollector(object);
        } else if ([object isKindOfClass:[NSManagedObject class]]) {
            return [(NSManagedObject *)object objectID];
        }
        
        NSCAssert(NO, @"%@ is unsupported by SLRESTfulCoreDataManagedObjectIDCollector", object);
        return nil;
    }];
}

static inline NSArray *SLRESTfulCoreDataManagedObjectCollector(NSArray *objectIDs, NSManagedObjectContext *context)
{
    return [objectIDs SLArrayByCollectionObjectsWithCollector:^id(id object, NSUInteger index, BOOL *stop) {
        if ([object isKindOfClass:[NSArray class]]) {
            return SLRESTfulCoreDataManagedObjectCollector(object, context);
        } else if ([object isKindOfClass:[NSManagedObjectID class]]) {
            return [context objectWithID:object];
        }
        
        NSCAssert(NO, @"%@ is unsupported by SLRESTfulCoreDataManagedObjectIDCollector", object);
        return nil;
    }];
}
