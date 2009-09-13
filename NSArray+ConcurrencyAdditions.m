//
//  NSArray+ConcurrencyAdditions.m
//  ConcurrencyExtensions
//
//  Created by Steve Streza on 9/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ConcurrencyAdditions.h"
#import <dispatch/dispatch.h>

@implementation NSArray (ConcurrencyAdditions)

+(NSArray *)SS_arrayWithCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator{
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
	
	NSPointerArray *pointers = [NSPointerArray pointerArrayWithWeakObjects];
	[pointers setCount:count];
	
	NSObject **objectArray = calloc(sizeof(NSObject *),count);
	
	__block NSUInteger ticks = 0;
	
//	NSLog(@"Adding operations");
	dispatch_apply((size_t)count, dispatchQueue, ^(size_t index){
		NSObject *object = populator(index);
//		NSLog(@"Inserting object at index: %i - %@", index, object);
		objectArray[index] = [object retain];
	});
//	NSLog(@"Done adding operations");
	
	dispatch_release(dispatchQueue);
	
//	NSLog(@"1) Retain count %i, ",[objectArray[5] retainCount]);
	NSArray *retArray = [[NSArray arrayWithObjects:objectArray count:count] retain];
//	NSLog(@"2) Retain count %i, ",[[retArray objectAtIndex:5] retainCount]);
	
	[pool drain];
	free(objectArray);

	[retArray autorelease];

//	NSLog(@"3) Retain count %i, %i",[[retArray objectAtIndex:5] retainCount], [retArray count]);
	[retArray makeObjectsPerformSelector:@selector(release)];

	return retArray;
}

-(id)SS_arrayByAddingCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator{
	NSArray *newArray = [NSArray SS_arrayWithCount:count withOptions:options populator:populator];
	return [self arrayByAddingObjectsFromArray:newArray];
}

-(id)SS_arrayByInsertingCount:(NSUInteger)count atIndex:(NSUInteger)index withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator{
	return nil;
}

@end

@implementation NSMutableArray (ConcurrencyAdditions)

-(void)SS_addCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator{
	[self addObjectsFromArray:[NSArray SS_arrayWithCount:count withOptions:options populator:populator]];
}

-(void)SS_insertCount:(NSUInteger)count atIndex:(NSUInteger)index withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator{
	[self insertObjects:[NSArray SS_arrayWithCount:count withOptions:options populator:populator]
			  atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, index+count)]];
}

@end
