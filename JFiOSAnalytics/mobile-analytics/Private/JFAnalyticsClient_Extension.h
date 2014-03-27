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

static NSString* const kJFAnalyticsClientLastUsedVersion = @"lastUsedVersion";
static NSString* const kJFAnalyticsClientUserID = @"userID";
static NSInteger const kJFAnalyticsClientThirtyMinutes = 30*60;
static NSInteger const kJFAnalyticsClientDefaultTagQueueLimit = 20;

@interface JFAnalyticsClient ()

@property (nonatomic, strong) NSOperationQueue* tagQueue;
@property (nonatomic, assign) NSTimeInterval userID;
@property (nonatomic, assign) NSTimeInterval sessStartTime;
@property (nonatomic, assign) NSTimeInterval timeWhenPaused;
@property (nonatomic, assign) BOOL includeFirstVisit;
@property (nonatomic, strong) NSString *lastUsedVersion;
@property (nonatomic, assign, getter = isSendingTags) BOOL sendingTags;
@property (nonatomic, strong, readwrite) NSString *environment;
@property (nonatomic, strong, readwrite) NSMutableDictionary* globalTags;
@property (nonatomic, assign, readwrite) NSInteger tagQueueLimit;
@property (nonatomic, strong, readwrite) NSString *projectID;
@property (nonatomic, strong, readwrite) NSString *writeKey;
@property (nonatomic, strong, readwrite) NSString *readKey;

- (void)setLastUsedVersion;
- (void)createUserIDIfNeeded;
- (void)refreshSessStartTimeIfNeeded;
- (void)generateNewSession;

- (NSString*)timeToString:(NSTimeInterval)time;
- (NSString*)randomNumberString;
- (NSString*)build:(NSDictionary *)tag;

@end
