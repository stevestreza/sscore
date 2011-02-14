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

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#define kTCDownloadRunLoopMode NSDefaultRunLoopMode
#else
#define kTCDownloadRunLoopMode NSConnectionReplyMode
#endif

@class TCDownload;

#define kTCDownloadDidBeginDownloadNotification  @"kTCDownloadDidBeginDownloadNotification"
#define kTCDownloadDidFinishDownloadNotification @"kTCDownloadDidFinishDownloadNotification"

@protocol TCDownloadDelegate

-(void)downloadDidBegin:(TCDownload *)download;
-(void)downloadReceivedData:(TCDownload *)download;
-(void)downloadFinished:(TCDownload *)download;
-(BOOL)download:(TCDownload *)download shouldRedirectToURL:(NSURL *)url;
-(void)download:(TCDownload *)download hadError:(NSError *)error;

@end

typedef long long TCDownloadSize;

typedef enum {
	TCDownloadRequestTypeGET,
	TCDownloadRequestTypePOST,
	TCDownloadRequestTypePUT,
	TCDownloadRequestTypeDELETE,
	TCDownloadRequestTypeHEAD,
} TCDownloadRequestType;

@interface TCDownload : NSObject {
	id<TCDownloadDelegate> mDelegate;
	
	NSURL *mURL;
	NSURLRequest *mRequest;
	NSHTTPURLResponse *mResponse;
	NSURLConnection *mConnection;
	NSDictionary *mHeaders;
	NSError *mError;
	
	NSTimeInterval mTimeoutInterval;
	
	TCDownloadRequestType mRequestType;
	TCDownloadSize mExpectedSize;
	
	NSData *mRequestData;
	NSData *mData;
	
	//the run loop of the calling thread
	NSRunLoop *mRunLoop;
	
	BOOL mStarted;
	BOOL mActive;
	BOOL mFinished;
	BOOL mSynchronous;
	
	id mUserInfo;
}

@property (retain) id userInfo;
@property (retain) id<TCDownloadDelegate> delegate;
@property (readonly) NSURL *url;
@property (assign) NSTimeInterval timeoutInterval;
@property (readonly) NSURLRequest  *request;
@property (readonly) NSHTTPURLResponse *response;
@property (readonly) NSData *data;
@property (readonly) NSError *error;
@property (retain) NSData *requestData;
@property TCDownloadRequestType requestType;
@property (readonly) TCDownloadSize expectedSize;
@property (readonly) double percentComplete;
@property (readonly, getter=isFinished) BOOL finished;
@property (readonly, getter=isActive) BOOL active;
@property (readonly, getter=hasStarted) BOOL started;
@property (retain) NSRunLoop *runLoop;

-(id)initWithURL:(NSURL *)url;
-(BOOL)cacheToPath:(NSString *)path;
-(void)send;
-(void)send:(BOOL)async;
-(void)cancel;

-(double)percentComplete;

+(NSData *)loadResourceDataForURL:(NSURL *)url;
+(NSString *)loadResourceStringForURL:(NSURL *)url encoding:(NSStringEncoding)encoding;
+(void)setScheduleAtHead:(BOOL)head;

-(void)setValue:(id)value forHeader:(NSString *)headerKey;

-(NSOperation *)downloadOperation;

//delegate methods
-(void)downloadDidBegin;
-(void)downloadHadError:(NSError *)error;
-(void)downloadReceivedData;
-(void)downloadFinished;
-(BOOL)downloadShouldRedirectToURL:(NSURL *)aURL;
@end
