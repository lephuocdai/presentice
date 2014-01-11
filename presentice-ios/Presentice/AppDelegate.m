//
//  AppDelegate.m
//  SidebarDemo
//
//  Created by Simon on 28/6/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // ****************************************************************************
    // Parse initialization
    [Parse setApplicationId:@"Q7ub1yg5A0AmDAnwnzVc2SS0X0Q4UZMefq3Kukdf" clientKey:@"W4MvbeHuoqhmtPhvGHt29JziWfFeVJNbuaFp2lr1"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [PFFacebookUtils initializeFacebook];
    // ****************************************************************************

    NSLog(@"before push notification register");
    //Push Notification Test
    // Register for push notifications
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
    // Extract the notification data
//    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    NSLog(@"after push notification register");

    // Setting for SideMenu
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
//    MFSideMenuContainerViewController *container = (MFSideMenuContainerViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"navigationController"];
//    
//    UIViewController *leftSideMenuViewController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
//    UIViewController *rightSideMenuViewController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
//    
//    [container setLeftMenuViewController:leftSideMenuViewController];
//    [container setRightMenuViewController:rightSideMenuViewController];
//    [container setCenterViewController:navigationController];
    
    UIImage *navBackgroundImage = [UIImage imageNamed:@"nav_bg"];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:10.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                           [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 0)],
                                                           UITextAttributeTextShadowOffset,
                                                           [UIFont fontWithName:@"Helvetica-Light" size:20.0], UITextAttributeFont, nil]];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", newDeviceToken);
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
    NSLog(@"currentInstallation: %@",currentInstallation);
}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateInactive) {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    [PFPush handlePush:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


// ****************************************************************************
// App switching methods to support Facebook Single Sign-On.
// ****************************************************************************

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}
@end
