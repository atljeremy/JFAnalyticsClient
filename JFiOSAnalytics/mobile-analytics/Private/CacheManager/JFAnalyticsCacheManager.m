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

#import "JFAnalyticsCacheManager.h"

NSString* const kJFAnalyticsCachePurgeCompleteNotification = @"JFAnalyticsCachePurgeCompleteNotification";
NSString* const kJFAnalyticsCacheRequestSuccessfulNotification = @"JFAnalyticsCacheRequestSuccessfulNotification";
NSString* const kJFAnalyticsCacheRequestFailedNotification = @"JFAnalyticsCacheRequestFailedNotification";
NSString* const kJFAnalyticsCacheRemoveRequestSuccessfulNotification = @"JFAnalyticsCacheRemoveRequestSuccessfulNotification";
NSString* const kJFAnalyticsCacheRemoveRequestFailedNotification = @"JFAnalyticsCacheRemoveRequestFailedNotification";

static NSString* const kJFAnalyticsClientRequestCachePlist = @"JFAnalyticsClientTagCache.plist";
static NSString* const kJFAnalyticsClientDataKey = @"data";
static NSString* const kJFAnalyticsClientDateKey = @"date";
static NSInteger const kJFAnalyticsClientMaxCacheDays = 6;

@implementation JFAnalyticsCacheManager

#pragma mark ----------------------
#pragma mark Cache Path
#pragma mark ----------------------

+ (NSString*)getCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:kJFAnalyticsClientRequestCachePlist];
    if (path) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSMutableDictionary dictionary] writeToFile:path atomically:YES];
        }
    }
    
    return path;
}

#pragma mark ----------------------
#pragma mark Tag Cache
#pragma mark ----------------------

+ (NSMutableDictionary*)getTagCache
{
    NSString* path = [self getCachePath];
    if (!path) return nil;
    return [NSMutableDictionary dictionaryWithContentsOfFile:path];
}

#pragma mark ----------------------
#pragma mark Retreive all cached tags
#pragma mark ----------------------

+ (NSArray*)getAllCachedAnalyticsTags
{
    NSMutableArray* tagURLs = [@[] mutableCopy];
    NSMutableDictionary* cache = [self getTagCache];
    if (cache) {
        for (NSData* requestDictData in [cache allValues]) {
            NSDictionary* requestDict = [NSKeyedUnarchiver unarchiveObjectWithData:requestDictData];
            if (requestDict) {
                NSDate* cachedDate = [requestDict objectForKey:kJFAnalyticsClientDateKey];
                NSString* tagURL = [NSKeyedUnarchiver unarchiveObjectWithData:[requestDict objectForKey:kJFAnalyticsClientDataKey]];
                
                if ([self daysBetweenDate:cachedDate andDate:[NSDate date]] > kJFAnalyticsClientMaxCacheDays) {
                    [self removeCachedTag:tagURL];
                    continue;
                }
                
                if (tagURL) {
                    [tagURLs addObject:tagURL];
                }
            }
        }
    }
    return tagURLs;
}

#pragma mark ----------------------
#pragma mark Cache Purging
#pragma mark ----------------------

+ (void)purgeAnalyticsCache
{
    dispatch_queue_t queue = dispatch_queue_create("com.jeremyfox.AnalyticsCachePurgeQueue", NULL);
    dispatch_async(queue, ^{
        
        NSString* cachePath;
        NSMutableDictionary* cache;
        
        cachePath = [self getCachePath];
        cache = [self getTagCache];
        if (cache && cache.allValues.count > 0 && cachePath) {
            [cache removeAllObjects];
            [cache writeToFile:cachePath atomically:YES];
        }
               
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJFAnalyticsCachePurgeCompleteNotification object:nil];
            
        });
    });
}

#pragma mark ----------------------
#pragma mark Tag Caching
#pragma mark ----------------------

+ (BOOL)cacheAnalyticsTag:(NSString*)tagURL
{
    __block BOOL writtenSuccessfully = NO;
    dispatch_queue_t queue = dispatch_queue_create("com.jeremyfox.AnalyticsRequestCacheQueue", NULL);
    dispatch_sync(queue, ^{
        NSString* cachePath = [self getCachePath];
        NSMutableDictionary* cache = [self getTagCache];
        if (cache && cachePath) {
            NSData* tagURLData = [NSKeyedArchiver archivedDataWithRootObject:tagURL];
            NSDictionary* cachDict = @{kJFAnalyticsClientDataKey: tagURLData, kJFAnalyticsClientDateKey: [NSDate date]};
            NSData* cachData = [NSKeyedArchiver archivedDataWithRootObject:cachDict];
            [cache setObject:cachData forKey:tagURL];
            writtenSuccessfully = [cache writeToFile:cachePath atomically:YES];
        }
    });
    
    return writtenSuccessfully;
}

#pragma mark ----------------------
#pragma mark Cached Tag Removal
#pragma mark ----------------------

+ (BOOL)removeCachedTags:(NSArray*)tagURLs
{
    BOOL retVal = NO;
    if (tagURLs) {
        NSString* cachePath = [self getCachePath];
        NSMutableDictionary* cache = [self getTagCache];
        
        for (NSString* tagURL in tagURLs) {
            if (cache && tagURL) {
                [cache removeObjectForKey:tagURL];
            }
        }
        
        if (cachePath && [cache writeToFile:cachePath atomically:YES]) {
            retVal = YES;
        }
    }
    
    return retVal;
}

+ (void)removeCachedTag:(NSString*)url
{
    dispatch_queue_t queue = dispatch_queue_create("com.jeremyfox.AnalyticsRequestCacheRemovalQueue", NULL);
    dispatch_async(queue, ^{
        __block BOOL removedSuccessfully = NO;
        if (url) {
            NSString* cachePath = [self getCachePath];
            NSMutableDictionary* cache = [self getTagCache];
            if (cache && cachePath) {
                [cache removeObjectForKey:url];
                removedSuccessfully = [cache writeToFile:cachePath atomically:YES];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (removedSuccessfully) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kJFAnalyticsCacheRemoveRequestSuccessfulNotification object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kJFAnalyticsCacheRemoveRequestFailedNotification object:nil];
            }
        });
    });
}

#pragma mark ----------------------
#pragma mark Helper Methods
#pragma mark ----------------------

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

@end
