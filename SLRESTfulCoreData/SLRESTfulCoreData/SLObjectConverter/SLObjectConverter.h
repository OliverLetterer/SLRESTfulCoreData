//
//  SLObjectConverter.h
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
 @abstract  <#abstract comment#>
 */
@interface SLObjectConverter : NSObject

- (id)initWithManagedObjectClassName:(NSString *)managedObjectClassName;

- (id)managedObjectObjectFromJSONObjectObject:(id)JSONObjectObject
                    forManagedObjectAttribute:(NSString *)managedObjectAttributeName;

- (id)JSONObjectObjectFromManagedObjectObject:(id)managedObjectObject
                    forManagedObjectAttribute:(NSString *)managedObjectAttributeName;

/**
 Date time format, default is @"yyyy-MM-dd'T'HH:mm:ss'Z'"
 */
@property (nonatomic, strong) NSString *dateTimeFormat;

/**
 Every instance of SLObjectConverter will have defaultDateTimeFormat as default value for dateTimeFormat.
 */
+ (NSString *)defaultDateTimeFormat;
+ (void)setDefaultDateTimeFormat:(NSString *)defaultDateTimeFormat;

/**
 The timezone in which all dates are returned
 */
@property (nonatomic, strong) NSTimeZone *timeZone;

+ (NSTimeZone *)defaultTimeZone;
+ (void)setDefaultTimeZone:(NSTimeZone *)timeZone;

/**
 single table inheritens
 */
- (void)registerSubclass:(Class)subclass forManagedObjectAttributeName:(NSString *)managedObjectAttributeName withValue:(id)value;
- (Class)subclassForRawJSONDictionary:(NSDictionary *)JSONDictionary;

/**
 registering value transformers which can convert between JSON and CoreData
 */
- (void)registerValueTransformer:(NSValueTransformer *)valueTransformer forManagedObjectAttributeName:(NSString *)managedObjectAttributeName;
- (NSValueTransformer *)valueTransformerForManagedObjectAttributeName:(NSString *)managedObjectAttributeName;

@end
