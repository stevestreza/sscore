//
//  TCOAuthDownload.m
//  Bird
//
//  Created by Steve Streza on 6/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TCOAuthDownload.h"
#import "OAMutableURLRequest.h"

@implementation TCOAuthDownload

@synthesize consumer=_consumer, accessToken=_accessToken, requestToken=_requestToken;

-(NSURLRequest *)_buildRequest{
	NSURLRequest *oldRequest = [super _buildRequest];
	
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:mURL 
																   consumer:self.consumer 
																	  token:self.accessToken
																	  realm:nil 
														  signatureProvider:nil];
	
	[request setHTTPMethod:[oldRequest HTTPMethod]];
	
	NSDictionary *headerFields = [oldRequest allHTTPHeaderFields];
	NSMutableArray *headerKeys = [[[headerFields allKeys] mutableCopy] autorelease];
	[headerKeys removeObject:@"Authorization"];
	headerFields = [headerFields dictionaryWithValuesForKeys:headerKeys];

	[request setAllHTTPHeaderFields:headerFields];
	[request setHTTPShouldHandleCookies:[oldRequest HTTPShouldHandleCookies]];
	
	if([oldRequest HTTPBodyStream]){
		[request setHTTPBodyStream:[oldRequest HTTPBodyStream]];
	}else{
		[request setHTTPBody:[oldRequest HTTPBody]];
	}

	[request prepare];
	
	[mRequest release];
	mRequest = request;
	return mRequest;
}

@end
