/* 

 NSArray+ConcurrencyAdditions.h
 
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

#import <Foundation/Foundation.h>

/*
 Block typedef for creating an object at a given index.
 You should return an autoreleased object in your populator.
 To use:
 
 SSPopulator populator = ^SSPopulator(NSUInteger number){
	return [NSNumber numberWithInt:(2*number + 1)];
 }
 */
typedef NSObject* (^SSPopulator)(NSUInteger index);

/*
 These methods create or modify an existing array using a
 populator block. Supply NSEnumerationConcurrent for options
 to use Grand Central Dispatch to create objects concurrently,
 or supply 0 to create objects serially.
 */
@interface NSArray (ConcurrencyAdditions)

+(NSArray *)SS_arrayWithCount:(NSUInteger)count
				  withOptions:(NSEnumerationOptions)options
					populator:(SSPopulator)populator;

-(id)SS_arrayByAddingCount:(NSUInteger)count 
			   withOptions:(NSEnumerationOptions)options 
				 populator:(SSPopulator)populator;

-(id)SS_arrayByInsertingCount:(NSUInteger)count 
					  atIndex:(NSUInteger)index 
				  withOptions:(NSEnumerationOptions)options 
					populator:(SSPopulator)populator;
@end

@interface NSMutableArray (ConcurrencyAdditions)

-(void)SS_addCount:(NSUInteger)count
	   withOptions:(NSEnumerationOptions)options 
		 populator:(SSPopulator)populator;

-(void)SS_insertCount:(NSUInteger)count
			  atIndex:(NSUInteger)index
		  withOptions:(NSEnumerationOptions)options 
			populator:(SSPopulator)populator;

@end