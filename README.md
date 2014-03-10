JF Analytics Client Framework
=============================

This is an open source project for handling analytics within an iOS applications. The backend data store used to store the analytics events (A.K.A. tags) is http://www.keen.io. You’ll need to register for a free account, which provides you with up to 50,000 events per month, in order to utilize this framework. After registering you’ll need your keen.io project ID, write key, and read key. Follow the steps below to setup and use JFAnalyticsClient once you have this information.

Online Documentation will soon be available.

How to Install this Framework:
----------------------------

- Download the pre-compiled framework here: TBD
- OR: Clone this repo, select the “Framework” target, build, right click on “libJFiOSAnalytics.a” under the “Products” folder and choose “Show in Finder”. Once opened in Finder, find the “JFiOSAnalytics.framework” that is in the same directory.
- Drag it into your Xcode project

How to Use This Framework:
--------------------------

#### Step 1: Initialized JFAnalyticsClient using the designated initializer. This MUST happen before trying to access sharedClient.
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [JFAnalyticsClient clientWithProjectID:@“YOUR-KEEN.IO-PROJECT-KEY” writeKey:@“YOUR-KEEN.IO-WRITE-KEY” readKey:@“”YOUR-KEEN.IO-READ-KEY];
    
    // Additional application setup here

    return YES;
}
```

#### Step 2: Set the site variable by calling setSite: and passing in the appropriate string constant for the current environment.

```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application
{
#ifdef DEBUG
    [[JFAnalyticsClient sharedInstance] setEnvironment:@"dev"];
#else
    [[JFAnalyticsCLient sharedInstance] setEnvironment:@"prod"];
#endif
    
    [[JFAnalyticsClient sharedInstance] processSession];
}
```

#### Step 3: Send all queued tags when a user leaves the application to ensure tags are not lost (if user never returns). Also, call processSession to ensure proper session handling.
```objective-c
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[JFAnalyticsClient sharedClient] markTimePaused];

    UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        NSLog(@"Background task is being expired.");
    }];
    
    [[JFAnalyticsClient sharedClient] sendQueuedTagsWithCompletionHandler:^(void) {
        [application endBackgroundTask:taskId];
    }];
}
```

#### Step 4: Optionally set the desired tag queue limit. Default is 20.

```objective-c
[[RPAnalyticsManager sharedInstance] setTagQueueLimit:5];
```

#### Step 5: Optionally add any global tags to be fired with all tags.

```objective-c
[[RPAnalyticsManager sharedInstance] addGlobalTag:@{@"globalKey": @"globalValue"}];
```

#### Step 6: Fire tags for analytical events.

```objective-c
/**
 * Fire custom tags by simply passing in an NSDictionary of KVP's
 */
[[RPAnalyticsManager sharedInstance] fire:@{@“tap”: @“Dismiss Button“}];
[[RPAnalyticsManager sharedInstance] fire:@{@“screen”: @"Map”, @“action”: @“search”}];
[[RPAnalyticsManager sharedInstance] fire:@{@“screen”: @"Detail", @"type": @"pageview"}];
```

Queued tags will be sent after the `tagQueueLimit` has been reached and there are no tags currently being sent. Also when the application is backgrounded.
