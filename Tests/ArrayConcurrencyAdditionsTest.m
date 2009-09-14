//
//  ArrayConcurrencyAdditionsTest.m
//  ConcurrencyExtensions
//
//  Created by Steve Streza on 9/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ArrayConcurrencyAdditionsTest.h"

@implementation ArrayConcurrencyAdditionsTest

#pragma mark Unit Tests

-(void)testDoublesArray{
	[self runTestWithCount:1000 populator:(SSPopulator)^(NSUInteger index){
		return [NSNumber numberWithInt:index * 2]; 
	}];
}

-(void)testAlphabet{
	[self runTestWithCount:52 populator:(SSPopulator)^(NSUInteger index){
		char code = index;
		if(index < 26){
			code += 65;
		}else{
			code -= 26;
			code += 97;
		}
		return [[[NSString alloc] initWithBytes:&code length:1 encoding:NSASCIIStringEncoding] autorelease];
	}];
}

#pragma mark Accessory Methods

-(NSArray *)dumbArrayWithCount:(NSUInteger)count 
					 populator:(SSPopulator)populator{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];

	NSUInteger index=0;
	for(index; index<count; index++){
		[array addObject:populator(index)];
	}
	
	return array;
}

-(void)runTestWithCount:(NSUInteger)count populator:(SSPopulator)populator{
	NSArray *desiredResult = [self dumbArrayWithCount:count populator:populator];
//	NSLog(@"desired: %@",desiredResult);
	
	NSArray *result = [NSArray SS_arrayWithCount:count
									 withOptions:0
									   populator:populator];
	
	STAssertNotNil(result, @"serial result array is nil");
	STAssertTrue([result isEqualToArray:desiredResult], @"serial result array is not equal to real results");
	
	result = [NSArray SS_arrayWithCount:count
							withOptions:NSEnumerationConcurrent
							  populator:populator];
	
	STAssertNotNil(result, @"concurrent result array is nil");
	STAssertTrue([result isEqualToArray:desiredResult], @"concurrent result array is not equal to real results");
}

@end
