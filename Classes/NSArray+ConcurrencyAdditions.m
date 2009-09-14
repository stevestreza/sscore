/* 

 NSArray+ConcurrencyAdditions.m
 
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

#import "NSArray+ConcurrencyAdditions.h"
#import <dispatch/dispatch.h>

@implementation NSArray (ConcurrencyAdditions)

+(NSArray *)SS_arrayWithCount:(NSUInteger)count 
				  withOptions:(NSEnumerationOptions)options
					populator:(SSPopulator)populator{
	
	NSAutoreleasePool *pool = [NSAutoreleasePool new];

	dispatch_queue_t dispatchQueue = NULL;

	if(options != NSEnumerationConcurrent){
//		NSLog(@"Using serial queue");
		dispatchQueue = dispatch_queue_create("com.stevestreza.nsarray.serial", 0);
	}else{
//		NSLog(@"Using concurrent queue");
		dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_retain(dispatchQueue);
	}
	
	if(!dispatchQueue) return nil;
	
	NSObject **objectArray = calloc(sizeof(NSObject *),count);
	
	dispatch_apply((size_t)count, dispatchQueue, ^(size_t index){
		NSObject *object = populator(index);
		objectArray[index] = [object retain]; // we release the object again at the end of the method
	});
	
	dispatch_release(dispatchQueue);
	dispatchQueue = NULL;
	
	NSArray *retArray = [[self arrayWithObjects:objectArray count:count] retain];
	
	[pool drain];
	free(objectArray);

	[retArray autorelease];

	[retArray makeObjectsPerformSelector:@selector(release)];
	return retArray;
}

-(id)SS_arrayByAddingCount:(NSUInteger)count
			   withOptions:(NSEnumerationOptions)options 
				 populator:(SSPopulator)populator{
	
	NSArray *newArray = [NSArray SS_arrayWithCount:count
									   withOptions:options
										 populator:populator];
	return [self arrayByAddingObjectsFromArray:newArray];
}

-(id)SS_arrayByInsertingCount:(NSUInteger)count
					  atIndex:(NSUInteger)index
				  withOptions:(NSEnumerationOptions)options
					populator:(SSPopulator)populator{
	
	NSMutableArray *array = [[self mutableCopy] autorelease];
	[array SS_insertCount:count
				  atIndex:index
			  withOptions:options
				populator:populator];
	return array;
}

@end

@implementation NSMutableArray (ConcurrencyAdditions)

-(void)SS_addCount:(NSUInteger)count
	   withOptions:(NSEnumerationOptions)options
		 populator:(SSPopulator)populator{
	
	[self addObjectsFromArray:[NSArray SS_arrayWithCount:count 
											 withOptions:options
											   populator:populator]];
}

-(void)SS_insertCount:(NSUInteger)count
			  atIndex:(NSUInteger)index
		  withOptions:(NSEnumerationOptions)options
			populator:(SSPopulator)populator{
	
	[self insertObjects:[NSArray SS_arrayWithCount:count 
									   withOptions:options
										 populator:populator]
			  atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, index+count)]];
}

@end
