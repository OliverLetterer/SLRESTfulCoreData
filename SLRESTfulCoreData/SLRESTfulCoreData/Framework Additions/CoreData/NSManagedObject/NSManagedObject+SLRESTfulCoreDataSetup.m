//
//  NSManagedObject+SLRESTfulCoreDataSetup.m
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

#import "NSManagedObject+SLRESTfulCoreDataSetup.h"
#import "NSManagedObject+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataQueryInterface.h"
#import "SLAttributeMapping.h"
#import "SLObjectConverter.h"
#import "SLObjectDescription.h"
#import <objc/runtime.h>

char *const SLRESTfulCoreDataAttributeMappingKey;
char *const SLRESTfulCoreDataObjectConverterKey;
char *const SLRESTfulCoreDataObjectDescriptionKey;



@implementation NSManagedObject (SLRESTfulCoreDataSetup)

+ (SLAttributeMapping *)attributeMapping
{
    SLAttributeMapping *attributeMapping = objc_getAssociatedObject(self, &SLRESTfulCoreDataAttributeMappingKey);
    
    if (!attributeMapping) {
        attributeMapping = [[SLAttributeMapping alloc] initWithManagedObjectClassName:NSStringFromClass(self)];
        objc_setAssociatedObject(self, &SLRESTfulCoreDataAttributeMappingKey, attributeMapping, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return attributeMapping;
}

+ (SLObjectConverter *)objectConverter
{
    SLObjectConverter *objectConverter = objc_getAssociatedObject(self, &SLRESTfulCoreDataObjectConverterKey);
    
    if (!objectConverter) {
        objectConverter = [[SLObjectConverter alloc] initWithManagedObjectClassName:NSStringFromClass(self)];
        objc_setAssociatedObject(self, &SLRESTfulCoreDataObjectConverterKey, objectConverter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return objectConverter;
}

+ (SLObjectDescription *)objectDescription
{
    SLObjectDescription *attributeMapping = objc_getAssociatedObject(self, &SLRESTfulCoreDataObjectDescriptionKey);
    
    if (!attributeMapping) {
        attributeMapping = [[SLObjectDescription alloc] initWithManagedObjectClassName:NSStringFromClass(self)];
        objc_setAssociatedObject(self, &SLRESTfulCoreDataObjectDescriptionKey, attributeMapping, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return attributeMapping;

}

+ (void)registerAttributeName:(NSString *)attributeName forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath
{
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    
    [attributeMapping registerAttribute:attributeName forJSONObjectKeyPath:JSONObjectKeyPath];
}

+ (void)registerAttributeMapping:(NSDictionary *)attributeMapping
{
    for (id key in attributeMapping) {
        [self registerAttributeName:key forJSONObjectKeyPath:attributeMapping[key]];
    }
}

+ (void)unregisterAttributeName:(NSString *)attributeName
{
    SLAttributeMapping *attributeMapping = [self attributeMapping];
    
    [attributeMapping unregisterAttributeName:attributeName];
}

+ (void)registerCRUDBaseURL:(NSURL *)CRUDBaseURL forRelationship:(NSString *)relationship
{
    [[self objectDescription] registerCRUDBaseURL:CRUDBaseURL forRelationship:relationship];
}

+ (void)registerCRUDBaseURL:(NSURL *)CRUDBaseURL
{
    NSParameterAssert(CRUDBaseURL);
    
    [self objectDescription].CRUDBaseURL = CRUDBaseURL;
}

+ (void)registerSubclass:(Class)subclass forManagedObjectAttributeName:(NSString *)managedObjectAttributeName withValue:(id)value
{
    [[self objectConverter] registerSubclass:subclass forManagedObjectAttributeName:managedObjectAttributeName withValue:value];
}

+ (void)registerValueTransformer:(NSValueTransformer *)valueTransformer forManagedObjectAttributeName:(NSString *)managedObjectAttributeName
{
    [[self objectConverter] registerValueTransformer:valueTransformer forManagedObjectAttributeName:managedObjectAttributeName];
}

+ (void)registerObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention
{
    [[self attributeMapping] registerObjcNamingConvention:objcNamingConvention forJSONNamingConvention:JSONNamingConvention];
}

+ (void)registerUniqueIdentifierOfJSONObjects:(NSString *)uniqueIdentifier
{
    [self objectDescription].uniqueIdentifierOfJSONObjects = uniqueIdentifier;
}

+ (void)registerTimezone:(NSTimeZone *)timezone
{
    [self objectConverter].timeZone = timezone;
}

@end
