//
//  NSData+SSL.h
//  Lockbox
//
//  Created by Steve Streza on 5/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#ifdef UsingOpenSSL
	#import <openssl/sha.h>
#else
	#import <CommonCrypto/CommonDigest.h>
#endif

#ifdef UsingOpenSSL
	#define LBSHADigestLength SHA_DIGEST_LENGTH
#else
	#define LBSHADigestLength CC_SHA1_DIGEST_LENGTH
#endif

//const void* LBSHA1ForBytes(const char *bytes, unsigned long long len);

@interface NSData (SSLCategory)

-(NSData *)SHA1;
-(NSString *)hexval;

@end

@interface NSString (SSLCategory)

-(NSString *)SHA1;

@end
