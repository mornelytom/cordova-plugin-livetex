//
//  AppDelegate+livetex.m
//  cordova-plugin-livetex
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+livetex.h"
#import "ProductModuleName-Swift.h"
#import <objc/runtime.h>

@import Firebase;
@import FirebaseInstanceID;


@implementation AppDelegate (livetex)

ChatViewModel *chatViewModel;
BOOL livetexFromPush;
unsigned char livetexSwapped;
const unsigned char livetexSwapped_userNotificationCenter_willPresentNotification = 1;
const unsigned char livetexSwapped_userNotificationCenter_didReceiveNotificationResponse = 2;

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
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(original),
                                method_getTypeEncoding(original));
        } else {
            method_exchangeImplementations(original, swizzled);
        }
    });
}

- (AppDelegate *)livetex_swizzled_init
{
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
    if (chatViewModel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [chatViewModel applicationWillEnterForeground];
        });
    }
    if (livetexFromPush) {
        livetexFromPush = FALSE;
        [self showChatDialog];
    }
}

- (void)livetexOnApplicationDidEnterBackground:(NSNotification *)notification
{
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
    [livetex hideChat:false];
}

- (void)initLivetexPushNotifications {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([FIRApp defaultApp] == nil) {
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
        [self livetexSetupNewPushHandlers];
    });
    if (![self livetexPermissionState]) {
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
                       });
                }
              }];
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
    livetexFromPush = FALSE;
    chatViewModel = [ChatViewModel shared];
    [self initLivetexPushNotifications];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

#pragma mark - REMOTE NOTIFICATION DELEGATE

- (void)livetexSetupNewPushHandlers
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    livetexSwapped = 0;
    if ([[center delegate] respondsToSelector:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)]) {
        NSLog(@"livetex swapping userNotificationCenter:willPresentNotification listener");
        Method original, swizzled;
        original = class_getInstanceMethod([self class], @selector(livetexUserNotificationCenter:willPresentNotification:withCompletionHandler:));
        swizzled = class_getInstanceMethod([[center delegate] class], @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:));
        method_exchangeImplementations(original, swizzled);
        livetexSwapped += livetexSwapped_userNotificationCenter_willPresentNotification;
    } else {
        NSLog(@"livetex adding userNotificationCenter:willPresentNotification listener");
        class_addMethod([[center delegate] class], @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:), class_getMethodImplementation([self class], @selector(livetexUserNotificationCenter:willPresentNotification:withCompletionHandler:)), nil);
    }
    if ([[center delegate] respondsToSelector:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)]) {
        NSLog(@"livetex swapping userNotificationCenter:didReceiveNotificationResponse listener");
        Method original, swizzled;
        original = class_getInstanceMethod([self class], @selector(livetexUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:));
        swizzled = class_getInstanceMethod([[center delegate] class], @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:));
        method_exchangeImplementations(original, swizzled);
        livetexSwapped += livetexSwapped_userNotificationCenter_didReceiveNotificationResponse;
    } else {
        NSLog(@"livetex adding userNotificationCenter:didReceiveNotificationResponse listener");
        class_addMethod([[center delegate] class], @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:), class_getMethodImplementation([self class], @selector(livetexUserNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)), nil);
    }
}

-(void)livetexUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    //Called when a notification is delivered to a foreground app.
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (livetexSwapped & livetexSwapped_userNotificationCenter_willPresentNotification) {  // call swizzled method
        [self livetexUserNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
    }
    if ([userInfo[@"aps"][@"category"] isEqual: @"chat_message"] || [userInfo[@"type"] isEqual: @"chat_message"]) {
        NSLog(@"got chat message");
        livetexFromPush = FALSE;
        Livetex *livetex = [self getCommandInstance:@"Livetex"];
        [livetex onPush];
    }
    completionHandler(UNNotificationPresentationOptionNone);
}

-(void)livetexUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if (livetexSwapped & livetexSwapped_userNotificationCenter_didReceiveNotificationResponse) {  // call swizzled method
        [self livetexUserNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    }
    if ([userInfo[@"aps"][@"category"] isEqual: @"chat_message"] || [userInfo[@"type"] isEqual: @"chat_message"]) {
        livetexFromPush = TRUE;
    }
    completionHandler();
}

@end
