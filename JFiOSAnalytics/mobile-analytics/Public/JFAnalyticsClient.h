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

/**
 * @return JFAnalyticsClient handles all analytics events. It will handle queueing and caching tag requests.
 */
@interface JFAnalyticsClient : NSObject

/**
 * @return Your keen.io project ID.
 */
@property (nonatomic, strong, readonly) NSString *projectID;

/**
 * @return Your keen.io write key.
 */
@property (nonatomic, strong, readonly) NSString *writeKey;

/**
 * @return Your keen.io read key.
 */
@property (nonatomic, strong, readonly) NSString *readKey;

/**
 * @return Use this to differentiate your development and production builds.
 */
@property (nonatomic, strong, readonly) NSString *environemnt;

/**
 * @return The tag queue limit. Use setTagQueueLimit: to set a custom queue limit. Default is 20.
 */
@property (nonatomic, assign, readonly) NSInteger tagQueueLimit;

/**
 * @return All current global tags. Use addGlobalTag: and removeGlobalTag: to add/remove global tags.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary* globalTags;

/**
 * @return Use to initialize JFAnalyticsClient with your keen.io project ID, write key, and read key. This method must be called before trying to access sharedClient.
 * @param projectID Your keen.io project ID
 * @param writeKey Your keen.io write key
 * @param readKey Your keen.io read key
 */
+ (instancetype)clientWithProjectID:(NSString*)projectID writeKey:(NSString*)writeKey readKey:(NSString*)readKey;

/**
 * @return The single instance of JFAnalyticsClient. This should be used whenever needing an instance of JFAnalyticsClient instead of allocating a new instance. You must call initializeClientWithProjectID:writeKey:readKey: before trying to access the sharedClient.
 */
+ (instancetype)sharedClient;

/**
 * @return Used to set the site property to a custom site value. If used to set the site property, you must call this method before calling processSession.
 *
 * For Example:
 *
 * - (void)applicationDidBecomeActive:(UIApplication *)application {
 * #ifdef DEBUG
 *     [[JFAnalyticsClient sharedInstance] setSite:@"YOUR-DEV-SITE-VALUE"];
 * #else
 *     [[JFAnalyticsClient sharedInstance] setSite:@"YOUR-PROD-SITE-VALUE"];
 * #endif
 * }
 */
- (void)setEnvironment:(NSString*)environemnt;

/**
 * @return Use this method to set the tagQueueLimit property which is used to determine if the queue should be flushed.
 * @param limit The max number of tagging events to queue before sending them all to the tagging warehouse.
 */
- (void)setTagQueueLimit:(NSInteger)limit;

/**
 * @return Use this method to start or stop tracking UIViewController viewDidAppear events.
 * @param trackEvents The BOOL representing whether to turn on (YES) or turn off (NO) view controller viewDidAppear event track.
 */
- (void)setTrackingViewControllerViewDidAppearEvents:(BOOL)trackEvents;

/**
 * @return Use this method to check the state of UIViewController viewDidAppear event tracking. If this returns YES, tracking is enabled. If this returns NO, tracking is disabled.
 */
- (BOOL)isTrackingViewControllerViewDidAppearEvents;

/**
 * @return Use this method to queue a tagging event. All queued tagging events will be sent to keen.io after the queueLimit has been reached or when the applicaiton is backgrounded.
 * @param tags An NSDictionary of all custom tagging event KVP's to track.
 */
- (void)trackEventWithName:(NSString*)name tags:(NSDictionary *)tags;
- (void)trackContentViewWithName:(NSString*)name tags:(NSDictionary *)tags;

/**
 * @return Use to send all currently queued tags immediately. Recommended usage would be to utilize this inside applicationDidEnterBackground: and begin a background task to upload all queud tags. This will help ensure queued tags are sent when the app enters the background, even if the tag queue limit hasn't been reached.
 */
- (void)sendQueuedTagsWithCompletionHandler:(void(^)())completionHandler;

/**
 * @return Use this method to add global tags that should be appended to all tags that are sent using fire:.
 * @param globalTag The NSDictionary containing the global tag to append to all tags
 */
- (void)addGlobalTag:(NSDictionary *)globalTag;

/**
 * @return Use this method to remove global tags from tags that are sent using fire:.
 * @param globalTag The NSDictionary containing the global tag to remove
 */
- (void)removeGlobalTag:(NSDictionary *)globalTag;

/**
 * @return A helper method to determine if the application is being launched for the first time of a specific version.
 */
- (BOOL)isFirstLaunchOfThisVersion;

@end
