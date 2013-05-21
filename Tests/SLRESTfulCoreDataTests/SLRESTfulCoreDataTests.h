//
//  SLRESTfulCoreDataTests.h
//  SLRESTfulCoreData
//
//  Created by Oliver Letterer on 20.05.13.
//  Copyright 2013 Sparrow-Labs. All rights reserved.
//

#import "SLRESTfulCoreData.h"
#import "SLCoreDataStack.h"



@interface SLTestDataStore : SLCoreDataStack @end
@interface SLTestBackgroundQueue : NSObject <SLRESTfulCoreDataBackgroundQueue> @end
