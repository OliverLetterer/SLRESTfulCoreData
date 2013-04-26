//
//  SLAttributeMapping.m
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

#import "SLAttributeMapping.h"
#import "NSString+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreData.h"
#import "NSManagedObject+SLRESTfulCoreDataSetup.h"

static void mergeDictionaries(NSMutableDictionary *mainDictionary, NSDictionary *otherDictionary)
{
    for (id key in otherDictionary) {
        if (!mainDictionary[key]) {
            mainDictionary[key] = otherDictionary[key];
        }
    }
}



@interface SLAttributeMapping () {
    
}

+ (NSMutableDictionary *)managedObjectJSONObjectAttributesDictionary;
+ (NSMutableDictionary *)JSONObjectManagedObjectAttributesDictionary;

+ (NSMutableDictionary *)managedObjectJSONObjectNamingConventions;
+ (NSMutableDictionary *)JSONObjectManagedObjectNamingConventions;

@property (nonatomic, copy) NSString *managedObjectClassName;

@property (nonatomic, strong) NSMutableArray *unregisteresAttributeNames;
@property (nonatomic, readonly) NSArray *mergedUnregisteresAttributeNames;

@property (nonatomic, strong) NSMutableDictionary *managedObjectJSONObjectAttributesDictionary; // { "myValue" : "my_value" }
@property (nonatomic, readonly) NSDictionary *mergedManagedObjectJSONObjectAttributesDictionary;

@property (nonatomic, strong) NSMutableDictionary *JSONObjectManagedObjectAttributesDictionary; // { "my_value" : "myValue" }
@property (nonatomic, readonly) NSDictionary *mergedJSONObjectManagedObjectAttributesDictionary;

@property (nonatomic, strong) NSMutableDictionary *managedObjectJSONObjectNamingConventions; // { "myValue" : "my_value" }
@property (nonatomic, readonly) NSDictionary *mergedManagedObjectJSONObjectNamingConventions;

@property (nonatomic, strong) NSMutableDictionary *JSONObjectManagedObjectNamingConventions; // { "my_value" : "myValue" }
@property (nonatomic, readonly) NSDictionary *mergedJSONObjectManagedObjectNamingConventions;

- (void)_mergeDictionary:(NSMutableDictionary *)thisDictionary withOtherDictionary:(NSMutableDictionary *)otherDictionary;

@end



static NSDictionary *SLAttributeMappingMergeDictionary(SLAttributeMapping *self, NSString *value)
{
    NSMutableDictionary *dictionary = [[self valueForKey:value] mutableCopy];
    Class managedObjectClass = [NSClassFromString(self.managedObjectClassName) superclass];
    
    while ([[managedObjectClass class] isSubclassOfClass:[NSManagedObject class]] && [managedObjectClass class] != [NSManagedObject class]) {
        mergeDictionaries(dictionary, [[managedObjectClass attributeMapping] valueForKey:value]);
        managedObjectClass = [managedObjectClass superclass];
    }
    
    return dictionary;
}



@implementation SLAttributeMapping

#pragma mark - setters and getters

+ (NSMutableDictionary *)managedObjectJSONObjectAttributesDictionary
{
    static NSMutableDictionary *managedObjectJSONObjectAttributesDictionary = nil;
    
    if (!managedObjectJSONObjectAttributesDictionary) {
        managedObjectJSONObjectAttributesDictionary = [NSMutableDictionary dictionary];
    }
    
    return managedObjectJSONObjectAttributesDictionary;
}

+ (NSMutableDictionary *)JSONObjectManagedObjectAttributesDictionary
{
    static NSMutableDictionary *JSONObjectManagedObjectAttributesDictionary = nil;
    
    if (!JSONObjectManagedObjectAttributesDictionary) {
        JSONObjectManagedObjectAttributesDictionary = [NSMutableDictionary dictionary];
    }
    
    return JSONObjectManagedObjectAttributesDictionary;
}

+ (NSMutableDictionary *)managedObjectJSONObjectNamingConventions
{
    static NSMutableDictionary *managedObjectJSONObjectNamingConventions = nil;
    
    if (!managedObjectJSONObjectNamingConventions) {
        managedObjectJSONObjectNamingConventions = [NSMutableDictionary dictionary];
    }
    
    return managedObjectJSONObjectNamingConventions;
}

+ (NSMutableDictionary *)JSONObjectManagedObjectNamingConventions
{
    static NSMutableDictionary *JSONObjectManagedObjectNamingConventions = nil;
    
    if (!JSONObjectManagedObjectNamingConventions) {
        JSONObjectManagedObjectNamingConventions = [NSMutableDictionary dictionary];
    }
    
    return JSONObjectManagedObjectNamingConventions;
}

- (NSArray *)mergedUnregisteresAttributeNames
{
    NSMutableArray *unregisteresAttributeNames = self.unregisteresAttributeNames.mutableCopy;
    Class managedObjectClass = [NSClassFromString(self.managedObjectClassName) superclass];
    
    while ([[managedObjectClass class] isSubclassOfClass:[NSManagedObject class]] && [managedObjectClass class] != [NSManagedObject class]) {
        [unregisteresAttributeNames addObjectsFromArray:[managedObjectClass attributeMapping].unregisteresAttributeNames];
        managedObjectClass = [managedObjectClass superclass];
    }
    
    return unregisteresAttributeNames;
}

- (NSDictionary *)mergedManagedObjectJSONObjectAttributesDictionary
{
    return SLAttributeMappingMergeDictionary(self, @"managedObjectJSONObjectAttributesDictionary");
}
- (NSDictionary *)mergedJSONObjectManagedObjectAttributesDictionary
{
    return SLAttributeMappingMergeDictionary(self, @"JSONObjectManagedObjectAttributesDictionary");
}

- (NSDictionary *)mergedManagedObjectJSONObjectNamingConventions
{
    return SLAttributeMappingMergeDictionary(self, @"managedObjectJSONObjectNamingConventions");
}

- (NSDictionary *)mergedJSONObjectManagedObjectNamingConventions
{
    return SLAttributeMappingMergeDictionary(self, @"JSONObjectManagedObjectNamingConventions");
}

#pragma mark - Initialization

- (id)initWithManagedObjectClassName:(NSString *)managedObjectClassName
{
    if (self = [super init]) {
        _managedObjectClassName = managedObjectClassName;
        
        self.managedObjectJSONObjectAttributesDictionary = [self.class managedObjectJSONObjectAttributesDictionary].mutableCopy;
        self.JSONObjectManagedObjectAttributesDictionary = [self.class JSONObjectManagedObjectAttributesDictionary].mutableCopy;
        
        self.managedObjectJSONObjectNamingConventions = [self.class managedObjectJSONObjectNamingConventions].mutableCopy;
        self.JSONObjectManagedObjectNamingConventions = [self.class JSONObjectManagedObjectNamingConventions].mutableCopy;
        
        self.unregisteresAttributeNames = [NSMutableArray array];
    }
    return self;
}

#pragma mark - instance methods

+ (void)registerDefaultAttribute:(NSString *)attribute forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath
{
    NSParameterAssert(attribute);
    NSParameterAssert(JSONObjectKeyPath);
    
    [self managedObjectJSONObjectAttributesDictionary][attribute] = JSONObjectKeyPath;
    [self JSONObjectManagedObjectAttributesDictionary][JSONObjectKeyPath] = attribute;
}

- (void)registerAttribute:(NSString *)attribute forJSONObjectKeyPath:(NSString *)JSONObjectKeyPath
{
    NSAssert(attribute != nil, @"No attribute specified");
    NSAssert(JSONObjectKeyPath != nil, @"No JSONObjectKeyPath specified");
    
    [self.unregisteresAttributeNames removeObject:attribute];
    self.managedObjectJSONObjectAttributesDictionary[attribute] = JSONObjectKeyPath;
    self.JSONObjectManagedObjectAttributesDictionary[JSONObjectKeyPath] = attribute;
}

- (void)unregisterAttributeName:(NSString *)attributeName
{
    NSAssert(attributeName != nil, @"attributeName cannot be nil");
    [self.unregisteresAttributeNames addObject:attributeName];
}

- (BOOL)isAttributeNameRegistered:(NSString *)attributeName
{
    return ![self.mergedUnregisteresAttributeNames containsObject:attributeName];
}

+ (void)registerDefaultObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention
{
    NSParameterAssert(objcNamingConvention);
    NSParameterAssert(JSONNamingConvention);
    
    [self managedObjectJSONObjectNamingConventions][objcNamingConvention] = JSONNamingConvention;
    [self JSONObjectManagedObjectNamingConventions][JSONNamingConvention] = objcNamingConvention;
}

- (void)registerObjcNamingConvention:(NSString *)objcNamingConvention forJSONNamingConvention:(NSString *)JSONNamingConvention
{
    NSParameterAssert(objcNamingConvention);
    NSParameterAssert(JSONNamingConvention);
    
    self.managedObjectJSONObjectNamingConventions[objcNamingConvention] = JSONNamingConvention;
    self.JSONObjectManagedObjectNamingConventions[JSONNamingConvention] = objcNamingConvention;
}

- (NSString *)convertManagedObjectAttributeToJSONObjectAttribute:(NSString *)attribute
{
    NSString *key = self.mergedManagedObjectJSONObjectAttributesDictionary[attribute];
    
    if (key) {
        return key;
    }
    
    NSMutableCharacterSet *leftCharacterSet = [NSMutableCharacterSet lowercaseLetterCharacterSet];
    [leftCharacterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSMutableCharacterSet *rightCharacterSet = [NSMutableCharacterSet uppercaseLetterCharacterSet];
    
    NSDictionary *mergedManagedObjectJSONObjectNamingConventions = self.mergedManagedObjectJSONObjectNamingConventions;
    NSArray *possibleConventions = [mergedManagedObjectJSONObjectNamingConventions.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        } else if (obj1.length > obj2.length) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    for (NSString *namingConvention in possibleConventions) {
        NSRange range = [attribute.uppercaseString rangeOfString:namingConvention.uppercaseString];
        
        if (range.location == NSNotFound) {
            continue;
        }
        
        BOOL isAtStartOfString = range.location == 0;
        BOOL isAtEndOfString = range.location + range.length == attribute.length;
        
        if (isAtStartOfString && isAtEndOfString) {
            attribute = [attribute stringByReplacingCharactersInRange:range withString:mergedManagedObjectJSONObjectNamingConventions[namingConvention]];
            continue;
        }
        
        BOOL isLeftCharacterValid = isAtStartOfString;
        BOOL isRightCharacterValid = isAtEndOfString;
        
        if (!isLeftCharacterValid && !isAtStartOfString) {
            isLeftCharacterValid = [leftCharacterSet characterIsMember:[attribute characterAtIndex:range.location - 1]];
        }
        
        if (!isRightCharacterValid && !isAtEndOfString) {
            isRightCharacterValid = [rightCharacterSet characterIsMember:[attribute characterAtIndex:range.location + range.length]];
        }
        
        // string is in the middle, only allow substitution of full path components
        if (isLeftCharacterValid && isRightCharacterValid) {
            NSString *replacementString = mergedManagedObjectJSONObjectNamingConventions[namingConvention];
            
            if (!isAtStartOfString) {
                replacementString = [@"_" stringByAppendingString:replacementString];
            }
            
            if (!isAtEndOfString) {
                replacementString = [replacementString stringByAppendingString:@"_"];
            }
            
            attribute = [attribute stringByReplacingCharactersInRange:range withString:replacementString];
        }
    }
    
    return attribute.stringByUnderscoringString;
}

- (NSString *)convertJSONObjectAttributeToManagedObjectAttribute:(NSString *)JSONObjectKeyPath
{
    NSString *key = self.mergedJSONObjectManagedObjectAttributesDictionary[JSONObjectKeyPath];
    
    if (key) {
        return key;
    }
    
    NSDictionary *mergedJSONObjectManagedObjectNamingConventions = self.mergedJSONObjectManagedObjectNamingConventions;
    NSArray *possibleConventions = [mergedJSONObjectManagedObjectNamingConventions.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        } else if (obj1.length > obj2.length) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    for (NSString *namingConvention in possibleConventions) {
        NSRange range = [JSONObjectKeyPath rangeOfString:namingConvention];
        
        if (range.location == NSNotFound) {
            continue;
        }
        
        BOOL isAtStartOfString = range.location == 0;
        BOOL isAtEndOfString = range.location + range.length == JSONObjectKeyPath.length;
        
        if (isAtStartOfString && isAtEndOfString) {
            JSONObjectKeyPath = [JSONObjectKeyPath stringByReplacingCharactersInRange:range withString:mergedJSONObjectManagedObjectNamingConventions[namingConvention]];
            continue;
        }
        
        BOOL isLeftCharacterValid = isAtStartOfString;
        BOOL isRightCharacterValid = isAtEndOfString;
        
        if (!isLeftCharacterValid && !isAtStartOfString) {
            isLeftCharacterValid = [JSONObjectKeyPath characterAtIndex:range.location - 1] == '_';
        }
        
        if (!isRightCharacterValid && !isAtEndOfString) {
            isRightCharacterValid = [JSONObjectKeyPath characterAtIndex:range.location + range.length] == '_';
        }
        
        // string is in the middle, only allow substitution of full path components
        if (isLeftCharacterValid && isRightCharacterValid) {
            JSONObjectKeyPath = [JSONObjectKeyPath stringByReplacingCharactersInRange:range withString:mergedJSONObjectManagedObjectNamingConventions[namingConvention]];
        }
    }
    
    return JSONObjectKeyPath.stringByCamelizingString;
}

#pragma mark - Private category implementation ()

- (void)_mergeDictionary:(NSMutableDictionary *)thisDictionary withOtherDictionary:(NSMutableDictionary *)otherDictionary
{
    [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (!thisDictionary[key]) {
            thisDictionary[key] = obj;
        }
    }];
}

@end
