//
//  SLRESTfulCoreDataTests.m
//  SLRESTfulCoreDataTests
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

#import "SLRESTfulCoreDataTests.h"
#import "SLRESTfulCoreData.h"
#import "TTEntity1.h"
#import "Entity2.h"
#import "Entity3.h"
#import "Entity4.h"
#import "TTWorkflow.h"
#import "TTWorkflowSubsclass.h"
#import "TTDashboard.h"
#import "SLRESTfulCoreDataSharedManagedObjectContext.h"
#import "EntityOneToOne1.h"
#import "EntityOneToOne2.h"

@interface SLRESTfulCoreDataTests ()

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end



@implementation SLRESTfulCoreDataTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [SLRESTfulCoreDataSharedManagedObjectContext sharedInstance].managedObjectContext;
}

#pragma mark - Tests

- (void)testDifferentAttributeMappings
{
    SLAttributeMapping *model1 = [TTEntity1 attributeMapping];
    SLAttributeMapping *model2 = [Entity2 attributeMapping];
    
    STAssertNotNil(model1, @"+[NSManagedObject attributeMapping] cannot return nil");
    STAssertNotNil(model2, @"+[NSManagedObject attributeMapping] cannot return nil");
    
    STAssertTrue(model1 != model2, @"Different entities cannot return the same SLAttributeMapping");
    
    STAssertEquals(model1, [TTEntity1 attributeMapping], @"+[NSManagedObject attributeMapping] cannot return different models for the same class.");
}

- (void)testAttributeMappingKeyConversion
{
    SLAttributeMapping *model = [TTEntity1 attributeMapping];
    
    NSString *key = [model convertManagedObjectAttributeToJSONObjectAttribute:@"someStrangeString"];
    NSString *expectedKey = @"some_super_strange_string";
    STAssertEqualObjects(key, expectedKey, @"keyForJSONObjectFromManagedObjectAttribute: not working");
    
    key = [model convertManagedObjectAttributeToJSONObjectAttribute:@"someDate"];
    expectedKey = @"some_date";
    STAssertEqualObjects(key, expectedKey, @"keyForJSONObjectFromManagedObjectAttribute: not working");
    
    
    
    key = [model convertJSONObjectAttributeToManagedObjectAttribute:@"some_super_strange_string"];
    expectedKey = @"someStrangeString";
    STAssertEqualObjects(key, expectedKey, @"keyForManagedObjectFromJSONObjectKeyPath: not working");
    
    key = [model convertJSONObjectAttributeToManagedObjectAttribute:@"some_date"];
    expectedKey = @"someDate";
    STAssertEqualObjects(key, expectedKey, @"keyForManagedObjectFromJSONObjectKeyPath: not working");
}

- (void)testAttributeNames
{
    NSArray *attributeNames = [TTEntity1 registeredAttributeNames];
    NSArray *expectedAttributes = @[ @"identifier", @"keyPathValue", @"someDate", @"someNumber", @"someStrangeString", @"someString" ];
    
    STAssertEqualObjects(attributeNames, expectedAttributes, @"+[NSManagedObject attributeNamesInManagedObjectContext] not returning correct attribute names");
}

- (void)testCreationAndUpdateOfManagedObjectModels
{
    NSURL *URL = [[NSBundle bundleForClass:self.class] URLForResource:@"APISampleEntity" withExtension:@"json"];
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                                                   options:0
                                                                     error:NULL];
    
    // update one entity with id 5
    TTEntity1 *entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                               inManagedObjectContext:self.managedObjectContext];
    
    STAssertEqualObjects(entity.identifier, @5, @"id not correct (%@)", entity);
    STAssertEqualObjects(entity.someString, @"String", @"someString not correct (%@)", entity);
    STAssertEqualObjects(entity.someNumber, @7, @"someNumber not correct (%@)", entity);
    STAssertEqualObjects(entity.someStrangeString, @"Super Strange String", @"someStrangeString not correct (%@)", entity);
    STAssertEqualObjects(entity.keyPathValue, @"keyPathValue", @"keyPathValue wrong");
    
    NSDictionary *rawJSONDictionary = entity.rawJSONDictionary;
    NSDictionary *exptetedRawJSONDictionary = @{
                                                @"id": @5,
                                                @"some_string": @"String",
                                                @"some_date": @"2012-02-24T08:22:43Z",
                                                @"some_number": @7,
                                                @"some_super_strange_string": @"Super Strange String",
                                                @"key_path_value": @{ @"second_string_key": @"keyPathValue" },
                                                };
    STAssertEqualObjects(rawJSONDictionary, exptetedRawJSONDictionary, @"rawJSONDictionary not working");
    
    TTEntity1 *fetchedEntity = [TTEntity1 objectWithRemoteIdentifier:@5
                                              inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(fetchedEntity, @"fetchedEntity cannot be nil");
    STAssertEqualObjects(fetchedEntity.identifier, @5, @"id not correct (%@)", fetchedEntity);
    STAssertEqualObjects(fetchedEntity.someString, @"String", @"someString not correct (%@)", fetchedEntity);
    STAssertEqualObjects(fetchedEntity.someNumber, @7, @"someNumber not correct (%@)", fetchedEntity);
    STAssertEqualObjects(fetchedEntity.someStrangeString, @"Super Strange String", @"someStrangeString not correct (%@)", fetchedEntity);
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = [SLObjectConverter defaultDateTimeFormat];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    STAssertEqualObjects(entity.someDate, [dateFormatter dateFromString:@"2012-02-24T08:22:43Z"], @"someDate not correct (%@)", entity);
    
    // now update the same entity with myID 5 => only one object should exist in the database
    entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                    inManagedObjectContext:self.managedObjectContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(entity.class)];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", @5];
    
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    
    STAssertNil(error, @"error while fetching");
    STAssertTrue(objects.count == 1, @"only one object should be in the database");
}

- (void)testUpdateWithBadJSONObject
{
    NSURL *URL = [[NSBundle bundleForClass:self.class] URLForResource:@"BADAPISampleEntity" withExtension:@"json"];
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                                                   options:0
                                                                     error:NULL];
    
    // update one entity with id 5
    TTEntity1 *entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                               inManagedObjectContext:self.managedObjectContext];
    
    STAssertNil(entity.someString, @"some_string is badly formatted => entity.someString should not be set (%@)", entity);
    STAssertNil(entity.someDate, @"some_date is badly formatted => entity.someDate should not be set (%@)", entity.someDate);
}

- (void)testUpdateWithJSONObjectWithoutID
{
    NSURL *URL = [[NSBundle bundleForClass:self.class] URLForResource:@"SampleEntityWithoutID" withExtension:@"json"];
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                                                   options:0
                                                                     error:NULL];
    
    // update one entity with id 5
    TTEntity1 *entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                               inManagedObjectContext:self.managedObjectContext];
    
    STAssertNil(entity, @"JSON object without id should not create a CoreData object: %@", entity);
}

- (void)testURLSubstitution
{
    NSURL *URL = [[NSBundle bundleForClass:self.class] URLForResource:@"APISampleEntity" withExtension:@"json"];
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:URL]
                                                                   options:0
                                                                     error:NULL];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = [SLObjectConverter defaultDateTimeFormat];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    // update one entity with id 5
    TTEntity1 *entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                               inManagedObjectContext:self.managedObjectContext];
    
    URL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/:id/bla"];
    URL = [URL URLBySubstitutingAttributesWithManagedObject:entity];
    NSURL *expectedURL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/5/bla"];
    STAssertEqualObjects(URL, expectedURL, @":id substitution not working");
    
    URL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/:id/:some_string"];
    URL = [URL URLBySubstitutingAttributesWithManagedObject:entity];
    expectedURL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/5/String"];
    STAssertEqualObjects(URL, expectedURL, @":id and :some_string substitution not working");
    
    URL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/dashboard_content_containers/:id/workflows?updated_at=:some_date"];
    URL = [URL URLBySubstitutingAttributesWithManagedObject:entity];
    expectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:3000/api/dashboard_content_containers/5/workflows?updated_at=%@", [dateFormatter stringFromDate:entity.someDate]]];
    STAssertEqualObjects(URL, expectedURL, @":some_date substitution not working");
}

- (void)testInheritedModelShouldInheritMappingAndObjectConverter
{
    SLAttributeMapping *workflowSubclassAttributeMapping = [TTWorkflowSubsclass attributeMapping];
    
    STAssertEqualObjects([workflowSubclassAttributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"subclassAttribute"], @"__subclass_attribute", @"subclassAttribute wrong");
    STAssertEqualObjects([workflowSubclassAttributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"name"], @"__name", @"mapping model of super class not onherited");
    STAssertEqualObjects([workflowSubclassAttributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"blabla"], @"blabla2", @"mapping model of subsclass should bind stronger than mapping model of super class");
    
    SLObjectConverter *subclassObjectConverter = [TTWorkflowSubsclass objectConverter];
    
    NSString *convertedName = [subclassObjectConverter managedObjectObjectFromJSONObjectObject:@"string" forManagedObjectAttribute:@"subclassAttribute"];
    STAssertEqualObjects(convertedName, @"string", @"validation model not working for subclassAttribute");
    
    convertedName = [subclassObjectConverter managedObjectObjectFromJSONObjectObject:@"stringor" forManagedObjectAttribute:@"name"];
    STAssertEqualObjects(convertedName, @"stringor", @"validation model not working for name attribute from super class");
}

- (void)testRelationshipObjectDispatch
{
    NSMutableDictionary *dashboardJSONDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    @5, @"id",
                                                    @"old name", @"name",
                                                    nil];
    TTDashboard *dashboard = [TTDashboard updatedObjectWithRawJSONDictionary:dashboardJSONDictionary
                                                      inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(dashboard, @"dashboard cannot be nil");
    STAssertEqualObjects(dashboard.name, @"old name", @"name wrong");
    STAssertEqualObjects(dashboard.identifier, @5, @"identifier wrong");
    
    dashboardJSONDictionary[@"name"] = @"name";
    TTDashboard *newDashboard = [TTDashboard updatedObjectWithRawJSONDictionary:dashboardJSONDictionary
                                                         inManagedObjectContext:self.managedObjectContext];
    
    STAssertEquals(newDashboard, dashboard, @"same id should update same object");
    STAssertEqualObjects(newDashboard.name, @"name", @"name wrong");
    
    //    @property (nonatomic, retain) NSString * name;                <-- __name
    //    @property (nonatomic, retain) NSString * type;                <-- type
    //    @property (nonatomic, strong) NSNumber *identifier;           <-- id
    //    @property (nonatomic, retain) NSString * subclassAttribute;   <-- __subclass_attribute
    NSDictionary *workflow1 = @{
                                @"__name": @"workflow1",
                                @"type": @"plain",
                                @"id": @1
                                };
    NSDictionary *workflow2 = @{
                                @"__name": @"workflow2",
                                @"type": @"subclass",
                                @"id": @2,
                                @"__subclass_attribute": @"some value"
                                };
    
    NSArray *JSONArray = @[ workflow1, workflow2 ];
    NSError *error = nil;
    NSArray *updatedObjects = [dashboard updateObjectsForRelationship:@"workflows"
                                                       withJSONObject:JSONArray
                                                              fromURL:nil
                                               deleteEveryOtherObject:YES
                                                                error:&error];
    STAssertNil(error, @"error while updating workflows %@", error);
    
    STAssertEquals(updatedObjects.count, 2u, @"two objects should be updated");
    TTWorkflow *managedWorkflow1 = updatedObjects[0];
    TTWorkflowSubsclass *managedWorkflow2 = updatedObjects[1];
    
    STAssertEqualObjects(managedWorkflow1.class, TTWorkflow.class, @"managedWorkflow1 has wrong class");
    STAssertEqualObjects(managedWorkflow1.name, @"workflow1", @"name wrong");
    STAssertEqualObjects(managedWorkflow1.type, @"plain", @"type wrong");
    STAssertEqualObjects(managedWorkflow1.identifier, @1, @"id wrong");
    
    STAssertEqualObjects(managedWorkflow2.class, TTWorkflowSubsclass.class, @"managedWorkflow2 has wrong class");
    STAssertEqualObjects(managedWorkflow2.name, @"workflow2", @"name wrong");
    STAssertEqualObjects(managedWorkflow2.type, @"subclass", @"type wrong");
    STAssertEqualObjects(managedWorkflow2.identifier, @2, @"id wrong");
    STAssertEqualObjects(managedWorkflow2.subclassAttribute, @"some value", @"subclassAttribute wrong");
    
    NSMutableArray *newObjects = [NSMutableArray arrayWithCapacity:newDashboard.workflows.count];
    for (id object in newDashboard.workflows) {
        [newObjects addObject:object];
    }
    [newObjects sortUsingComparator:^NSComparisonResult(TTWorkflow *obj1, TTWorkflow *obj2) {
        return [obj1.identifier compare:obj2.identifier];
    }];
    updatedObjects = newObjects;
    STAssertEquals(updatedObjects.count, 2u, @"two objects should be updated");
    managedWorkflow1 = updatedObjects[0];
    managedWorkflow2 = updatedObjects[1];
    
    STAssertEqualObjects(managedWorkflow1.class, TTWorkflow.class, @"managedWorkflow1 has wrong class");
    STAssertEqualObjects(managedWorkflow1.name, @"workflow1", @"name wrong");
    STAssertEqualObjects(managedWorkflow1.type, @"plain", @"type wrong");
    STAssertEqualObjects(managedWorkflow1.identifier, @1, @"id wrong");
    
    STAssertEqualObjects(managedWorkflow2.class, TTWorkflowSubsclass.class, @"managedWorkflow2 has wrong class");
    STAssertEqualObjects(managedWorkflow2.name, @"workflow2", @"name wrong");
    STAssertEqualObjects(managedWorkflow2.type, @"subclass", @"type wrong");
    STAssertEqualObjects(managedWorkflow2.identifier, @2, @"id wrong");
    STAssertEqualObjects(managedWorkflow2.subclassAttribute, @"some value", @"subclassAttribute wrong");
    
    NSURL *URL = [NSURL URLWithString:@"http://0.0.0.0:3000/api/root/:dashboard.name/bla"];
    URL = [URL URLBySubstitutingAttributesWithManagedObject:managedWorkflow1];
    NSURL *expectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:3000/api/root/%@/bla", managedWorkflow1.dashboard.name]];
    STAssertEqualObjects(URL, expectedURL, @"keypath substitution not working");
}

- (void)testUnregisteredAttributes
{
    NSDictionary *JSONDictionary = @{
                                     @"id": @1331275,
                                     @"unregistered_value": @"this should not be there"
                                     };
    
    TTEntity1 *entity = [TTEntity1 updatedObjectWithRawJSONDictionary:JSONDictionary
                                               inManagedObjectContext:self.managedObjectContext];
    STAssertNil(entity.unregisteredValue, @"unregisteredValue should not be set.");
}

- (void)testNamingConventions
{
    SLAttributeMapping *attributeMapping = [TTEntity1 attributeMapping];
    
    NSString *attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"printer_id_blubb"];
    NSString *expectedAttributeName = @"printerIdentifierBlubb";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"oli_lett_bar"];
    expectedAttributeName = @"oliverLettererBar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"oli_letterer_bar"];
    expectedAttributeName = @"oliLettererBar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_oli_lett_bar"];
    expectedAttributeName = @"fooOliverLettererBar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_imoli_lett_bar"];
    expectedAttributeName = @"fooImoliLettBar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_oli_lett"];
    expectedAttributeName = @"fooOliverLetterer";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertJSONObjectAttributeToManagedObjectAttribute:@"foo_myoli_lett"];
    expectedAttributeName = @"fooMyoliLett";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"printerIdentifierBlubb"];
    expectedAttributeName = @"printer_id_blubb";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"oliverLettererBar"];
    expectedAttributeName = @"oli_lett_bar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"oliverLetterererBar"];
    expectedAttributeName = @"oliver_lettererer_bar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooOliverLettererBar"];
    expectedAttributeName = @"foo_oli_lett_bar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooImoliLettBar"];
    expectedAttributeName = @"foo_imoli_lett_bar";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooOliverLetterer"];
    expectedAttributeName = @"foo_oli_lett";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
    
    attributeName = [attributeMapping convertManagedObjectAttributeToJSONObjectAttribute:@"fooOliverLettererer"];
    expectedAttributeName = @"foo_oliver_lettererer";
    STAssertEqualObjects(attributeName, expectedAttributeName, @"naming conventions not working");
}

- (void)testUpdatedObjectWithStringTypeIdentifier
{
    NSDictionary *dictionary = @{
                                 @"id": @"oliver",
                                 @"name": @"letterer"
                                 };
    
    Entity3 *entity = [Entity3 updatedObjectWithRawJSONDictionary:dictionary
                                           inManagedObjectContext:self.managedObjectContext];
    
    STAssertNotNil(entity, @"no entity found");
    STAssertEqualObjects(entity.identifier, @"oliver", @"identifier wrong");
    STAssertEqualObjects(entity.name, @"letterer", @"name wrong");
    
    Entity3 *fetchedEntity = [Entity3 objectWithRemoteIdentifier:@"oliver"
                                          inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(fetchedEntity, @"no entity found");
    STAssertEqualObjects(fetchedEntity.identifier, @"oliver", @"identifier wrong");
    STAssertEqualObjects(fetchedEntity.name, @"letterer", @"name wrong");
}

- (void)testUpdatedObjectWithStringAsCustomUniqueTypeIdentifier
{
    NSDictionary *dictionary = @{
                                 @"unique_client_id": @"oliver",
                                 @"name": @"letterer"
                                 };
    
    Entity4 *entity = [Entity4 updatedObjectWithRawJSONDictionary:dictionary
                                           inManagedObjectContext:self.managedObjectContext];
    
    STAssertNotNil(entity, @"no entity found");
    STAssertEqualObjects(entity.uniqueClientIdentifier, @"oliver", @"identifier wrong");
    STAssertEqualObjects(entity.name, @"letterer", @"name wrong");
    
    Entity4 *fetchedEntity = [Entity4 objectWithRemoteIdentifier:@"oliver"
                                          inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(fetchedEntity, @"no entity found");
    STAssertEqualObjects(fetchedEntity.uniqueClientIdentifier, @"oliver", @"identifier wrong");
    STAssertEqualObjects(fetchedEntity.name, @"letterer", @"name wrong");
}

- (void)testAutoOneToOneRelationshipUpdateWithIdentifier
{
    NSDictionary *dictionary1 = @{
                                  @"id": @1,
                                  @"name": @"parent"
                                  };
    
    EntityOneToOne1 *parentEntity = [EntityOneToOne1 updatedObjectWithRawJSONDictionary:dictionary1
                                                                 inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(parentEntity, @"");
    
    NSDictionary *dictionary2 = @{
                                  @"id": @1,
                                  @"name": @"parent",
                                  @"parent_entity_id": @1
                                  };
    
    EntityOneToOne2 *childEntity = [EntityOneToOne2 updatedObjectWithRawJSONDictionary:dictionary2
                                                                inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(childEntity, @"");
    STAssertEqualObjects(childEntity.parentEntity, parentEntity, @"auto relationship update with XXX_id not working");
}

- (void)testAutoOneToOneRelationshipUpdateWithAttachedObject
{
    NSDictionary *dictionary = @{
                                 @"id": @2,
                                 @"name": @"parent",
                                 @"child_entity": @{
                                         @"id": @2,
                                         @"name": @"child"
                                         }
                                 };
    
    EntityOneToOne1 *parentEntity = [EntityOneToOne1 updatedObjectWithRawJSONDictionary:dictionary
                                                                 inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(parentEntity, @"");
    STAssertNotNil(parentEntity.childEntity, @"childEntity should be created automatically");
    STAssertEqualObjects(parentEntity.childEntity.name, @"child", @"");
}

- (void)testAutoRelationshipSettingWithExistingStoredIdentifier
{
    NSDictionary *dictionary1 = @{
                                  @"id": @3,
                                  @"name": @"parent",
                                  @"child_entity_id": @3
                                  };
    
    EntityOneToOne1 *parentEntity = [EntityOneToOne1 updatedObjectWithRawJSONDictionary:dictionary1
                                                                 inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(parentEntity, @"");
    STAssertNil(parentEntity.childEntity, @"");
    STAssertEqualObjects(parentEntity.childEntityIdentifier, @3, @"");
    
    NSDictionary *dictionary2 = @{
                                  @"id": @3,
                                  @"name": @"parent"
                                  };
    
    EntityOneToOne2 *childEntity = [EntityOneToOne2 updatedObjectWithRawJSONDictionary:dictionary2
                                                                inManagedObjectContext:self.managedObjectContext];
    STAssertNotNil(childEntity, @"");
    STAssertEqualObjects(childEntity, parentEntity.childEntity, @"relationship should be set automatically after object has been updated");
}

@end
