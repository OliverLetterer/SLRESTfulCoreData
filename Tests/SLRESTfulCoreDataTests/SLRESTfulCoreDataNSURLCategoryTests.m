//
//  SLRESTfulCoreDataNSURLCategoryTests.m
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 21.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreDataTests.h"

@interface SLEntity5Child1 : NSManagedObject
@property (nonatomic, strong) NSNumber *identifier;
@end

@interface SLEntity5 : NSManagedObject
@property (nonatomic, strong) NSNumber *floatNumber;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSString *otherString;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) SLEntity5Child1 *child;
@end



@interface SLRESTfulCoreDataNSURLCategoryTests : SenTestCase

@end



@implementation SLRESTfulCoreDataNSURLCategoryTests

- (void)setUp
{
    NSManagedObjectModel *model = [SLTestDataStore sharedInstance].managedObjectModel;
    
    for (NSEntityDescription *entity in model.entities) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity.name];
        
        NSError *error = nil;
        NSArray *objects = [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, @"");
        
        for (NSManagedObject *object in objects) {
            [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext deleteObject:object];
        }
    }
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
}

- (void)testComplexURLSubstitution
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDate *now = [NSDate date];
    NSString *nowString = [dateFormatter stringFromDate:now];
    now = [dateFormatter dateFromString:nowString];
    
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    entity.identifier = @5;
    entity.string = @"füh";
    entity.date = now;
    
    SLEntity5Child1 *child = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5Child1 class]) inManagedObjectContext:[SLTestDataStore sharedInstance].mainThreadManagedObjectContext];
    
    child.identifier = @7;
    entity.child = child;
    
    NSError *saveError = nil;
    [[SLTestDataStore sharedInstance].mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    
    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/:id/:date/:string/:child.id"];
    NSURL *expextedURL = [NSURL URLWithString:[[NSString stringWithFormat:@"http://0.0.0.0:3000/api/root/5/%@/füh/7", nowString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    expect([URL URLBySubstitutingAttributesWithManagedObject:entity]).to.equal(expextedURL);
}

@end
