//
//  SSListContainerView.m
//  SSListView
//
//  Created by Steve Streza on 1/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SSListContainerView.h"


@implementation SSListContainerView

@synthesize representedObject=mRepresentedObject, rowIndex;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

@end
