//
//  SSListContainerView.h
//  SSListView
//
//  Created by Steve Streza on 1/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SSListContainerView : NSView {
	id mRepresentedObject;
	
	NSUInteger rowIndex;
}

@property (assign) NSUInteger rowIndex;
@property (retain) id representedObject;

@end
