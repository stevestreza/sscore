//
//  NSData+SSL.m
//  Lockbox
//
//  Created by Steve Streza on 5/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSData+SSL.h"
#import <CommonCrypto/CommonCryptor.h>

const void* LBSHA1ForBytes(const char *bytes, unsigned long long len){
#ifdef UsingOpenSSL
	void *shaBytes = SHA1(bytes, len, NULL);
	return shaBytes;
#else
	/* Do the work */
//	shaInit   (NULL, 1);
//	shaUpdate (NULL, (BITS8 *) bytes, len);
//	shaFinal  (NULL, mydigest);

	void *mydigest = malloc(LBSHADigestLength);
	CC_SHA1(bytes, len, mydigest);
	
	/* print it out. */
	//	for (loop=0; loop<SHF_DIGESTSIZE; loop++) printf ("%02lX", mydigest[loop]);
	return mydigest;
#endif
}

@implementation NSData (SSLCategory)

-(NSData *)SHA1{
	unsigned long long len = [self length];
	const void *bytes = [self bytes];
	
	return [NSData dataWithBytes:LBSHA1ForBytes(bytes,len) 
						  length:LBSHADigestLength];	
}

- (NSString *)hexval
{
    NSMutableString *hex = [NSMutableString string];
    unsigned char *bytes = (unsigned char *)[self bytes];
    char temp[3];
    int i = 0;
	
    for (i = 0; i < [self length]; i++) {
        temp[0] = temp[1] = temp[2] = 0;
        (void)sprintf(temp, "%02x", bytes[i]);
        [hex appendString:[NSString stringWithUTF8String:temp]];
    }
	
    return hex;
}

@end

@implementation NSString (SSLCategory)

-(NSString *)SHA1{
	unsigned long long len = [self length];
	const void *bytes = [self bytes];
	
	return [NSData dataWithBytes:LBSHA1ForBytes(bytes,len) 
						  length:LBSHADigestLength];	
}

@end
