//
//  NSDictionary+util.m
//  base-extensions
//
//  Created by Primedia Inc on 5/30/12.
//  Copyright (c) 2012 Primedia Inc. All rights reserved.
//

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
        NSString *encodedKey = [[key description] urlEncodedString];
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
    NSString *encodedPart = [[value description] urlEncodedString];
    [parts addObject:[NSString stringWithFormat:@"%@=%@", path, encodedPart]];
}

@end
