//
//  NSArray+ConcurrencyAdditions.h
//  ConcurrencyExtensions
//
//  Created by Steve Streza on 9/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSObject* (^SSPopulator)(NSUInteger index);

@interface NSArray (ConcurrencyAdditions)

+(NSArray *)SS_arrayWithCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator;

-(id)SS_arrayByAddingCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator;
-(id)SS_arrayByInsertingCount:(NSUInteger)count atIndex:(NSUInteger)index withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator;

@end

@interface NSMutableArray (ConcurrencyAdditions)

-(void)SS_addCount:(NSUInteger)count withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator;
-(void)SS_insertCount:(NSUInteger)count atIndex:(NSUInteger)index withOptions:(NSEnumerationOptions)options populator:(SSPopulator)populator;

@end