//
//  TCListView.m
//  Technicolor
//
//  Created by Steve Streza on 12/20/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SSListView.h"

@interface SSListView (Private)

-(id)_wrapWithScrollView;
-(void)_updateScrollView;
-(double)_getHeightForRowAtIndex:(NSUInteger)index;

#ifdef SSListViewDelegateInsertionMode
-(NSUInteger)_getNumberOfRows;
-(id)_getObjectAtRow:(NSUInteger)row;
-(SSListContainerView *)_containerViewForObject:(id)object atRow:(NSUInteger)index;
#endif

@end

@class SSListContainerView;

@implementation SSListView

@synthesize scrollView=mParentScrollView, selectedRow=mSelectedRow;

#ifdef SSListViewDelegateInsertionMode
@synthesize dataSource=mDataSource;
#endif

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		mSelectedRow = NSNotFound;

		mRows = [[NSMutableArray alloc] init];
		[self setPostsFrameChangedNotifications:YES];
		
		unusedCellQueue = [[NSMutableSet alloc] init];
		
#ifdef SSListViewDelegateInsertionMode
//		containerViewCache = [[NSMutableDictionary dictionary] retain];
		containerViewCache.count = 512;
		containerViewCache.array = malloc(containerViewCache.count * sizeof(char*));
		bzero(containerViewCache.array, containerViewCache.count * sizeof(char*));
#endif
    }
    return self;
}

-(void)viewDidMoveToSuperview{
	[self _wrapWithScrollView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSViewBoundsDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsChanged:) name:NSViewFrameDidChangeNotification object:self];
}

-(void)boundsChanged:(NSNotification *)notif{
	[notif object];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"documentVisibleRect"]) {
		printf("WOOOO\n");
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

-(NSView *)parentScrollView{
	if(!mParentScrollView){
		[self _wrapWithScrollView];
	}
	return mParentScrollView;
}

-(id)_wrapWithScrollView{
	if(!mParentScrollView){
		[self retain];

		NSView *superview = [self superview];
		if(!superview) return;
		NSUInteger index = [[[self superview] subviews] indexOfObject:self];
		
		mParentScrollView = [[NSScrollView alloc] initWithFrame:[self frame]];
		[mParentScrollView setDrawsBackground:NO];
		[mParentScrollView setAutoresizingMask:[self autoresizingMask]];

		self.frame = mParentScrollView.bounds;
		[self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[superview replaceSubview:self with:mParentScrollView];
		[[mParentScrollView contentView] addSubview:self];

		[self release];
	}
	return mParentScrollView;
}

-(BOOL)isFlipped{
	return YES;
}

-(void)mouseDown:(NSEvent *)e{
	
}

-(void)mouseUp:(NSEvent *)e{
	NSPoint location = [self convertPoint:[e locationInWindow] fromView:nil];
//	self.selectedRow = [self indexOfPoint:location];
}

-(NSUInteger)indexOfPoint:(NSPoint)pt{
	if(mRows.count == 0) return NSNotFound;
	
	NSUInteger index = 0;
	for(index; index < mRows.count; index++){
		NSRect rect = [(NSView *)[mRows objectAtIndex:index] frame];
		if(NSPointInRect(pt, rect)){
			return index;
		}
	}
}

-(void)_updateScrollView{
	NSSize size = [self totalContentSize];
	size.width = self.frame.size.width;
//	[self setFrameSize:size];
}

-(NSSize)totalContentSize{
	//we can cheat here and assume all views are in the correct location
	NSView *view = [mRows lastObject];
	NSSize frameSize = view.frame.size;
	
	frameSize.height = view.frame.origin.y + frameSize.height;
	return frameSize;
}

-(NSRect)visibleRect{
	return [self superview].bounds;
}

-(NSIndexSet *)displayingRows{
	NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
	
	NSUInteger rowCount = NSNotFound;
#if SSListViewDelegateInsertionMode
	rowCount = [self _getNumberOfRows];
#else
	rowCount = mRows.count;
#endif
	if(rowCount > 0){
		NSRect bounds = [self visibleRect];
		
		NSUInteger index = 0;
		for(index; index < rowCount; index++){
			NSRect frame = [self frameForRowAtIndex:index];
			if(NSIntersectsRect(bounds, frame)){
				[set addIndex:index];
			}else if([set count] > 0){
				break;
			}
		}
	}
	
	return [[set copy] autorelease];
}

-(NSIndexSet *)onscreenRows{
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	for(SSListContainerView *view in self.subviews){
		NSUInteger index = [view rowIndex];
		[indexSet addIndex:index];
	}
	return [[indexSet copy] autorelease];
}

-(void)drawRect:(NSRect)theRect{
	[super drawRect:theRect];
	
	if(mSelectedRow != NSNotFound){
		NSRect selectionFrame = [self frameForRowAtIndex:mSelectedRow];
		
		if(NSIntersectsRect(selectionFrame, theRect)){
			[self drawSelectedBackgroundInRect:selectionFrame];
		}
	}
	
//	[self drawGridInRect:theRect];
}

-(void)drawGridInRect:(NSRect)theRect{
	NSIndexSet *set = [self displayingRows];
	if([set count] == 0) return;
	
	NSUInteger index = [set firstIndex];
	if(index == NSNotFound) return;
	
	[[NSColor grayColor] setStroke];
	do{
		NSRect frame = [self frameForRowAtIndex:index];
		if(frame.size.height < 1) break;
		float line = frame.origin.y + frame.size.height;
		
		[self drawGridLineAtY:line width:frame.size.width];
		
		index = [set indexGreaterThanIndex:index];
	}while(index != [set lastIndex]);
}

-(void)drawGridLineAtY:(float)y width:(float)width{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0,y+0.5)];
	[path lineToPoint:NSMakePoint(width,y+0.5)];
	
	[[NSColor darkGrayColor] setStroke];
	[path stroke];
}

//Override to provide custom cell selection behavior
-(void)drawSelectedBackgroundInRect:(NSRect)rect{
	[[NSColor selectedControlColor] setFill];
	[NSBezierPath fillRect:rect];
}

-(void)setSelectedRow:(NSUInteger)newRow{
	mSelectedRow = newRow;
	[self setNeedsDisplay:YES];
}

-(void)setBoundsOrigin:(NSPoint)newBounds{
	[super setBoundsOrigin:newBounds];
}

-(void)setFrame:(NSRect)newFrame{
	[super setFrame:newFrame];
	
	[self updateSubviewFrames];
}

-(void)logFramesOfView:(NSView *)view depth:(NSString *)depth{
	NSLog(@"%@Frame: %@",depth, NSStringFromRect(view.frame));
	depth = [depth stringByAppendingString:@" "];
	for(NSView *subview in view.subviews){
		[self logFramesOfView:subview depth:depth];
	}
}

#if SSListViewDelegateInsertionMode
#pragma mark Delegate Insertion
-(void)reloadData{
	if(![NSThread isMainThread]){
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
		return;
	}
	
	for(NSView *view in [[self.subviews copy] autorelease]){
		[view removeFromSuperview];
	}
	
	double offset = 0.;
	NSIndexSet *addedRows = [self reloadRowHeightsWithTotalHeight:&offset];
	
	[self _insertRowsAtIndexSet:addedRows];
	
	NSRect viewFrame = [self frame];
	viewFrame.size.height = offset;
	NSLog(@"setting view fraem to %@",NSStringFromRect(viewFrame));
	[super setFrame:viewFrame];	
	
	[self setNeedsDisplay:YES];
	[self _updateScrollView];
	[self updateSubviewFrames];
	
fail:
	return;
}

-(NSIndexSet *)reloadRowHeights{
	return [self reloadRowHeightsWithTotalHeight:NULL];
}

-(NSIndexSet *)reloadRowHeightsWithTotalHeight:(double *)height{
	NSMutableIndexSet *addedRows = [NSMutableIndexSet indexSet];
	NSRect visibleRect = [self visibleRect];
	NSUInteger count = [self _getNumberOfRows];
	
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)];
	
#if kBNUseBlocks
	__block double offset = 0.;
	[indexSet enumerateIndexesWithOptions:NSEnumerationConcurrent
							   usingBlock:^(NSUInteger index, BOOL *stop){
#else
	double offset = 0.;
	NSUInteger index = 0;
	for(index; index < count; index++){
#endif
		id obj = [self _getObjectAtRow:index];
		if(!obj){
#if kBNUseBlocks
			*stop = YES;
			return;
#else
			continue;
#endif
		}
		
		float height = [self.dataSource listView:self heightForRow:index];
		
		if((offset > visibleRect.origin.y || offset + height > visibleRect.origin.y) && (offset < visibleRect.origin.y + visibleRect.size.height)){
			   printf("Adding index %i\n",index);
			   [addedRows addIndex:index];
		}
		
		offset += height;
#if kBNUseBlocks
	}];	
#else
	}
#endif
	return addedRows;
}

-(NSRect)frameForRowAtIndex:(NSUInteger)index{
	NSUInteger count = [self _getNumberOfRows];
	if(index > count){
		goto fail;
	}
	
	NSRect realFrame = NSZeroRect;
	realFrame.origin.y = 0.;
	realFrame.size = self.frame.size;

	NSRect frame;
	NSUInteger i = 0;
	for(i; i < index; i++){
		if(index == count){
			realFrame.size.height = 0;
			break;
		}
		
//		id object = [self _getObjectAtRow:i];
//		if(!object) goto fail;
		
//		SSListContainerView *view = [self _containerViewForObject:object atRow:i createIfNeeded:NO];
//		if(!view) goto fail;
		
//		frame = [view frame];
//		float height = frame.size.height;
		float height = [self _getHeightForRowAtIndex:i];
		
		SSListContainerView *view = [self cachedContainerAtIndex:i];
		if(view){
			NSRect viewFrame = [view frame];
			if(viewFrame.origin.y != realFrame.origin.y){
				viewFrame.origin.y = realFrame.origin.y;
				viewFrame.size.height = height;
				[view setFrame:viewFrame];
			}
		}
		
		realFrame.origin.y = realFrame.origin.y + height;
//		realFrame.size.height = height;
	}
	realFrame.size.height = [self _getHeightForRowAtIndex:index];
	return realFrame;
fail:
	return NSZeroRect;
}

-(void)_insertRow:(SSListContainerView *)row atIndex:(NSUInteger)index{
}

-(SSListContainerView *)cachedContainerAtIndex:(NSUInteger)index{
	//return [containerViewCache objectForKey:[NSString stringWithFormat:@"%i",index]];
	return (SSListContainerView *)(containerViewCache.array[index]);
}

-(void)insertContainer:(SSListContainerView *)container atIndex:(NSUInteger)index{
	
}

-(NSUInteger)_getNumberOfRows{
	if([mDataSource respondsToSelector:@selector(numberOfRowsInListView:)]){
		return [mDataSource numberOfRowsInListView:self];
	}else{
		return 0;
	}
}

-(id)_getObjectAtRow:(NSUInteger)row{
	if([mDataSource respondsToSelector:@selector(listView:objectForRowAtIndex:)]){
		return [mDataSource listView:self objectForRowAtIndex:row];
	}else{
		return nil;
	}	
}

-(SSListContainerView *)_containerViewForObject:(id)object atRow:(NSUInteger)index{
	return [self _containerViewForObject:object atRow:index createIfNeeded:YES];
}

-(SSListContainerView *)_containerViewForObject:(id)object atRow:(NSUInteger)index createIfNeeded:(BOOL)create{
	id container = [self cachedContainerAtIndex:index];
	if(!container && create && [mDataSource respondsToSelector:@selector(listView:viewForObject:atRow:)]){
		container = [mDataSource listView:self viewForObject:object atRow:index];
	}
	return container;
}
		
-(double)_getHeightForRowAtIndex:(NSUInteger)index{
	if(mDataSource && [mDataSource respondsToSelector:@selector(listView:heightForRow:)]){
		return [mDataSource listView:self heightForRow:index];
	}
	return 0.0;
}

-(void)updateSubviewFrames{
	NSIndexSet *visibleRows = [self displayingRows];
	NSUInteger index = [visibleRows firstIndex];
	while(index != NSNotFound){
		NSRect frame = [self frameForRowAtIndex:index];
		[[self cachedContainerAtIndex:index] setFrame:frame];
		
		index = [visibleRows indexGreaterThanIndex:index];
	}
}

-(void)scrollViewDidScroll:(NSScrollView *)scrollView{
	NSIndexSet *newVisibleRows = [self displayingRows];
	NSIndexSet *currentVisibleRows = [self onscreenRows];
	
	NSMutableIndexSet *needRemoveSet = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *needAddSet = [NSMutableIndexSet indexSet];
	
	NSUInteger index = 0;
	
	//if they are onscreen, they need removal
	index = [currentVisibleRows firstIndex];
	while(index != NSNotFound){
		if(![newVisibleRows containsIndex:index]){
//			printf("r:%i ",index);
			[needRemoveSet addIndex:index];
		}
//			else printf("nr:%i ",index);
		index = [currentVisibleRows indexGreaterThanIndex:index];
	}
	
	//if they are not onscreen, they need adding
	index = [newVisibleRows firstIndex];
	while(index != NSNotFound){
		if(![currentVisibleRows containsIndex:index]){
//			printf("a:%i ",index);
			[needAddSet addIndex:index];
		}
//			else printf("na:%i ",index);
		index = [newVisibleRows indexGreaterThanIndex:index];
	}
	
	index = [needRemoveSet lastIndex];
	while(index != NSNotFound){
		SSListContainerView *removeMe = [self cachedContainerAtIndex:index];
		if(removeMe){
			[unusedCellQueue addObject:removeMe];
		}
		[removeMe removeFromSuperview];
		
//		[containerViewCache removeObjectForKey:[NSString stringWithFormat:@"%i",index]];
		containerViewCache.array[index] = NULL;
		
		index = [needRemoveSet indexLessThanIndex:index];
	}

	[self _insertRowsAtIndexSet:needAddSet];
	
//	[self updateSubviewFrames];
}

-(SSListContainerView *)dequeueCell{
	if(unusedCellQueue.count > 0){
		SSListContainerView *cell = [[unusedCellQueue anyObject] retain];
		[unusedCellQueue removeObject:cell];
		
		return [cell autorelease];
	}
	return nil;
}

-(void)_insertRowsAtIndexSet:(NSIndexSet *)indexSet{
	NSDisableScreenUpdates();
	
	NSUInteger count = [self _getNumberOfRows];
#if kBNUseBlocks
	[indexSet enumerateIndexesWithOptions:NSEnumerationConcurrent | NSEnumerationReverse
							   usingBlock:^(NSUInteger index, BOOL *stop){
#else
	NSUInteger index = [indexSet lastIndex];
	while(index != NSNotFound){
#endif
		if(index < count){
			id obj = [self _getObjectAtRow:index];
			SSListContainerView *container = [self _containerViewForObject:obj atRow:index];
			if(!container){
#if !kBNUseBlocks
				goto fail;
#endif
			}else{
				
				container.rowIndex = index;
				
				NSRect containerFrame = [self frameForRowAtIndex:index];
				
				//			[containerViewCache setObject:container forKey:[NSString stringWithFormat:@"%i",index]];
				//			containerViewCache.array 
				if(index > containerViewCache.count){
					[self doubleListCacheArray];
				}
				containerViewCache.array[index] = [container retain];
				
				[container setFrame:containerFrame];
				[self addSubview:container];
			}
		}
#if kBNUseBlocks
	}];	
#else
		index = [indexSet indexLessThanIndex:index];
	}
#endif
fail:
	NSEnableScreenUpdates();
	return;
}
					
-(void)doubleListCacheArray{
	//needs resize
	NSUInteger total = containerViewCache.count;
	SSListContainerView **newArray = malloc(total * 2 * sizeof(SSListContainerView *));
	bzero(newArray, total*2*sizeof(SSListContainerView *));
	strcpy((char*)containerViewCache.array, (char*)newArray);
	
	free(containerViewCache.array);
	containerViewCache.array = newArray;
	
	containerViewCache.count *= 2;
}

#else
#pragma mark Manual Insertion (that's what she said!)

-(void)addRow:(SSListContainerView *)row{
	[self insertRow:row atIndex:mRows.count];
}

-(void)insertRow:(SSListContainerView *)row atIndex:(NSUInteger)index{
	if(index > mRows.count) index = mRows.count - 1;
	
	[row setRowIndex:index];
	
	[mRows insertObject:row atIndex:index];
	[self addSubview:row];
	[row setFrame:[self frameForRowAtIndex:index]];
	[row setAutoresizingMask:(NSViewWidthSizable & NSViewMaxYMargin)];
	
	[self _updateScrollView];
}

-(void)removeAllRows{
	while(mRows.count > 0) [self removeRowAtIndex:0];
}

-(void)removeRowAtIndex:(NSUInteger)index{
	if(index >= mRows.count) index = mRows.count - 1;
	
	[mRows removeObjectAtIndex:index];
	[[[self subviews] objectAtIndex:index] removeFromSuperview];
	
	[self _updateScrollView];
}

-(void)reloadData{
	
}

-(NSRect)frameForRowAtIndex:(NSUInteger)index{
	if(index >= mRows.count){
		return NSZeroRect;
	}
	
	NSView *indexedRow = [mRows objectAtIndex:index];
	NSRect frame = indexedRow.frame;
	frame.origin.y = 1.;
	frame.size.width = self.bounds.size.width;
	
	NSUInteger loopIndex=0;
	for(loopIndex; loopIndex<index; loopIndex++){
		NSView *view = [mRows objectAtIndex:loopIndex];
		frame.origin.y += view.frame.size.height + 1;
	}
	return NSIntegralRect(frame);
}

-(void)updateSubviewFrames{
	NSRect frame = NSMakeRec
	for(SSListContainerView *view in self.subviews){
		NSUInteger index = [view rowIndex];
		frame = [self frameForRowAtIndex:index];
		//		NSLog(@"Updating row frame for %i to %@",index,NSStringFromRect(frame));
		[view setFrame:frame];
	}
	
	NSRect viewFrame = [self frame];
	viewFrame.size.height = frame.origin.y;
	NSLog(@"setting view fraem to %@",NSStringFromRect(viewFrame));
	[super setFrame:viewFrame];
	
	/*	
	 NSIndexSet *indexes = [self displayingRows];
	 NSUInteger index = [indexes firstIndex];
	 
	 NSRect frame;
	 
	 while(index != NSNotFound){
	 frame = [self frameForRowAtIndex:index];
	 //		NSLog(@"Frame: %@",NSStringFromRect(frame));
	 #if SSListViewDelegateInsertionMode
	 id containerObject = [self _getObjectAtRow:index];
	 [[self _containerViewForObject:containerObject atRow:index] setFrame:frame];
	 #else
	 [[mRows objectAtIndex:index] setFrame:frame];		
	 #endif
	 index = [indexes indexGreaterThanIndex:index];
	 }
	 */
}


#endif

@end
