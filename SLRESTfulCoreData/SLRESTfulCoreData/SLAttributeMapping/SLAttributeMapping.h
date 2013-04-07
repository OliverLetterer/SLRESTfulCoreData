//
//  SLAttributeMapping.h
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



/**
 @abstract This class stores attribute mappings between JSON objects and NSManagedObjects.
 */
@interface SLAttributeMapping : NSObject

- (id)initWithManagedObjectClassName:(NSString *)managedObjectClassName;

+ (void)registerDefaultAttribute:(NSString *)attribute forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath;

- (void)registerAttribute:(NSString *)attribute forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath;
- (void)unregisterAttributeName:(NSString *)attributeName;
- (BOOL)isAttributeNameRegistered:(NSString *)attributeName;

/**
 registers naming conventions. can be used for example to always convert _id_ into _identifier_ and vice versa.
 */
+ (void)registerDefaultObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention;
- (void)registerObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention;

- (NSString *)convertManagedObjectAttributeToJSONObjectAttribute:(NSString *)attribute;
- (NSString *)convertJSONObjectAttributeToManagedObjectAttribute:(NSString *)JSONObjectKeyPath;

@end
