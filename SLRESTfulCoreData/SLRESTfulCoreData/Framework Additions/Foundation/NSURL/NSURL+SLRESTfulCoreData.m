//
//  NSURL+SLRESTfulCoreData.m
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

#import "SLRESTfulCoreData.h"

@implementation NSURL (SLRESTfulCoreData)

- (NSURL *)URLBySubstitutingAttributesWithManagedObject:(NSManagedObject *)managedObject
{
    NSParameterAssert(managedObject);
    NSString *string = self.relativeString;
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@":[a-z]([a-zA-Z_0-9\\.])+"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:NULL];
    
    NSMutableDictionary *substitutionDictionary = [NSMutableDictionary dictionary];
    
    [regularExpression enumerateMatchesInString:string
                                        options:0
                                          range:NSMakeRange(0, string.length)
                                     usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                         SLObjectConverter *objectConverter = [managedObject.class objectConverter];
                                         SLAttributeMapping *attributeMapping = [managedObject.class attributeMapping];
                                         
                                         NSString *matchingString = [string substringWithRange:result.range];
                                         NSString *keyPath = [matchingString substringFromIndex:1];
                                         NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
                                         
                                         id evaluatingObject = managedObject;
                                         for (NSString *URLKey in keyPathComponents) {
                                             NSString *valueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:URLKey];
                                             
                                             evaluatingObject = [evaluatingObject valueForKey:valueKey];
                                             
                                             if ([evaluatingObject isKindOfClass:[NSManagedObject class]]) {
                                                 objectConverter = [[evaluatingObject class] objectConverter];
                                                 attributeMapping = [[evaluatingObject class] attributeMapping];
                                             }
                                         }
                                         
                                         NSString *lastValueKey = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:keyPathComponents.lastObject];
                                         
                                         evaluatingObject = [objectConverter JSONObjectObjectFromManagedObjectObject:evaluatingObject
                                                                                           forManagedObjectAttribute:lastValueKey];
                                         
                                         NSAssert(evaluatingObject != nil, @"no object found for underscored key path: %@", matchingString);
                                         
                                         substitutionDictionary[matchingString] = evaluatingObject;
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
