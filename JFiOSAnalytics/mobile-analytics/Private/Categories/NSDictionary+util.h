//
//  NSDictionary+util.h
//  base-extensions
//
//  Created by Primedia Inc on 5/30/12.
//  Copyright (c) 2012 Primedia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (util)

- (NSString*)stringForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key;
- (NSInteger)integerForKey:(NSString*)key;
- (NSString *)stringWithURLEncodedEntries;
- (void)URLEncodeParts:(NSMutableArray *)parts path:(NSString *)inPath;
- (void)URLEncodePart:(NSMutableArray *)parts path:(NSString *)path value:(id)value;

@end