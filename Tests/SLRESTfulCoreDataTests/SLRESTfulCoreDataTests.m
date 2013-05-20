//
//  SLRESTfulCoreDataTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"
#import "SLTestDataStore.h"
#import "SLRESTfulCoreData.h"



__attribute__((constructor))
void SLRESTfulCoreDataTestsInitialize(void)
{
    [NSManagedObject registerDefaultMainThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestDataStore sharedInstance].mainThreadManagedObjectContext;
    }];
    
    [NSManagedObject registerDefaultBackgroundThreadManagedObjectContextWithAction:^NSManagedObjectContext *{
        return [SLTestDataStore sharedInstance].backgroundThreadManagedObjectContext;
    }];
}


@interface SLRESTfulCoreDataTests () {
    
}

@end



@implementation SLRESTfulCoreDataTests

#pragma mark - Initialization

- (id)init 
{
    if (self = [super init]) {
        // Initialization code
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    
}

#pragma mark - Private category implementation ()

@end
