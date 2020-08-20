//
//  AppDelegate+livetex.m
//  cordova-plugin-livetex
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+linphone.h"
#import "ProductModuleName-Swift.h"
#import <objc/runtime.h>

@import Firebase;
@import FirebaseInstanceID;


@implementation AppDelegate (livetex)

ChatViewModel *chatViewModel;
BOOL livetexFromPush;
BOOL livetexSwapped;

- (id) getCommandInstance:(NSString*)className
{
    return [self.viewController getCommandInstance:className];
}

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"livetex: installing swizzle");
        Class class = [self class];

        SEL originalSelector = @selector(init);
        SEL swizzledSelector = @selector(livetex_swizzled_init);

        Method original = class_getInstanceMethod(class, originalSelector);
        Method swizzled = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzled),
                        method_getTypeEncoding(swizzled));

        if (didAddMethod) {
            NSLog(@"livetex swizzling method");
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(original),
                                method_getTypeEncoding(original));
        } else {
            NSLog(@"livetex exchanging method");
            method_exchangeImplementations(original, swizzled);
        }
    });
}

- (AppDelegate *)livetex_swizzled_init
{
    NSLog(@"livetex swizzled init");
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(livetexOnApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(livetexOnApplicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initLivetexCore:) name:@"UIApplicationDidFinishLaunchingNotification" object:nil];

    // This actually calls the original init method over in AppDelegate. Equivilent to calling super
    // on an overrided method, this is not recursive, although it appears that way. neat huh?
    return [self livetex_swizzled_init];
}

- (void)livetexOnApplicationDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"livetex onApplicationDidBecomeActive");
    if (chatViewModel) {
        [chatViewModel applicationWillEnterForeground];
    }
    if (livetexFromPush) {
        livetexFromPush = FALSE;
        [self showChatDialog];
        NSLog(@"livetex opened from push notification");
    }
}

- (void)livetexOnApplicationDidEnterBackground:(NSNotification *)notification
{
    NSLog(@"livetex onApplicationDidEnterBackground");
    if (chatViewModel) {
        [chatViewModel applicationDidEnterBackground];
    }
    [self hideChatDialog];
}

//  FCM refresh token
//  Unclear how this is testable under normal circumstances
- (void)livetexOnTokenRefresh {
#if !TARGET_IPHONE_SIMULATOR
    // A rotation of the registration tokens is happening, so the app needs to request a new token.
    NSLog(@"The FCM registration token needs to be changed.");
    [[FIRInstanceID instanceID] instanceIDWithHandler:^(FIRInstanceIDResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error fetching remote instance ID: %@", error);
        } else {
            NSLog(@"Remote instance ID token: %@", result.token);
            [chatViewModel applicationDidRegisterForRemoteNotifications:result.token];
        }
    }];
#endif
}

// contains error info
- (void)livetexSendDataMessageFailure:(NSNotification *)notification {
    NSLog(@"sendDataMessageFailure");
}

- (void)livetexSendDataMessageSuccess:(NSNotification *)notification {
    NSLog(@"sendDataMessageSuccess");
}

- (void)livetexDidSendDataMessageWithID:messageID {
    NSLog(@"didSendDataMessageWithID");
}

- (void)livetexWillSendDataMessageWithID:messageID error:error {
    NSLog(@"willSendDataMessageWithID");
}

- (void)livetexDidDeleteMessagesOnServer {
    NSLog(@"didDeleteMessagesOnServer");
    // Some messages sent to this device were deleted on the GCM server before reception, likely
    // because the TTL expired. The client should notify the app server of this, so that the app
    // server can resend those messages.
}

- (void)showChatDialog {
    Livetex *livetex = [self getCommandInstance:@"Livetex"];
    [livetex showChat];
}

- (void)hideChatDialog {
    Livetex *livetex = [self getCommandInstance:@"Livetex"];
    [livetex hideChat];
}

- (void)livetexApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"livetex Received Remote notification");
    if (livetexSwapped) {
        [self livetexApplication:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
    if ([userInfo[@"aps"][@"category"] isEqual: @"chat_message"]) {
        NSLog(@"!!!! chat message!!! ");
        if(application.applicationState != UIApplicationStateActive) {
            livetexFromPush = TRUE;
        } else {
            // [self showChatDialog];  // do not open chat dialog while running
            NSLog(@"received push notification while foreground");
            livetexFromPush = FALSE;
        }
    } else {
        livetexFromPush = FALSE;
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)livetexSetupPushHandlers
{
    // this = self;
    if ([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
        NSLog(@"livetex swapping listener");
        Method original, swizzled;
        original = class_getInstanceMethod([self class], @selector(livetexApplication:didReceiveRemoteNotification:fetchCompletionHandler:));
        swizzled = class_getInstanceMethod([[[UIApplication sharedApplication] delegate] class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
        method_exchangeImplementations(original, swizzled);
        livetexSwapped = TRUE;
    } else {
        NSLog(@"livetex adding listener");
        class_addMethod([[[UIApplication sharedApplication] delegate] class], @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:), class_getMethodImplementation([self class], @selector(livetexApplication:didReceiveRemoteNotification:fetchCompletionHandler:)), nil);
        livetexSwapped = FALSE;
    }
}

- (void)initLivetexPushNotifications {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([FIRApp defaultApp] == nil) {
            NSLog(@"configuring Firebase");
            [FIRApp configure];
        }
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(livetexOnTokenRefresh)
         name:kFIRInstanceIDTokenRefreshNotification object:nil];

        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(livetexSendDataMessageFailure:)
         name:FIRMessagingSendErrorNotification object:nil];

        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(livetexSendDataMessageSuccess:)
         name:FIRMessagingSendSuccessNotification object:nil];

        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(livetexDidDeleteMessagesOnServer)
         name:FIRMessagingMessagesDeletedNotification object:nil];
        [self livetexSetupPushHandlers];
    });
    if (![self livetexPermissionState]) {
        NSLog(@"push notifications are not registered");
        if ([UNUserNotificationCenter class] != nil) {
          // iOS 10 or later
          // For iOS 10 display notification (sent via APNS)
          // [UNUserNotificationCenter currentNotificationCenter].delegate = self;
          UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
          [[UNUserNotificationCenter currentNotificationCenter]
              requestAuthorizationWithOptions:authOptions
              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                // ...
                if (granted && !error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                           [[UIApplication sharedApplication] registerForRemoteNotifications];
                           NSLog(@"registered for remote push");
                       });
                } else {
                    NSLog(@"not granted for iOS");
                }
              }];
        } else {
            NSLog(@"not supported iOS version for notifications");
        }
    }
}

- (BOOL)livetexPermissionState
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    } else {
        return [[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone;
    }
}

- (void)initLivetexCore:(NSNotification *)notification
{
    NSLog(@"initLivetexCore");
    livetexFromPush = FALSE;
    chatViewModel = [ChatViewModel shared];
    [self initLivetexPushNotifications];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
    NSLog(@"dealloc");
}

@end
