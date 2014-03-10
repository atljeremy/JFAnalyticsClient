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

#import <Foundation/Foundation.h>

extern NSString* const kJFAnalyticsCachePurgeCompleteNotification;
extern NSString* const kJFAnalyticsCacheRequestSuccessfulNotification;
extern NSString* const kJFAnalyticsCacheRequestFailedNotification;
extern NSString* const kJFAnalyticsCacheRemoveRequestSuccessfulNotification;
extern NSString* const kJFAnalyticsCacheRemoveRequestFailedNotification;

/**
 * @return The JFAnalyticsCacheManager is a private class in which handles all tag caching. Tags are written to a plist within the documents directory. Tags will be cached for up to 12 days. If an object that exists in cache is requested after 12 days, it will not be returned and will be immediately deleted from the cache.
 */
@interface JFAnalyticsCacheManager : NSObject

/**
 * @return An array of all tags that have been cached and not executed.
 */
+ (NSArray*)getAllCachedAnalyticsTags;

/**
 * @return This will asynchornously empty the entire cache.
 */
+ (void)purgeAnalyticsCache;

/**
 * @return Use to cache a new tag
 * @param tagURL the string tag url to be cached
 */
+ (BOOL)cacheAnalyticsTag:(NSString*)tagURL;

/**
 * @return Use to from cahced tags
 * @param tagURLs the array of string tag url's to be removed from cache
 */
+ (BOOL)removeCachedTags:(NSArray*)tagURLs;

/**
 * @return Use to remove a cached tag
 * @param tagURL the string tag url to be removed from cache
 */
+ (void)removeCachedTag:(NSString*)tagURL;

@end
