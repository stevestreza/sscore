//
//  TCMasterDetailCell.m
//  Technicolor
//
//  Created by Steve Streza on 12/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCMasterDetailCell.h"


@implementation TCMasterDetailCell

@synthesize primaryKey, secondaryKey;

static NSDictionary *sPrimaryAttribtues   = nil;
static NSDictionary *sSecondaryAttributes = nil;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	id obj = [self objectValue];
	
	NSString *primaryString = [obj valueForKey:primaryKey];
	if(![primaryString isKindOfClass:[NSString class]]){
		primaryString = [primaryString description];
	}
	
	NSString *secondaryString = [obj valueForKey:secondaryKey];
	if(![secondaryString isKindOfClass:[NSString class]]){
		secondaryString = [secondaryString description];
	}
	
	CGRect primaryRect = CGRectZero;
	CGRect secondaryRect = CGRectZero;
	
	CGRectDivide(NSRectToCGRect(cellFrame), &primaryRect, &secondaryRect, (cellFrame.size.height/2.), CGRectMinYEdge);
	
//	if(!sPrimaryAttribtues){
		sPrimaryAttribtues = [[[NSDictionary dictionaryWithObjectsAndKeys:
							  [[NSFontManager sharedFontManager] convertFont:[NSFont systemFontOfSize:12.] toHaveTrait:NSBoldFontMask], NSFontAttributeName,
								[self primaryColor], NSForegroundColorAttributeName,
							  nil] retain] autorelease];
//	}
	
//	if(!sSecondaryAttributes){
		sSecondaryAttributes = [[[NSDictionary dictionaryWithObjectsAndKeys:
//								 [[NSFontManager sharedFontManager] convertFont:
																				[NSFont systemFontOfSize:11.]
//																	toHaveTrait:NSBoldFontMask]
									, NSFontAttributeName,
								 [self secondaryColor], NSForegroundColorAttributeName,
								  nil] retain] autorelease];
//	}

	[self drawBackgroundIfNeededInRect:cellFrame];
	
	NSSize primarySize   = [primaryString   sizeWithAttributes:sPrimaryAttribtues];
	NSSize secondarySize = [secondaryString sizeWithAttributes:sSecondaryAttributes];
	
	  primaryRect.origin.y   += ((  primaryRect.size.height -   primarySize.height)/2.);
	secondaryRect.origin.y += ((secondaryRect.size.height - secondarySize.height)/2.);
	
	primaryRect.size.height = primarySize.height;
	secondaryRect.size.height = secondarySize.height;
	
	[  primaryString drawInRect: NSRectFromCGRect(primaryRect)   withAttributes:sPrimaryAttribtues];
	[secondaryString drawInRect: NSRectFromCGRect(secondaryRect) withAttributes:sSecondaryAttributes];
}

static NSGradient *sGradient = nil;
-(void)drawBackgroundIfNeededInRect:(NSRect)drawRect{
	return;
	
	if([self isHighlighted]){
		if(!sGradient){
			NSArray *colorArray = [NSArray arrayWithObjects:
								   [NSColor colorWithCalibratedWhite:0.3008 alpha:1.0],
								   [NSColor colorWithCalibratedWhite:0.2656 alpha:1.0],
								   [NSColor colorWithCalibratedWhite:0.1367 alpha:1.0],
								   [NSColor colorWithCalibratedWhite:0.0117 alpha:1.0],
								   nil];
			const CGFloat locations[] = { 0.0f, 0.49f, 0.5f, 1.0f };
			sGradient = [[NSGradient alloc] initWithColors:colorArray
											   atLocations:locations
												colorSpace:[NSColorSpace deviceRGBColorSpace]];
		}
		[sGradient drawInRect:drawRect angle:90.f];
	}
}

-(NSColor *)primaryColor{
	if([self isHighlighted]){
		return [NSColor whiteColor];
	}else{
		return [NSColor blackColor];
	}
}

-(NSColor *)secondaryColor{
	if([self isHighlighted]){
		return [NSColor colorWithCalibratedWhite:0.85 alpha:1];
	}else{
		return [NSColor colorWithCalibratedWhite:0.35 alpha:1];
	}
}


- (void)setObjectValue:(id )object {
	id oldObjectValue = [self objectValue];
	if (object != oldObjectValue) {
		[object retain];
		[oldObjectValue release];
		[super setObjectValue:[NSValue valueWithNonretainedObject:object]];
	}
}

- (id)objectValue {
	id value = [super objectValue];
	if([value respondsToSelector:@selector(nonretainedObjectValue)]){
		value = [value nonretainedObjectValue];
	}
	return value;
}

@end
