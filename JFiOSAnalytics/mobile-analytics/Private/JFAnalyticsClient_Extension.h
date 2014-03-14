//
//  JFAnalyticsClient_Test.h
//  ios_primedia
//
//  Created by Jeremy Fox on 4/22/13.
//
//

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
