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
#import "NSDictionary+util.h"

@implementation NSDictionary (util)

- (NSString*)stringForKey:(NSString*)key {
    NSString* keyValue = nil;
    NSObject* keyObject = [self objectForKey:key];
    
    if (keyObject && [keyObject isKindOfClass:[NSString class]]) {
        keyValue = (NSString*)keyObject;
    }
    
    return keyValue;
}

- (BOOL)boolForKey:(NSString*)key {
    NSNumber* keyValue = nil;
    NSObject* keyObject = [self objectForKey:key];
    
    if (keyObject && [keyObject isKindOfClass:[NSNumber class]]) {
        keyValue = (NSNumber*)keyObject;
    }
    
    return [keyValue boolValue] != NO;
}

- (NSInteger)integerForKey:(NSString*)key {
    NSNumber* keyValue = nil;
    NSObject* keyObject = [self objectForKey:key];
    
    if (keyObject && [keyObject isKindOfClass:[NSNumber class]]) {
        keyValue = (NSNumber*)keyObject;
    }
    
    return [keyValue integerValue];
}

- (NSString *)stringWithURLEncodedEntries
{
    NSMutableArray *parts = [NSMutableArray array];
    [self URLEncodeParts:parts path:nil];
    return [parts componentsJoinedByString:@"&"];
}

- (void)URLEncodeParts:(NSMutableArray *)parts path:(NSString *)inPath
{
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *encodedKey = [[key description] JF_urlEncodedString];
        NSString *path = inPath ? [inPath stringByAppendingFormat:@"[%@]", encodedKey] : encodedKey;
        
        if ([value isKindOfClass:[NSArray class]]) {
            for (id item in value) {
                if ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSMutableDictionary class]]) {
                    [item URLEncodeParts:parts path:[path stringByAppendingString:@"[]"]];
                } else {
                    [self URLEncodePart:parts path:[path stringByAppendingString:@"[]"] value:item];
                }
                
            }
        } else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
            [value URLEncodeParts:parts path:path];
        }
        else {
            [self URLEncodePart:parts path:path value:value];
        }
    }];
}

- (void)URLEncodePart:(NSMutableArray *)parts path:(NSString *)path value:(id)value
{
    NSString *encodedPart = [[value description] JF_urlEncodedString];
    [parts addObject:[NSString stringWithFormat:@"%@=%@", path, encodedPart]];
}

@end
