//
//  SLObjectConverter.m
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
#import <objc/runtime.h>

char *const SLObjectConverterDefaultDateTimeFormatKey;
char *const SLObjectConverterDefaultTimeZoneKey;

static BOOL NSAttributeTypeIsNSNumber(NSAttributeType attributeType)
{
    return NSInteger16AttributeType == attributeType || NSInteger32AttributeType == attributeType || NSInteger64AttributeType == attributeType || NSDecimalAttributeType == attributeType || NSDoubleAttributeType == attributeType || NSFloatAttributeType == attributeType || NSBooleanAttributeType == attributeType;
}

static void mergeDictionaries(NSMutableDictionary *mainDictionary, NSDictionary *otherDictionary)
{
    for (id key in otherDictionary) {
        if (!mainDictionary[key]) {
            mainDictionary[key] = otherDictionary[key];
        }
    }
}



@interface SLObjectConverter () {
    NSDictionary *_attributTypesValidationDictionary;
}

@property (nonatomic, copy) NSString *managedObjectClassName;

@property (nonatomic, strong) NSMutableDictionary *registeredSubclassesDictionary;
@property (nonatomic, readonly) NSDictionary *mergedSubclassesDictionary;

@property (nonatomic, strong) NSMutableDictionary *valueTransformers;
@property (nonatomic, strong) NSDictionary *mergedValueTransformers;

- (BOOL)_isObject:(id)object validForManagedObjectAttribute:(NSString *)managedObjectAttributeName;
- (id)_convertObject:(id)object forManagedObjectAttribute:(NSString *)managedObjectAttributeName;
- (id)_reverseConvertObject:(id)object forManagedObjectAttribute:(NSString *)managedObjectAttributeName;

@end



@implementation SLObjectConverter

#pragma mark - setters and getters

- (NSDictionary *)mergedSubclassesDictionary
{
    NSMutableDictionary *mergedSubclassesDictionary = self.registeredSubclassesDictionary.mutableCopy;
    Class managedObjectClass = [NSClassFromString(self.managedObjectClassName) superclass];
    
    while ([[managedObjectClass class] isSubclassOfClass:[NSManagedObject class]] && [managedObjectClass class] != [NSManagedObject class]) {
        SLObjectConverter *nextConvert = [managedObjectClass objectConverter];
        
        [nextConvert.registeredSubclassesDictionary enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary *otherSubclassDictionary, BOOL *stop) {
            NSMutableDictionary *thisSubclassDictionary = [self _subclassDictionaryForManagedObjectAttributeName:key inDictionary:mergedSubclassesDictionary];
            
            mergeDictionaries(thisSubclassDictionary, otherSubclassDictionary);
        }];
        
        managedObjectClass = [managedObjectClass superclass];
    }
    
    return mergedSubclassesDictionary;
}

- (NSDictionary *)mergedValueTransformers
{
    NSMutableDictionary *mergedValueTransformers = self.valueTransformers.mutableCopy;
    Class managedObjectClass = [NSClassFromString(self.managedObjectClassName) superclass];
    
    while ([[managedObjectClass class] isSubclassOfClass:[NSManagedObject class]] && [managedObjectClass class] != [NSManagedObject class]) {
        mergeDictionaries(mergedValueTransformers, [managedObjectClass objectConverter].valueTransformers);
        managedObjectClass = [managedObjectClass superclass];
    }
    
    return mergedValueTransformers;
}

#pragma mark - Initialization

- (id)initWithManagedObjectClassName:(NSString *)managedObjectClassName
{
    if (self = [super init]) {
        // Initialization code
        _managedObjectClassName = managedObjectClassName;
        
        self.registeredSubclassesDictionary = [NSMutableDictionary dictionary];
        self.valueTransformers = [NSMutableDictionary dictionary];
        self.dateTimeFormat = [self.class defaultDateTimeFormat];
        self.timeZone = [self.class defaultTimeZone];
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:_managedObjectClassName
                                                             inManagedObjectContext:[NSClassFromString(_managedObjectClassName) mainThreadManagedObjectContext]];
        
        NSMutableDictionary *attributTypesValidationDictionary = [NSMutableDictionary dictionaryWithCapacity:entityDescription.attributesByName.count];
        
        [entityDescription.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeDescription, BOOL *stop)
         {
             NSAttributeType attributeType = attributeDescription.attributeType;
             attributTypesValidationDictionary[attributeName] = @(attributeType);
         }];
        
        _attributTypesValidationDictionary = attributTypesValidationDictionary;
    }
    return self;
}

#pragma mark - Instance methods

- (id)managedObjectObjectFromJSONObjectObject:(id)JSONObjectObject
                    forManagedObjectAttribute:(NSString *)managedObjectAttributeName
{
    if ([self _isObject:JSONObjectObject validForManagedObjectAttribute:managedObjectAttributeName]) {
        return [self _convertObject:JSONObjectObject forManagedObjectAttribute:managedObjectAttributeName];
    }
    
    if (JSONObjectObject) {
        NSLog(@"API return invalid object %@ for managedObjectAttributeName %@ of class %@", JSONObjectObject, managedObjectAttributeName, _managedObjectClassName);
    }
    
    return nil;
}

- (id)JSONObjectObjectFromManagedObjectObject:(id)managedObjectObject
                    forManagedObjectAttribute:(NSString *)managedObjectAttributeName
{
    return [self _reverseConvertObject:managedObjectObject
             forManagedObjectAttribute:managedObjectAttributeName];
}

+ (NSString *)defaultDateTimeFormat
{
    return objc_getAssociatedObject(self, &SLObjectConverterDefaultDateTimeFormatKey) ?: @"yyyy-MM-dd'T'HH:mm:ss'Z'";
}

+ (void)setDefaultDateTimeFormat:(NSString *)defaultDateTimeFormat
{
    objc_setAssociatedObject(self, &SLObjectConverterDefaultDateTimeFormatKey,
                             defaultDateTimeFormat, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSTimeZone *)defaultTimeZone
{
    return objc_getAssociatedObject(self, &SLObjectConverterDefaultTimeZoneKey) ?: [NSTimeZone timeZoneForSecondsFromGMT:0];
}

+ (void)setDefaultTimeZone:(NSTimeZone *)timeZone
{
    objc_setAssociatedObject(self, &SLObjectConverterDefaultTimeZoneKey,
                             timeZone, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)registerSubclass:(Class)subclass forManagedObjectAttributeName:(NSString *)managedObjectAttributeName withValue:(id)value
{
    NSAssert(subclass, @"subclass cannot be nil");
    NSAssert(managedObjectAttributeName, @"managedObjectAttributeName cannot be nil");
    NSAssert(value, @"value cannot be nil");
    
    NSMutableDictionary *subclassDictionary = [self _subclassDictionaryForManagedObjectAttributeName:managedObjectAttributeName inDictionary:self.registeredSubclassesDictionary];
    subclassDictionary[value] = subclass;
}

- (Class)subclassForRawJSONDictionary:(NSDictionary *)JSONDictionary
{
    __block Class class = nil;
    
    SLAttributeMapping *attributeMapping = [NSClassFromString(self.managedObjectClassName) attributeMapping];
    [self.mergedSubclassesDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *managedObjectAttributeName, NSDictionary *subclassesDictionary, BOOL *stop) {
        NSString *JSONObjectKey = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:managedObjectAttributeName];
        id JSONObjectValue = JSONDictionary[JSONObjectKey];
        
        Class registeredClass = subclassesDictionary[JSONObjectValue];
        if (registeredClass) {
            class = registeredClass;
            *stop = YES;
        }
    }];
    
    return class;
}

- (void)registerValueTransformer:(NSValueTransformer *)valueTransformer forManagedObjectAttributeName:(NSString *)managedObjectAttributeName
{
    NSParameterAssert(valueTransformer);
    NSParameterAssert(managedObjectAttributeName);
    
    self.valueTransformers[managedObjectAttributeName] = valueTransformer;
}

- (NSValueTransformer *)valueTransformerForManagedObjectAttributeName:(NSString *)managedObjectAttributeName
{
    NSValueTransformer *valueTransformer = self.mergedValueTransformers[managedObjectAttributeName];
    
    if (valueTransformer) {
        return valueTransformer;
    }
    
    objc_property_t property = class_getProperty(NSClassFromString(self.managedObjectClassName), managedObjectAttributeName.UTF8String);
    
    char *attribute = property_copyAttributeValue(property, "T");
    NSString *className = [NSString stringWithUTF8String:attribute];
    free(attribute);
    
    if (className.length < 3) {
        return nil;
    }
    
    if ([className characterAtIndex:0] != '@' && [className characterAtIndex:1] != '"' && [className characterAtIndex:className.length - 1] != '"') {
        return nil;
    }
    
    className = [className substringFromIndex:2];
    className = [className substringToIndex:className.length - 1];
    
    Class valueTransformerClass = NSClassFromString([NSString stringWithFormat:@"SL%@ValueTransformer", className]);
    if ([valueTransformerClass isSubclassOfClass:[NSValueTransformer class]]) {
        return [valueTransformerClass new];
    }
    
    return nil;
}

#pragma mark - private category implementation ()

- (BOOL)_isObject:(id)object validForManagedObjectAttribute:(NSString *)managedObjectAttributeName
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:_managedObjectClassName
                                                         inManagedObjectContext:[NSClassFromString(_managedObjectClassName) mainThreadManagedObjectContext]];
    NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectAttributeName];
    
    if ((!object || [object isKindOfClass:[NSNull class]]) && attributeDescription.isOptional) {
        return YES;
    }
    
    NSAttributeType attributeType = [_attributTypesValidationDictionary[managedObjectAttributeName] unsignedIntegerValue];
    
    if (NSAttributeTypeIsNSNumber(attributeType)) {
        return [object isKindOfClass:NSNumber.class];
    } else if (attributeType == NSStringAttributeType || attributeType == NSDateAttributeType) {
        return [object isKindOfClass:NSString.class];
    } else if (attributeType == NSTransformableAttributeType) {
        return YES;
    }
    
    return NO;
}

- (id)_convertObject:(id)object forManagedObjectAttribute:(NSString *)managedObjectAttributeName
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:_managedObjectClassName
                                                         inManagedObjectContext:[NSClassFromString(_managedObjectClassName) mainThreadManagedObjectContext]];
    NSAttributeDescription *attributeDescription = entityDescription.attributesByName[managedObjectAttributeName];
    
    if ((!object || [object isKindOfClass:[NSNull class]]) && attributeDescription.isOptional) {
        return nil;
    }
    
    NSAttributeType attributeType = [_attributTypesValidationDictionary[managedObjectAttributeName] unsignedIntegerValue];
    
    if (NSAttributeTypeIsNSNumber(attributeType) || attributeType == NSStringAttributeType) {
        return object;
    } else if (attributeType == NSDateAttributeType) {
        return [self _dateFromString:object];
    } else if (attributeType == NSTransformableAttributeType) {
        NSValueTransformer *valueTransformer = [self valueTransformerForManagedObjectAttributeName:managedObjectAttributeName];
        return [valueTransformer transformedValue:object];
    }
    
    return nil;
}

- (id)_reverseConvertObject:(id)object forManagedObjectAttribute:(NSString *)managedObjectAttributeName
{
    NSAttributeType attributeType = [_attributTypesValidationDictionary[managedObjectAttributeName] unsignedIntegerValue];
    
    if (NSAttributeTypeIsNSNumber(attributeType) || attributeType == NSStringAttributeType) {
        return object;
    } else if (attributeType == NSDateAttributeType) {
        return [self _stringFromDate:object];
    } else if (attributeType == NSTransformableAttributeType) {
        NSValueTransformer *valueTransformer = [self valueTransformerForManagedObjectAttributeName:managedObjectAttributeName];
        return [valueTransformer reverseTransformedValue:object];
    }
    
    return nil;
}

- (NSMutableDictionary *)_subclassDictionaryForManagedObjectAttributeName:(NSString *)managedObjectAttributeName inDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableDictionary *subclassDictionary = dictionary[managedObjectAttributeName];
    
    if (!subclassDictionary) {
        subclassDictionary = [NSMutableDictionary dictionary];
        dictionary[managedObjectAttributeName] = subclassDictionary;
    }
    
    return subclassDictionary;
}

- (NSString *)_stringFromDate:(NSDate *)date
{
    if (![date isKindOfClass:[NSDate class]]) {
        return nil;
    }
    
    NSDateFormatter *formatter = [self _dateFormatterWithFormat:self.dateTimeFormat];
    formatter.timeZone = self.timeZone;
    
    return [formatter stringFromDate:date];
}

- (NSDate *)_dateFromString:(NSString *)string
{
    if (![string isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSDateFormatter *formatter = [self _dateFormatterWithFormat:self.dateTimeFormat];
    formatter.timeZone = self.timeZone;
    
    return [formatter dateFromString:string];
}

- (NSDateFormatter *)_dateFormatterWithFormat:(NSString *)dateTimeFormat
{
    static NSMutableDictionary *dateFormatters = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatters = [NSMutableDictionary dictionary];
    });
    
    NSDateFormatter *dateFormatter = dateFormatters[dateTimeFormat];
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = dateTimeFormat;
        dateFormatters[dateTimeFormat] = dateFormatter;
    }
    
    return dateFormatter;
}

@end
