/*
 * JFiOSMobileAnalytics
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

#import "JFAnalyticsClient.h"
#import <sys/utsname.h>
#import "JFTagOperation.h"

#pragma mark ----------------------
#pragma mark JFAnalyticsClient_Extension
#pragma mark ----------------------
#import "JFAnalyticsClient_Extension.h"

static NSString* const kJFAnalyticsClientTagQueueName = @"JFAnalyticsClientTagQueue";

@implementation JFAnalyticsClient

static JFAnalyticsClient* _sharedClient = nil;

- (id)init
{
    if(self = [super init]) {
        _sessStartTime = 0;
        _userID = 0;
        _timeWhenPaused = 0;
        _tagQueue = [[NSOperationQueue alloc] init];
        _tagQueue.name = kJFAnalyticsClientTagQueueName;
        _tagQueue.maxConcurrentOperationCount = 4;
        _site = @"no site";
        _lastUsedVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kJFAnalyticsClientLastUsedVersion];
        _includeFirstVisit = NO;
        _sendingTags = NO;
        _tagQueueLimit = kJFAnalyticsClientDefaultTagQueueLimit;
        _globalTags = [@{} mutableCopy];
    }
    return self;
}

+ (instancetype)clientWithProjectID:(NSString*)projectID writeKey:(NSString*)writeKey readKey:(NSString*)readKey
{
    if (_sharedClient) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"JFAnalyticsClient already initialized. Pelase access JFAnalyticsClient through sharedClient after calling clientWithProjectID:writeKey:readKey:." userInfo:nil];
    }
    
    NSParameterAssert(projectID);
    NSParameterAssert(writeKey);
    NSParameterAssert(readKey);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void) {
        _sharedClient = [[self alloc] init];
        _sharedClient.projectID = projectID;
        _sharedClient.writeKey = writeKey;
        _sharedClient.readKey = readKey;
    });
    
    return _sharedClient;
}

+ (instancetype)sharedClient
{
    if (!_sharedClient) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"JFAnalyticsClient must first be initialized using clientWithProjectID:writeKey:readKey: before trying to access sharedClient." userInfo:nil];
    }
    
    return _sharedClient;
}

#pragma mark ----------------------
#pragma mark Convenience Methods
#pragma mark ----------------------

- (void)setSite:(NSString *)site
{
    _site = site;
}

- (void)setTagQueueLimit:(NSInteger)limit
{
    _tagQueueLimit = limit;
}

#pragma mark ----------------------
#pragma mark Global Tag Hanlding
#pragma mark ----------------------

- (void)addGlobalTag:(NSDictionary *)globalTag
{
    [globalTag enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.globalTags setValue:obj forKey:key];
    }];
}

- (void)removeGlobalTag:(NSDictionary *)globalTag
{
    [self.globalTags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [globalTag enumerateKeysAndObjectsUsingBlock:^(id tagKey, id tagObj, BOOL *stopTagEnum) {
            if ([tagKey isEqualToString:key]) {
                [self.globalTags removeObjectForKey:tagKey];
                *stopTagEnum = YES;
            }
        }];
    }];
}

#pragma mark ----------------------
#pragma mark Tag Creation and Caching
#pragma mark ----------------------

- (void)fire:(NSDictionary *)tags
{
    if (!self.userID || self.userID == 0) {
        [self processSession];
    }
    if (tags && tags.allValues.count > 0) {
        NSString *trackingUrl = nil;
        trackingUrl = [self build:tags];
        NSLog(@"JFAnalyticsClient: queued this tag: @@@@@%@", trackingUrl);
        
        [JFAnalyticsCacheManager cacheAnalyticsTag:trackingUrl];
        
        NSArray* queuedTags = [JFAnalyticsCacheManager getAllCachedAnalyticsTags];
        NSLog(@"Queued Tags: %d", queuedTags.count);
        if (queuedTags.count >= self.tagQueueLimit && !self.isSendingTags) {
            [self sendQueuedTags:queuedTags withCompletionHandler:nil];
        }
    }
}

- (NSString*)build:(NSDictionary *)eventTags
{
    NSMutableDictionary *myMap = [[self tagMapTemplate] mutableCopy];
    [myMap addEntriesFromDictionary:eventTags];
    [myMap setValue:[NSString stringWithFormat:@"%@.%@", [self timeToString:self.userID], [self timeToString:self.sessStartTime]] forKey:@"session"];
    [myMap setValue:[self timeToString:self.userID] forKey:@"fpc"];
    
    if (self.includeFirstVisit) {
        [myMap setValue:[self timeToString:self.sessStartTime] forKey:@"first_visit"];
        self.includeFirstVisit = NO;
    }
    
    [myMap setValue:self.site forKey:@"site"];
    [myMap addEntriesFromDictionary:self.globalTags];
    
    return [myMap stringWithURLEncodedEntries];
}

- (NSMutableDictionary*)tagMapTemplate
{
    NSMutableDictionary* template = [NSMutableDictionary dictionary];
    [template setValue:[NSDate date] forKey:@"event_time"];
    [template setValue:self.randomNumberString forKey:@"cache_buster"];
    [template setValue:self.isRetinaDeviceString forKey:@"retina"];
    [template setValue:[UIDevice platformString] forKey:@"platform"];
    [template setValue:[[UIDevice currentDevice] systemVersion] forKey:@"os"];
    [template setValue:APP_VERSION forKey:@"app_version"];
    
    return template;
}

#pragma mark ----------------------
#pragma mark Tag Operations
#pragma mark ----------------------

- (void)sendQueuedTags:(NSArray*)tags withCompletionHandler:(void(^)())completionHandler
{
    @synchronized (self) {
        self.sendingTags = YES;
        __block NSMutableArray* completeTagURLs = [@[] mutableCopy];
        NSMutableArray* operations = [@[] mutableCopy];
        
        __block dispatch_group_t dispatchGroup = dispatch_group_create();
        NSBlockOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
                [JFAnalyticsCacheManager removeCachedTags:[completeTagURLs copy]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) completionHandler();
                    self.sendingTags = NO;
                });
            });
        }];
        
        for (NSString* tagString in tags) {
            NSDictionary* tag = [tagString parseKeyValueFromQueryString];
            JFTagOperation* tagOperation = [JFTagOperation operationWithTag:tag completionBlock:^(JFTagOperation *operation, JFTagOperationStatus status) {
                if (status == JFTagOperationStatusFAILED) {
                    NSLog(@"Failed to send a tagging event: %@", operation.tag);
                } else {
                    [completeTagURLs addObject:[operation.tag stringWithURLEncodedEntries]];
                    NSLog(@"Successfully sent a tagging event: %@", operation.tag);
                }
            }];
            [completionOperation addDependency:tagOperation];
            [operations addObject:tagOperation];
        }
        
        [operations addObject:completionOperation];
        
        [self.tagQueue addOperations:operations waitUntilFinished:NO];
    }
}

- (void)sendQueuedTagsWithCompletionHandler:(void(^)())completionHandler
{
    NSArray* queuedRequests = [JFAnalyticsCacheManager getAllCachedAnalyticsTags];
    [self sendQueuedTags:queuedRequests withCompletionHandler:completionHandler];
}

#pragma mark ----------------------
#pragma mark Sessions Handling
#pragma mark ----------------------

- (void)createUserIDIfNeeded
{
    self.includeFirstVisit = YES;
    self.userID = [[NSUserDefaults standardUserDefaults] doubleForKey:kJFAnalyticsClientUserID];
    
    if (self.userID == 0) {
        self.userID = [[NSDate date] timeIntervalSince1970] * 1000;
        self.sessStartTime = self.userID;
        NSLog(@"JFAnalyticsClient: Generated a new userID of: %@", [self timeToString:self.userID]);
        [[NSUserDefaults standardUserDefaults] setDouble:self.userID forKey:kJFAnalyticsClientUserID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSLog(@"JFAnalyticsClient: Reusing a userID of: %@", [self timeToString:self.userID]);
    }
}

- (void)processSession
{
    [self createUserIDIfNeeded];
    [self refreshSessStartTimeIfNeeded];
}

- (void)refreshSessStartTimeIfNeeded
{
    if(self.sessStartTime == 0) {
        [self generateNewSession];
    }
    
    if(self.timeWhenPaused > 0) {
        NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
        if(timeNow >= (self.timeWhenPaused + kJFAnalyticsClientThirtyMinutes)) {
            [self generateNewSession];
            self.timeWhenPaused = 0;
        }
    }
}

- (void)generateNewSession
{
    self.sessStartTime = [[NSDate date] timeIntervalSince1970] * 1000;
    self.includeFirstVisit = YES;
}

- (void)markTimePaused
{
    self.timeWhenPaused = [[NSDate date] timeIntervalSince1970];
}

#pragma mark ----------------------
#pragma mark Helper Methods
#pragma mark ----------------------

- (BOOL)isFirstLaunchOfThisVersion
{
    [self setLastUsedVersion];
    if(nil == self.lastUsedVersion || ![self.lastUsedVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]]) {
        self.lastUsedVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        return YES;
    }
    return NO;
}

- (void)setLastUsedVersion
{
    [[NSUserDefaults standardUserDefaults] setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:kJFAnalyticsClientLastUsedVersion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)timeToString:(NSTimeInterval)time
{
    return [@(floor(time)) stringValue];
}

- (NSString*)randomNumberString
{
    return [@(arc4random() % 9999999999) stringValue];
}

- (NSString*)isRetinaDeviceString
{
    return ([UIDevice isRetinaDisplay]) ? @"Yes" : @"No";
}

@end
