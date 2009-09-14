//
//  TCMasterDetailCell.h
//  Technicolor
//
//  Created by Steve Streza on 12/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCMasterDetailCell : NSActionCell {
	NSString *primaryKey;
	NSString *secondaryKey;
}
@property (copy) NSString *primaryKey;
@property (copy) NSString *secondaryKey;
-(void)drawBackgroundIfNeededInRect:(NSRect)drawRect;
@end
