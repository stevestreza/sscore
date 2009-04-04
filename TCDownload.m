/*
 
 Copyright (c) 2008 Technicolor Project
 Licensed under the MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "TCDownload.h"


@implementation TCDownload

@synthesize 
delegate=mDelegate, 
url=mURL, 
request=mRequest, 
response=mResponse,  
data=mData,  
requestType=mRequestType,  
requestData=mRequestData,  
finished=mFinished,
expectedSize=mExpectedSize;

+(NSString *)loadResourceStringForURL:(NSURL *)url encoding:(NSStringEncoding)encoding{
	return [[[NSString alloc] initWithData:[TCDownload loadResourceDataForURL:url] encoding:encoding] autorelease];
}

+(NSData *)loadResourceDataForURL:(NSURL *)url{
	TCDownload *download = [[TCDownload alloc] initWithURL:url];
	[download send:NO];
	while(!download.finished){
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	NSData *data = [download.data retain];
	[download release];
	return data;
}

-(id)initWithURL:(NSURL *)url{
	if(self = [super init]){
		mURL = [url copy];
		mFinished = NO;
	}
	return self;
}

-(void)setValue:(id)value forHeader:(NSString *)headerKey{
	if(mHeaders){
		mHeaders = [[NSMutableDictionary alloc] init];
	}
	[mHeaders setValue:value forKey:headerKey];
}

-(NSString *)_HTTPMethodName{
	switch (mRequestType) {
		case TCDownloadRequestTypeGET:
			return @"GET";
			break;
		case TCDownloadRequestTypePOST:
			return @"POST";
			break;
		case TCDownloadRequestTypeHEAD:
			return @"HEAD";
			break;
		default:
			break;
	}
	return @"GET";
}

-(NSURLRequest *)_buildRequest{
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:mURL];
	[request setHTTPMethod:[self _HTTPMethodName]];

	if(mHeaders){
		NSArray *keys = [mHeaders allKeys];
		for(NSString *key in keys){
			id value = [mHeaders valueForKey:key];
			[request addValue:value forHTTPHeaderField:key];
		}
	}
	
	if(mRequestData){
		[request setHTTPBody:mRequestData];
	}
	
	return [request autorelease];
}

-(void)send{
	if(![NSThread isMainThread]){
		[self performSelectorOnMainThread:@selector(send) withObject:nil waitUntilDone:NO];
		return;
	}
	
	[self send:YES];
}

-(void)send:(BOOL)async{
	mRequest = [[self _buildRequest] retain];
	if(async){
		mConnection = [[NSURLConnection connectionWithRequest:mRequest delegate:self] retain];
		[mConnection performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];	
	}else{
		NSURLResponse *response = nil;
		NSError *error = nil;
		
		NSData *data = [NSURLConnection sendSynchronousRequest:mRequest returningResponse:&response error:&error];
		
		if(response && !error){
			[self connection:nil didReceiveResponse:response];
			[self connection:nil didReceiveData:data];
			[self connectionDidFinishLoading:nil];
		}else if(error){
			[self connection:nil didFailWithError:error];
		}
	}
}

-(void)cancel{
	[mConnection cancel];
}

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)deadError{
	mError = [deadError copy];
	if(mDelegate && [mDelegate respondsToSelector:@selector(download:hadError:)]){
		[mDelegate download:self hadError:deadError];
	}	
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData{
	NSMutableData *objectData = (NSMutableData *)mData;
	
	[self willChangeValueForKey:@"data"];
	[objectData appendData:theData];
	[self didChangeValueForKey:@"data"];

	if(mDelegate && [mDelegate respondsToSelector:@selector(downloadReceivedData:)]){
		[mDelegate downloadReceivedData:self];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	mFinished = YES;
	
	if(mDelegate && [mDelegate respondsToSelector:@selector(downloadFinished:)]){
		[mDelegate downloadFinished:self];
	}
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse{
	BOOL shouldReturn = YES;
	
	if(mDelegate && [mDelegate respondsToSelector:@selector(download:shouldRedirectToURL:)]){
		shouldReturn = [mDelegate download:self shouldRedirectToURL:[request URL]];
	}
	//	TNSWLog(@"sending request %@",request);
	return (shouldReturn ? request : nil);
}


-(void)connection:(NSURLConnection *)conn didReceiveResponse:(NSHTTPURLResponse *)response{
	if([response statusCode] == 303 && [[response allHeaderFields] valueForKey:@"Location"]){
		NSLog(@"need a redirect!");
		return;
	}
	mExpectedSize = [response expectedContentLength];
	if(!mData){
		if(mExpectedSize == -1){
			mData = [[NSMutableData alloc] init];
		}else{
			mData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)mExpectedSize];	
		}
	}
}

-(BOOL)cacheToPath:(NSString *)path{
	return [[NSFileManager defaultManager] createFileAtPath:path contents:mData attributes:nil];
}

-(void)dealloc{
	mDelegate = nil;
	
	[mURL release];
	mURL = nil;
	
	[mRequest release];
	mRequest = nil;
	
	[mResponse release];
	mResponse = nil;
	
	[mConnection release];
	mConnection = nil;
	
	[mHeaders release];
	mHeaders = nil;
	
	[mError release];
	mError = nil;

	[mRequestData release];
	mRequestData = nil;
	
	[mData release];
	mData = nil;
	
	[super dealloc];
}

@end
