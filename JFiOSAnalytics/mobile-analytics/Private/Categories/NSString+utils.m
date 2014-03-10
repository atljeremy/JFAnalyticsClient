/*
 * JFiOSAnalytics
 *
 * Created by Jeremy Fox on 10/19/12.
 * Copyright (c) 2012 Jeremy Fox. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "NSString+utils.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (utils)

- (NSString *)stringFromMD5 {
    
    if(self == nil || [self length] == 0)
        return nil;
    
    const char *value = [self UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}

- (NSString*)urlEncodedString {
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                     (CFStringRef)self,
                                                                     NULL,
                                                                     (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

- (NSString*)urlDecodedString {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)stringByAppendingQueryParameters:(NSDictionary *)queryParameters
{
    if ([queryParameters count] > 0) {
        return [NSString stringWithFormat:@"%@?%@", self, [queryParameters stringWithURLEncodedEntries]];
    }
    return [NSString stringWithString:self];
}

- (NSArray *)keyValueArrayFromQuery
{
    NSString* decodedQuery = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSRange range = [decodedQuery rangeOfString:@"?"];
    
    NSString *trimmedQuery = decodedQuery;
    if (range.location == NSNotFound) {
        range = [decodedQuery rangeOfString:@".com"];
        if (range.location != NSNotFound) {
            trimmedQuery = [decodedQuery substringFromIndex:range.location + range.length + 1];
        }
    } else {
        trimmedQuery = [decodedQuery substringFromIndex:range.location + range.length];
    }
    
    trimmedQuery = [trimmedQuery stringByReplacingOccurrencesOfString:@" & " withString:@" and "];
    NSArray *keyValues = [trimmedQuery componentsSeparatedByString:@"&"];
    return keyValues;
}

- (NSDictionary*)parseKeyValueFromQueryString
{
    NSMutableDictionary* keyValueDictionary = [@{} mutableCopy];
    if (self && ![self isKindOfClass:[NSNull class]]) {
        NSArray *keyValues = [self keyValueArrayFromQuery];
        for (NSString *keyValuePair in keyValues) {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = pairComponents[0];
            NSString *value = pairComponents[1];
            
            if (key && value) {
                [keyValueDictionary setValue:value forKey:key];
            }
        }
    }
    
    return keyValueDictionary;
}

@end
