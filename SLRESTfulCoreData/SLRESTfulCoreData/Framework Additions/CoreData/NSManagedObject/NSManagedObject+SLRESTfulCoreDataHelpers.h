//
//  NSManagedObject+SLRESTfulCoreDataHelpers.h
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

@interface NSManagedObject (SLRESTfulCoreDataHelpers)

/**
 @return NSRelationshipDescription whichs name is relationshipName.
 */
+ (NSRelationshipDescription *)relationshipDescriptionNamed:(NSString *)relationshipName;

/**
 @return NSArray with a NSString for each attribute belonging to this entity which should be mapped.
 */
+ (NSArray *)attributeNames;

/**
 @return Fetches an object of this class from database with a given it of a remote object.
 */
+ (instancetype)objectWithRemoteIdentifier:(id)identifier inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 @return [self objectsFromRelationship:relationship sortedByAttribute:attribute ascending:YES].
 */
- (NSArray *)objectsFromRelationship:(NSString *)relationship sortedByAttribute:(NSString *)attribute;

/**
 @return Sorted array of a given relationship by a given attribute ascending.
 */
- (NSArray *)objectsFromRelationship:(NSString *)relationship sortedByAttribute:(NSString *)attribute ascending:(BOOL)ascending;

/**
 Deletes a set of objects with given remote IDs.
 */
+ (void)deleteObjectsWithoutRemoteIDs:(NSArray *)remoteIDs inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 Returns JSONObjectPrefix from attribute mapping
 */
+ (NSString *)JSONObjectPrefix;

@end
