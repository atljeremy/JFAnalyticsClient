#include "Kiwi.h"
#import "JFAnalyticsClient_Extension.h"

SPEC_BEGIN(JFAnalyticsClientTests)

describe(@"JFAnalyticsClient", ^{
    __block JFAnalyticsClient* aMngr = nil;
    __block NSUserDefaults* userDefaults = nil;
    
    context(@"testing JFAnalyticsClient initialization", ^{
        
        // Only occurs once
        beforeAll(^{
            aMngr = [JFAnalyticsClient clientWithProjectID:@"adc" writeKey:@"asd" readKey:@"dsa"];
            userDefaults = [NSUserDefaults standardUserDefaults];
        });
        
        afterAll(^{
            [userDefaults removeObjectForKey:kJFAnalyticsClientLastUsedVersion];
        });
        
        specify(^{
            [aMngr shouldNotBeNil];
        });
        
        it(@"should instantiate using sharedInstance", ^{
            [[JFAnalyticsClient sharedClient] shouldNotBeNil];
        });
        
        it(@"should return the same instance twice using sharedInstance", ^{
            [[aMngr should] beIdenticalTo:[JFAnalyticsClient sharedClient]];
        });
        
        it(@"should be of class JFAnalyticsClient", ^{
            [[aMngr should] beKindOfClass:[JFAnalyticsClient class]];
        });
        
        it(@"calls required methods when initializing a JFAnalyticsClient object", ^{
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[NSUserDefaults should] receive:@selector(standardUserDefaults)];
            [[userDefaults should] receive:@selector(stringForKey:) withArguments:@"lastUsedVersion"];
            __unused id unused = [manager init];
        });
        
        it(@"setups of proper default values when initializing a JFAnalyticsClient object", ^{
            [userDefaults setObject:@"This is a test!" forKey:kJFAnalyticsClientLastUsedVersion];
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            
            [[theValue(manager.site) should] equal:theValue(@"no site")];
            [[theValue(manager.lastUsedVersion) should] equal:theValue(@"This is a test!")];
            [[theValue(manager.includeFirstVisit) should] beFalse];
            
            __unused id unused = [manager init];
        });
    });
    
    context(@"testing body of JFAnalyticsClient", ^{
        
        afterEach(^{
            [userDefaults removeObjectForKey:kJFAnalyticsClientLastUsedVersion];
        });
        
        it(@"testing isFirstLaunchOfThisVersion returns proper value when true", ^{
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            Boolean isFirstLaunch = [manager isFirstLaunchOfThisVersion];
            [[theValue(isFirstLaunch) should] beTrue];
        });
        
        it(@"testing isFirstLaunchOfThisVersion returns proper value when false", ^{
            NSBundle* mainBundle = [NSBundle mainBundle];
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            
            [[manager should] receive:@selector(lastUsedVersion) andReturn:@"This is the same!" withCount:2];
            [[mainBundle should] receive:@selector(objectForInfoDictionaryKey:) andReturn:@"This is the same!" withCount:2 arguments:@"CFBundleVersion"];
            
            Boolean isFirstLaunch = [manager isFirstLaunchOfThisVersion];
            [[theValue(isFirstLaunch) should] beFalse];
        });
        
        it(@"should call setLastUsedVersion from isFirstLaunchOfThisVersion", ^{
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[manager should] receive:@selector(setLastUsedVersion)];
            [manager isFirstLaunchOfThisVersion];
        });
        
        it(@"testing setLastUsedVersion calls proper NSUSerDefault methods with proper params", ^{
            id object = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[userDefaults should] receive:@selector(setObject:forKey:) withArguments:object, kJFAnalyticsClientLastUsedVersion];
            [[userDefaults should] receive:@selector(synchronize)];
            [manager setLastUsedVersion];
        });
        
        it(@"should set up proper values and call required methods from createUserIDIfNeeded if userID doesn't exist", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSTimeInterval timeInterval1000 = timeInterval * 1000;
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            
            [[theValue(manager.includeFirstVisit) should] beFalse];
            [[userDefaults should] receive:@selector(doubleForKey:) andReturn:0 withArguments:@"userID"];
            [[userDefaults should] receive:@selector(setDouble:forKey:) withArguments:theValue(timeInterval1000), @"userID"];
            [[userDefaults should] receive:@selector(synchronize)];
            [[NSDate should] receive:@selector(date) andReturn:date];
            [[date should] receive:@selector(timeIntervalSince1970) andReturn:theValue(timeInterval)];
            
            [manager createUserIDIfNeeded];
            
            [[theValue(manager.includeFirstVisit) should] beTrue];
            [[theValue(manager.userID) should] equal:theValue(timeInterval1000)];
            [[theValue(manager.sessStartTime) should] equal:theValue(manager.userID)];
        });
        
        it(@"should set up proper values and call required methods from createUserIDIfNeeded if userID does exist", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSTimeInterval timeInterval1000 = timeInterval * 1000;
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            
            [[theValue(manager.includeFirstVisit) should] beFalse];
            [[userDefaults should] receive:@selector(doubleForKey:) andReturn:theValue(timeInterval1000) withArguments:@"userID"];
            [[userDefaults shouldNot] receive:@selector(setDouble:forKey:)];
            [[userDefaults shouldNot] receive:@selector(synchronize)];
            
            [manager createUserIDIfNeeded];
            
            [[theValue(manager.includeFirstVisit) should] beTrue];
            [[theValue(manager.userID) should] equal:theValue(timeInterval1000)];
            [[theValue(manager.sessStartTime) shouldNot] equal:theValue(manager.userID)];
        });
        
        it(@"should call required method from processSession", ^{
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[manager should] receive:@selector(createUserIDIfNeeded)];
            [[manager should] receive:@selector(refreshSessStartTimeIfNeeded)];
            [manager processSession];
        });
        
        it(@"should return a proper NSString object with appropriate value", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSTimeInterval timeInterval1000 = timeInterval * 1000;
            NSString* timeInterval1000String = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble: floor(timeInterval1000)]];
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            NSString* timeString = [manager timeToString:timeInterval1000];
            [timeString shouldNotBeNil];
            [[timeString should] beKindOfClass:[NSString class]];
            [[timeString should] equal:timeInterval1000String];
        });
        
        it(@"should generate new session if 0 is greater than or equal to sessStartTime", ^{
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[manager should] receive:@selector(sessStartTime) andReturn:theValue(0)];
            [[manager should] receive:@selector(generateNewSession)];
            [manager refreshSessStartTimeIfNeeded];
        });
        
        it(@"should not generate new session if 0 is less than sessStartTime and timeWhenPaused is 0", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[manager should] receive:@selector(sessStartTime) andReturn:theValue(timeInterval) withCountAtLeast:1];
            [[manager should] receive:@selector(timeWhenPaused) andReturn:theValue(0)];
            [[manager shouldNot] receive:@selector(generateNewSession)];
            [manager refreshSessStartTimeIfNeeded];
        });
        
        it(@"should generate new session if 0 is less than sessStartTime and timeWhenPaused is greater than 0", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[manager should] receive:@selector(sessStartTime) andReturn:theValue(timeInterval) withCountAtLeast:1];
            [[manager should] receive:@selector(timeWhenPaused) andReturn:theValue(timeInterval) withCount:2];
            [[manager should] receive:@selector(generateNewSession)];
            [manager refreshSessStartTimeIfNeeded];
            //[[theValue(manager.timeWhenPaused) should] equal:theValue(0)];
        });
        
        it(@"should generate a new session", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSTimeInterval timeInterval1000 = timeInterval * 1000;
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[theValue(manager.sessStartTime) shouldNot] equal:theValue(timeInterval1000)];
            [[NSDate should] receive:@selector(date) andReturn:date];
            [[date should] receive:@selector(timeIntervalSince1970) andReturn:theValue(timeInterval)];
            [manager generateNewSession];
            [[theValue(manager.sessStartTime) should] equal:theValue(timeInterval1000)];
            [[theValue(manager.includeFirstVisit) should] beTrue];
        });
        
        it(@"should mark time paused", ^{
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            NSDate *date = [df dateFromString:@"2013-04-23 14:50:14 +0000"];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            
            JFAnalyticsClient* manager = [[JFAnalyticsClient alloc] init];
            [[theValue(manager.timeWhenPaused) shouldNot] equal:theValue(timeInterval)];
            [[NSDate should] receive:@selector(date) andReturn:date];
            [[date should] receive:@selector(timeIntervalSince1970) andReturn:theValue(timeInterval)];
            [manager markTimePaused];
            [[theValue(manager.timeWhenPaused) should] equal:theValue(timeInterval)];
        });
    });
});

SPEC_END