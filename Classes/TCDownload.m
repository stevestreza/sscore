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
timeoutInterval=mTimeoutInterval,
request=mRequest, 
response=mResponse,  
data=mData, 
error=mError,
requestType=mRequestType,  
requestData=mRequestData,  
finished=mFinished,
expectedSize=mExpectedSize,
active=mActive, 
started=mStarted, 
userInfo=mUserInfo,
runLoop=mRunLoop;

static NSThread *sSharedClientThread = nil;
static NSRunLoop *sSharedClientRunLoop = nil;
static NSArray *sSharedJobQueue = nil;

static BOOL sScheduleAtHead = NO;

+(void)setupBackgroundThread{
	if(!sSharedClientThread){
		sSharedJobQueue = [[NSMutableArray alloc] init];
		
		sSharedClientThread = [[NSThread alloc] initWithTarget:self selector:@selector(beginRunLoop:) object:sSharedClientRunLoop];
		[sSharedClientThread start];
		
		while(!sSharedClientRunLoop){ usleep(1000); }
	}	
}

+(void)setScheduleAtHead:(BOOL)head{
	sScheduleAtHead = head;
}

+(void)beginDownload:(TCDownload *)download{
	[self beginDownload:download atIndex:(sScheduleAtHead ? 0 : sSharedJobQueue.count)];
}

+(void)beginDownload:(TCDownload *)download atIndex:(NSUInteger)index{
	[self setupBackgroundThread];
	//	[download performSelector:@selector(_reallySend) onThread:sSharedClientThread withObject:nil waitUntilDone:NO];
	@synchronized(sSharedJobQueue){
		if(index > 0 && index >= sSharedJobQueue.count) index = sSharedJobQueue.count - 1;
		[(NSMutableArray *)sSharedJobQueue insertObject:download atIndex:index];
	}
}

+(void)beginRunLoop:(NSRunLoop *)runLoop{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	sSharedClientRunLoop = [[NSRunLoop currentRunLoop] retain];
	if(!runLoop) runLoop = [sSharedClientRunLoop retain];

	NSThread *thread = [NSThread currentThread];
	
	while(![thread isCancelled]){
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
		[runLoop runMode:kTCDownloadRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];		
		
		TCDownload *download = nil;
		@synchronized(sSharedJobQueue){
			if(sSharedJobQueue.count){
				 download = [[sSharedJobQueue objectAtIndex:0] retain];
				[sSharedJobQueue removeObjectAtIndex:0];
			}
		}
		if(download){
			[download _reallySend];
			[download release];
		}
		
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

		 [pool drain];
	}
	
	NSLog(@"Aborting background thread!");
	
	[sSharedClientRunLoop release];
	sSharedClientRunLoop = nil;
	
	[runLoop release];
	
	[pool release];
}

+(NSString *)loadResourceStringForURL:(NSURL *)url encoding:(NSStringEncoding)encoding{
	return [[[NSString alloc] initWithData:[TCDownload loadResourceDataForURL:url] encoding:encoding] autorelease];
}

+(NSData *)loadResourceDataForURL:(NSURL *)url{
	TCDownload *download = [[TCDownload alloc] initWithURL:url];
	[download send:NO];
//	while(!download.finished){
//		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
//	}
	NSData *data = [download.data retain];
	[download release];
	return data;
}

-(id)initWithURL:(NSURL *)url{
	if(self = [super init]){
		mURL = [url copy];
		mRequest = nil;
		mActive = NO;
		mFinished = NO;
		mStarted = NO;
		
		//		mRunLoop = [[NSRunLoop currentRunLoop] retain];
		[TCDownload setupBackgroundThread];
		mRunLoop = [sSharedClientRunLoop retain];
	}
	return self;
}

-(id)initWithRequest:(NSURLRequest *)request{
	if(self = [self initWithURL:[request URL]]){
		mRequest = [request copy];
	}
	return self;
}

-(void)setUsername:(NSString *)username password:(NSString *)password{
	if (username && password) {
		// Set header for HTTP Basic authentication explicitly, to avoid problems with proxies and other intermediaries
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
		NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
		NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodingWithLineLength:80]];
		[self setValue:authValue forHeader:@"Authorization"];
	}	
}

-(void)setValue:(id)value forHeader:(NSString *)headerKey{
	if(!mHeaders){
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
		case TCDownloadRequestTypePUT:
			return @"PUT";
			break;
		case TCDownloadRequestTypeDELETE:
			return @"DELETE";
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
	if(mRequest) return mRequest;
	
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
	
	if(mTimeoutInterval){
		[request setTimeoutInterval:mTimeoutInterval];
	}
	
	mRequest = request;
	return request;
}

-(void)send{
	if(![NSThread isMainThread]){
		[self performSelectorOnMainThread:@selector(send) withObject:nil waitUntilDone:NO];
		return;
	}
	
	[self send:YES];
}

-(void)send:(BOOL)async{
	if(mStarted) return;
	
	mSynchronous = !async;
	[self willChangeValueForKey:@"started"];
	mStarted = YES;
	[self didChangeValueForKey:@"started"];

	if(mSynchronous){
		[self _reallySend];
	}else{
//		[NSThread detachNewThreadSelector:@selector(_reallySend) toTarget:self withObject:nil];
//		[sSharedClientRunLoop performSelector:@selector(_reallySend) target:self argument:nil order:0 modes:[NSArray arrayWithObject:kTCDownloadRunLoopMode]];
		[TCDownload beginDownload:self];
	}
}

-(void)_reallySend{
	NSAutoreleasePool *autoPool = [NSAutoreleasePool new];
	[self _buildRequest];

//	mConnection = [[NSURLConnection connectionWithRequest:mRequest delegate:self] retain];
	mConnection = [[NSURLConnection alloc] initWithRequest:mRequest delegate:self startImmediately:NO];
//	[mConnection unscheduleFromRunLoop:[NSRunLoop mainRunLoop] forMode:kTCDownloadRunLoopMode];
	
//	[mRunLoop release];
	if(!mRunLoop){
		mRunLoop = [[NSRunLoop currentRunLoop] retain];
	}
	
	[mConnection scheduleInRunLoop:mRunLoop forMode:kTCDownloadRunLoopMode];
	
	[mConnection start];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kTCDownloadDidBeginDownloadNotification object:self];
	
	if(mSynchronous){
		[self blockUntilFinished];
	}
//	}else{
//		NSURLResponse *response = nil;
//		NSError *error = nil;
		
//		NSData *data = [NSURLConnection sendSynchronousRequest:mRequest returningResponse:&response error:&error];
		
//		if(response && !error){
//			[self connection:nil didReceiveResponse:response];
//			[self connection:nil didReceiveData:data];
//			[self connectionDidFinishLoading:nil];
//		}else if(error){
//			[self connection:nil didFailWithError:error];
//		}
//	}
	[autoPool release];
}

-(void)blockUntilFinished{
	while(![self isFinished]){
//		NSLog(@"Tick");
		[mRunLoop runMode:kTCDownloadRunLoopMode beforeDate:[NSDate distantFuture]];		
	}
}

-(void)cancel{
	[mConnection cancel];
}

- (void)connection:(NSURLConnection*)connection
  didFailWithError:(NSError*)deadError{
	mError = [deadError copy];
	mFinished = YES;

	[[NSNotificationCenter defaultCenter] postNotificationName:kTCDownloadDidFinishDownloadNotification object:self];

	NSLog(@"TCDownload Error: %@",mError);
	[self downloadHadError:mError];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData{
	NSMutableData *objectData = (NSMutableData *)mData;
	
	[self willChangeValueForKey:@"data"];
	[objectData appendData:theData];
	[self didChangeValueForKey:@"data"];

//	NSLog(@"Received %i/%i bytes: %0.1f%% complete", [theData length], [objectData length],(100 * [objectData length]) / (double)[self expectedSize]);
	[self downloadReceivedData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	mFinished = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kTCDownloadDidFinishDownloadNotification object:self];

//	NSLog(@"Calling delegate that we're done: %@",mDelegate);
	[self downloadFinished];
	
	[self willChangeValueForKey:@"active"];
	mActive = NO;
	[self  didChangeValueForKey:@"active"];
}

-(void)downloadHadError:(NSError *)error{
	if(mDelegate && [mDelegate respondsToSelector:@selector(download:hadError:)]){
		[mDelegate download:self hadError:error];
	}
}

-(void)downloadReceivedData{
	if(mDelegate && [mDelegate respondsToSelector:@selector(downloadReceivedData:)]){
		[mDelegate downloadReceivedData:self];
	}	
}	

-(void)downloadDidBegin{
	if(mDelegate && [mDelegate respondsToSelector:@selector(downloadDidBegin:)]){
		[mDelegate downloadDidBegin:self];
	}	
}

-(void)downloadFinished{
	if(mDelegate && [mDelegate respondsToSelector:@selector(downloadFinished:)]){
		[mDelegate downloadFinished:self];
	}	
}

-(BOOL)downloadShouldRedirectToURL:(NSURL *)aURL{
	BOOL shouldReturn = YES;
	if(mDelegate && [mDelegate respondsToSelector:@selector(download:shouldRedirectToURL:)]){
		shouldReturn = [mDelegate download:self shouldRedirectToURL:aURL];
	}	
	return shouldReturn;
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
	printf("Upload %0.2f%% complete\n",(100.*totalBytesWritten/(double)totalBytesExpectedToWrite));
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse{
	BOOL shouldReturn = [self downloadShouldRedirectToURL:[request URL]];
//	TNSWLog(@"sending request %@",request);
	[self downloadDidBegin];
	return (shouldReturn ? request : nil);
}


-(void)connection:(NSURLConnection *)conn didReceiveResponse:(NSHTTPURLResponse *)response{
	mResponse = [response retain];
	
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
	
	[self willChangeValueForKey:@"active"];
	mActive = YES;
	[self  didChangeValueForKey:@"active"];
}

-(BOOL)cacheToPath:(NSString *)path{
	return [[NSFileManager defaultManager] createFileAtPath:path contents:mData attributes:nil];
}

-(double)percentComplete{
	return self.data.length / (double)self.expectedSize;
}

-(NSOperation *)downloadOperation{
	return [[[NSInvocationOperation alloc] initWithTarget:self
												 selector:@selector(_operationSend)
												   object:nil] autorelease];
}

-(void)_operationSend{
	[self send:NO];
	NSLog(@"Operation finished! Bool? %i", (int)[self isFinished]);
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
	
	[mRunLoop release];
	mRunLoop = nil;
	
	[super dealloc];
}

@end
