/* 
 
 ArrayConcurrencyAdditionsTest.m
 
 Copyright (c) 2009 Steve Streza
 Licensed under the MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

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
