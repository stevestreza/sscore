//
//  TCListView.h
//  Technicolor
//
//  Created by Steve Streza on 12/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SSListContainerView.h"

#define SSListViewDelegateInsertionMode 1

#ifdef SSListViewDelegateInsertionMode

@class SSListView;
@protocol SSListViewDataSource

@required
-(NSUInteger)numberOfRowsInListView:(SSListView *)listView;
-(id)listView:(SSListView *)listView objectForRowAtIndex:(NSUInteger)index;
-(SSListContainerView *)listView:(SSListView *)listView viewForObject:(id)object atRow:(NSUInteger)index;

@optional
-(double)listView:(SSListView *)listView heightForRow:(NSUInteger)index;

@end

#endif

typedef struct {
	NSUInteger count;
	SSListContainerView **array;
} SSListCache;

@interface SSListView : NSView {
	IBOutlet NSScrollView *mParentScrollView;
	
	NSMutableArray *mRows;
	NSUInteger mSelectedRow;
	
	NSMutableSet *unusedCellQueue;
	
	
#ifdef SSListViewDelegateInsertionMode
	id<SSListViewDataSource> mDataSource;
	
	SSListCache containerViewCache;
//	NSMutableDictionary *containerViewCache;
#endif
	
}

#ifdef SSListViewDelegateInsertionMode
@property (assign) id dataSource;
#endif

@property NSUInteger selectedRow;
@property (readonly) NSScrollView *scrollView;

-(void)addRow:(SSListContainerView *)row;
-(void)insertRow:(SSListContainerView *)row atIndex:(NSUInteger)index;

-(void)removeRowAtIndex:(NSUInteger)index;
-(void)removeAllRows;

-(NSRect)frameForRowAtIndex:(NSUInteger)index;
-(NSSize)totalContentSize;

-(NSUInteger)indexOfPoint:(NSPoint)pt;
-(NSIndexSet *)displayingRows;

-(void)drawGridInRect:(NSRect)theRect;
-(void)drawGridLineAtY:(float)y width:(float)width;
-(void)drawSelectedBackgroundInRect:(NSRect)rect;

-(NSRect)visibleRect;
-(SSListContainerView *)dequeueCell;
-(NSView *)parentScrollView;

-(void)reloadData;
-(NSIndexSet *)reloadRowHeights;
-(NSIndexSet *)reloadRowHeightsWithTotalHeight:(double *)height;
@end
