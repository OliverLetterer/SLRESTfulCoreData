//
//  SLObjectDescription.m
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

#import "SLObjectDescription.h"
#import "NSManagedObject+SLRESTfulCoreDataSetup.h"
#import "NSManagedObject+SLRESTfulCoreData.h"
#import <objc/runtime.h>

char *const SLObjectDescriptionDefaultUniqueIdentifierOfJSONObjectsKey;

static void mergeDictionaries(NSMutableDictionary *mainDictionary, NSDictionary *otherDictionary)
{
    for (id key in otherDictionary) {
        if (!mainDictionary[key]) {
            mainDictionary[key] = otherDictionary[key];
        }
    }
}



@interface SLObjectDescription () {
    
}

@property (nonatomic, copy) NSString *managedObjectClassName;

@property (nonatomic, strong) NSMutableDictionary *CRUDBaseURLs;
@property (nonatomic, readonly) NSDictionary *mergedCRUDBaseURLs;

@end



@implementation SLObjectDescription

#pragma mark - setters and getters

- (NSDictionary *)mergedCRUDBaseURLs
{
    NSMutableDictionary *mergedCRUDBaseURLs = self.CRUDBaseURLs.mutableCopy;
    Class managedObjectClass = [NSClassFromString(self.managedObjectClassName) superclass];
    
    while ([[managedObjectClass class] isSubclassOfClass:[NSManagedObject class]] && [managedObjectClass class] != [NSManagedObject class]) {
        mergeDictionaries(mergedCRUDBaseURLs, [managedObjectClass objectDescription].CRUDBaseURLs);
        managedObjectClass = [managedObjectClass superclass];
    }
    
    return mergedCRUDBaseURLs;
}

#pragma mark - Initialization

- (id)initWithManagedObjectClassName:(NSString *)managedObjectClassName
{
    if (self = [super init]) {
        _managedObjectClassName = managedObjectClassName;
        
        self.uniqueIdentifierOfJSONObjects = [self.class defaultUniqueIdentifierOfJSONObjects];
        self.CRUDBaseURLs = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    
}

#pragma mark - Instance methods

+ (void)setDefaultUniqueIdentifierOfJSONObjects:(NSString *)uniqueIdentifierOfJSONObjects
{
    objc_setAssociatedObject(self, &SLObjectDescriptionDefaultUniqueIdentifierOfJSONObjectsKey,
                             uniqueIdentifierOfJSONObjects, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSString *)defaultUniqueIdentifierOfJSONObjects
{
    return objc_getAssociatedObject(self, &SLObjectDescriptionDefaultUniqueIdentifierOfJSONObjectsKey) ?: @"id";
}

- (void)registerCRUDBaseURL:(NSURL *)CRUDBaseURL forRelationship:(NSString *)relationship
{
    NSParameterAssert(CRUDBaseURL);
    NSParameterAssert(relationship);
    
    self.CRUDBaseURLs[relationship] = CRUDBaseURL;
}

- (NSURL *)CRUDBaseURLForRelationship:(NSString *)relationship
{
    NSParameterAssert(relationship);
    
    NSURL *CRUDBaseURL = self.mergedCRUDBaseURLs[relationship];
    
    if (CRUDBaseURL) {
        return CRUDBaseURL;
    }
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:_managedObjectClassName
                                                         inManagedObjectContext:[NSClassFromString(_managedObjectClassName) mainThreadManagedObjectContext]];
    NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[relationship];
    
    Class class = NSClassFromString(relationshipDescription.destinationEntity.managedObjectClassName);
    CRUDBaseURL = [class objectDescription].CRUDBaseURL;
    
    return [self _relationshipCRUDBaseURLFromObjectCRUDBaseURL:CRUDBaseURL];
}

#pragma mark - Private category implementation ()

- (NSURL *)_relationshipCRUDBaseURLFromObjectCRUDBaseURL:(NSURL *)CRUDURL
{
    NSString *string = CRUDURL.relativeString;
    
    if (!string) {
        return nil;
    }
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@":[a-z]([a-zA-Z_0-9\\.])+"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:NULL];
    
    NSMutableDictionary *substitutionDictionary = [NSMutableDictionary dictionary];
    
    [regularExpression enumerateMatchesInString:string
                                        options:0
                                          range:NSMakeRange(0, string.length)
                                     usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                         NSString *matchingString = [string substringWithRange:result.range];
                                         NSString *keyPath = [matchingString substringFromIndex:1];
                                         NSMutableArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."].mutableCopy;
                                         
                                         keyPathComponents[0] = @"self";
                                         substitutionDictionary[matchingString] = [NSString stringWithFormat:@":%@", [keyPathComponents componentsJoinedByString:@"."]];
                                     }];
    
    NSMutableString *finalURLString = string.mutableCopy;
    [substitutionDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [finalURLString replaceOccurrencesOfString:key
                                        withString:[NSString stringWithFormat:@"%@", obj]
                                           options:NSLiteralSearch
                                             range:NSMakeRange(0, finalURLString.length)];
    }];
    
    return [NSURL URLWithString:finalURLString];
}

@end
