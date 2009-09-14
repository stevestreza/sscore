//
//  ArrayConcurrencyAdditionsTest.h
//  ConcurrencyExtensions
//
//  Created by Steve Streza on 9/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "NSArray+ConcurrencyAdditions.h"


@interface ArrayConcurrencyAdditionsTest : SenTestCase {

}

-(NSArray *)dumbArrayWithCount:(NSUInteger)count 
					 populator:(SSPopulator)populator;
-(void)runTestWithCount:(NSUInteger)count 
			  populator:(SSPopulator)populator;
@end
