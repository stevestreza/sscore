//
//  TCOAuthDownload.h
//  Bird
//
//  Created by Steve Streza on 6/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCDownload.h"
#import "OAConsumer.h"
#import "OAToken.h"

@interface TCOAuthDownload : TCDownload {
	OAConsumer *_consumer;
	OAToken *_accessToken;
	OAToken *_requestToken;
}

@property (retain) OAConsumer *consumer;
@property (retain) OAToken *accessToken;
@property (retain) OAToken *requestToken;

@end
