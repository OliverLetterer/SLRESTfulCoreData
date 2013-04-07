//
//  SLRESTfulCoreDataSharedManagedObjectContext.m
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

#import "SLRESTfulCoreDataSharedManagedObjectContext.h"
#import "SLAttributeMapping.h"
#import "SLRESTfulCoreData.h"

void initializeDefaultOptions(void);

@interface SLRESTfulCoreDataSharedManagedObjectContext () {
    
}

@end



__attribute((constructor))
void initializeDefaultOptions(void)
{
    [SLAttributeMapping registerDefaultAttribute:@"identifier" forJSONObjectKeyPath:@"id"];
    
    [SLAttributeMapping registerDefaultObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    
    [NSManagedObject registerDefaultMainThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLRESTfulCoreDataSharedManagedObjectContext sharedInstance].managedObjectContext;
    }];
    
    [NSManagedObject registerDefaultBackgroundThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLRESTfulCoreDataSharedManagedObjectContext sharedInstance].managedObjectContext;
    }];
}

@implementation SLRESTfulCoreDataSharedManagedObjectContext

#pragma mark - Initialization

- (id)init 
{
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - Instance methods

- (NSString *)managedObjectModelName
{
    return @"Model";
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        NSString *managedObjectModelName = self.managedObjectModelName;
        NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:managedObjectModelName withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        _managedObjectContext = self.newManagedObjectContext;
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *)newManagedObjectContext
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator = self.persistentStoreCoordinator;
    NSManagedObjectContext *newManagedObjectContext = nil;
    
    if (persistentStoreCoordinator) {
        newManagedObjectContext = [[NSManagedObjectContext alloc] init];
        newManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    }
    
    return newManagedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        NSManagedObjectModel *managedObjectModel = self.managedObjectModel;
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Private category implementation ()

@end



#pragma mark - Singleton implementation

@implementation SLRESTfulCoreDataSharedManagedObjectContext (Singleton)

+ (SLRESTfulCoreDataSharedManagedObjectContext *)sharedInstance 
{
    static SLRESTfulCoreDataSharedManagedObjectContext *_instance = nil;
    
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (id)allocWithZone:(NSZone *)zone 
{	
	return [self sharedInstance];	
}

- (id)copyWithZone:(NSZone *)zone 
{
    return self;	
}

@end
