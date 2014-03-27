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

#### Step 1:
Initialize JFAnalyticsClient using the designated initializer. This MUST happen before trying to access sharedClient. Also, optionally set the desired tagQueueLimit.

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [JFAnalyticsClient clientWithProjectID:@"YOUR-KEEN.IO-PROJECT-KEY" writeKey:@"YOUR-KEEN.IO-WRITE-KEY" readKey:@"YOUR-KEEN.IO-READ-KEY"];
    [[JFAnalyticsClient sharedInstance] setTagQueueLimit:5]; // Defaults to 20
	
    // Additional application setup here

    return YES;
}
```

#### Step 2:
Set the site variable by calling setSite: and passing in the appropriate string constant for the current environment.

```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application
{
#ifdef DEBUG
    [[JFAnalyticsClient sharedClient] setEnvironment:@"dev"];
#else
    [[JFAnalyticsCLient sharedClient] setEnvironment:@"prod"];
#endif
}
```

#### Step 3:
Send all queued tags when a user leaves the application to ensure tags are not lost (if user never returns).

```objective-c
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    UIBackgroundTaskIdentifier taskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        NSLog(@"Background task is being expired.");
    }];
    
    [[JFAnalyticsClient sharedClient] sendQueuedTagsWithCompletionHandler:^(void) {
        [application endBackgroundTask:taskId];
    }];
}
```

#### Step 4: Optionally add any global tags to be fired with all tags.

```objective-c
[[JFAnalyticsClient sharedClient] addGlobalTag:@{@"globalKey": @"globalValue"}];
```

#### Step 5: Track analytical events.

```objective-c
/**
 * Fire custom tags by simply passing in an NSDictionary of KVP's
 */
[[JFAnalyticsClient sharedClient] track:@{@"tap": @"Dismiss Button"}];
[[JFAnalyticsClient sharedClient] track:@{@"screen": @"Map", @"action": @"search"}];
[[JFAnalyticsClient sharedClient] track:@{@"screen": @"Detail", @"view": @"bottom-toolbar", @"action": @"save"}];
```

Queued tags will be sent after the `tagQueueLimit` has been reached and there are no tags currently being sent. Also when the application is backgrounded.

Keen.io Reporting:
------------------

As mentioned above, all KVP's are sent to your keen.io account. Keen.io is not your typical analytics service. It's essentially a glorified Key/Value store that offers a feature rich API. Let's take a look at a couple ways you can check your analytical data and create "Saved Queries" for quick and easy future execution.

#### Step 1: Verify that you are receiving tags in your keen.io account.

After you log in, click on the "Project Overiview" tab near the top of the page then find the "Event Explorer" section. Click on the "Select an Event Collection" dropdown menu and choose your apps collection. The name should be "YourAppName Events". Now select the "Last 10 Events" tab and you should see something like this...

![Event Collection](https://www.evernote.com/shard/s4/sh/61c372f9-c512-4f96-8896-f76b74c645e4/e81fe54f9e60a820a473183097ff973a/deep/0/Keen-IO---The-API-for-Custom-Analytics.png)

You can click on any of the events listed and it will show you the structure of the KVP's as they were received by keen.io.

#### Step 2: Query events for specific data.

Access the "Workbench" tab near the top of the page. Here is where you can manually build up queries to parse through your data. This should all be pretty self explanitory. If not, just click on the "?" icon next to any field that you are not sure of. This will open the documentaion and help clarify what it does.

#### Step 3: Saving queries for quick and easy future execution:

Unfortunatly, this can't be done from the website, not sure why. However, using a simple `curl` command you can do this through the API. Here's an example command that will create a saved query in your account within the "Saved Queries" tab.

**Please note:** You will need to replace the following in each of the examples below with your specific information:

- **YourAppNameHere**
- **Your-Project-ID-Here**
- **Your-Desired-Saved-Query-Name-Here**
- **Your-Master-API-Key-Here**

Basic request to store a new Saved Query for the count of all firstVisit tags. This will indicate new users.
```
curl -X PUT -H "Content-Type: application/json" -d '{"event_collection":"YourAppNameHere Events", "analysis_type":"count", "timeframe":"today", "interval":"hourly", "filters":[{"property_name":"first_visit", "operator":"exists", "property_value":true}]}' https://api.keen.io/3.0/projects/Your-Project-ID-Here/saved_queries/Your-Desired-Saved-Query-Name-Here?api_key=Your-Master-API-Key-Here
```

Basic request to store a new Saved Query for the count of all events that fired for an iOS device running iOS 7.1.
```
curl -X PUT -H "Content-Type: application/json" -d '{"event_collection":"YourAppNameHere Events", "analysis_type":"count", "timeframe":"today", "interval":"hourly", "filters":[{"property_name":"os", "operator":"eq", "property_value":"7.1"}]}' https://api.keen.io/3.0/projects/Your-Project-ID-Here/saved_queries/Your-Desired-Saved-Query-Name-Here?api_key=Your-Master-API-Key-Here
```

Basic request to store a new Saved Query for the count of all events that fired for a specific app version.
```
curl -X PUT -H "Content-Type: application/json" -d '{"event_collection":"YourAppNameHere Events", "analysis_type":"count", "timeframe":"today", "interval":"hourly", "filters":[{"property_name":"app_version", "operator":"eq", "property_value":"<Your-Desired-App-Version>"}]}' https://api.keen.io/3.0/projects/Your-Project-ID-Here/saved_queries/Your-Desired-Saved-Query-Name-Here?api_key=Your-Master-API-Key-Here
```

#### Step 4: 

Execute "Saved Queries" from the website.

![Saved Queries](https://www.evernote.com/shard/s4/sh/946672be-a7ea-4f7a-a44a-095336ad951c/3ef72a734aa19d1fec0736f5be6ae18b/deep/0/Keen-IO---The-API-for-Custom-Analytics.png)

Open the Saved Queries tab near the top of the page. You should now see all of your Saved Queires. To execute a Saved Query, just click on the name of the Saved Query.