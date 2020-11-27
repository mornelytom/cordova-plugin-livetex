//
//  Livetex.swift
//  cordova-plugin-livetex
//
//  Created by Leandr Khaliullov on 2020-08-14.
//  Copyright © 2020 Simdev, LCC. All rights reserved.
//

import LivetexCore


class UINavigationControllerLight: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                return .darkContent
            } else {
                return .darkContent
            }
        } else {
            return .lightContent
        }
    }

}


@objc(Livetex) class Livetex : CDVPlugin {
    var chatViewController: ChatViewController?
    var navController: UINavigationController?
    private var callbackId: String?
    private var nickname: String = "Guest"

    @objc(init:)
    func initilize(command: CDVInvokedUrlCommand) {
        let storyboard = UIStoryboard(name: "Livetex", bundle: nil)
        chatViewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        self.navController = UINavigationControllerLight(rootViewController: self.chatViewController!)
        self.navController?.navigationBar.barTintColor = UIColor(hex: 0xFFFFFF, alpha: 1)
        self.navController?.modalPresentationStyle = .fullScreen
        NotificationCenter.default.addObserver(self, selector: #selector(self.chatExit(notification:)), name: Notification.Name("ChatClose"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.chatLoaded(notification:)), name: Notification.Name("ChatViewLoaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.chatDrain(notification:)), name: Notification.Name("ChatDrain"), object: nil)
    }

    @objc func chatDrain(notification: Notification) {
        let chatViewModel: ChatViewModel = ChatViewModel.shared
        UserDefaults.standard.set(chatViewModel.lastMessage, forKey: "livetex.lastMessage")
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
            var identifiers: Array<String> = []
            for notification in notifications {
                if (notification.request.content.categoryIdentifier == "chat_message") {
                    identifiers.append(notification.request.identifier)
                }
            }
            if (identifiers.count > 0) {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        })
    }

    @objc func chatExit(notification: Notification) {
        self.hideChat(animated: true)
    }

    @objc(showChat)
    func showChat() {
        if (!self.navController!.isBeingPresented) {
            let chatViewModel: ChatViewModel = ChatViewModel.shared
            self.viewController.present(self.navController!, animated: true)
            chatViewModel.applicationWillEnterForeground()
        }
    }

    @objc(onPush)
    func onPush() {
        let chatViewModel: ChatViewModel = ChatViewModel.shared
        chatViewModel.onMessageCallback?()
    }

    func localNotify() {
        let result: CDVPluginResult? = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "receive")
        result?.setKeepCallbackAs(true)
        self.commandDelegate!.send(result, callbackId: self.callbackId)
    }

    @objc func chatLoaded(notification: Notification) {
        let chatViewModel: ChatViewModel = ChatViewModel.shared
        chatViewModel.onMessageCallback = {
            if (self.callbackId != nil && self.topMostController() != self.navController!) {
                self.localNotify()
            }
        }
        chatViewModel.onAttributesReceived = {
            let attributes = LivetexCore.Attributes(name: self.nickname,
                                        phone: "",
                                        email: "")
            chatViewModel.user.displayName = self.nickname
            chatViewModel.sendEvent(LivetexCore.ClientEvent(.attributes(attributes)))
        }
    }

    func topMostController() -> UIViewController? {
        guard let window = UIApplication.shared.keyWindow, let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController

        while let newTopController = topController.presentedViewController {
            topController = newTopController
        }

        return topController
    }

    @objc(hideChat:)
    func hideChat(animated: Bool = false) {
        if (self.topMostController() == self.navController!) {
            if (animated) {
                self.viewController.dismiss(animated: true)
                let chatViewModel: ChatViewModel = ChatViewModel.shared
                chatViewModel.applicationWillEnterForeground()
            } else {
                DispatchQueue.main.async {
                    self.viewController.dismiss(animated: false)
                }
            }
        }
    }

    @objc(open:)
    func open(command: CDVInvokedUrlCommand) {
        self.nickname = command.arguments[0] as? String ?? "Guest"
        let chatViewModel: ChatViewModel = ChatViewModel.shared

        let topController: UIViewController? = self.topMostController()
        if (self.navController!.isBeingPresented || topController == self.navController!) {
            NSLog("chat already opened")
        } else {
            if (self.viewController != topController) {
                NSLog("livetex: closing all modal windows")
                self.viewController.dismiss(animated: false, completion: {
                    self.viewController.present(self.navController!, animated: true, completion: nil)
                })
                return
            }
            self.viewController.present(self.navController!, animated: true, completion: nil)
        }

        chatViewModel.applicationWillEnterForeground()
    }

    @objc(callback:)
    func callback(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        let lastMessage: Int? = UserDefaults.standard.integer(forKey: "livetex.lastMessage")
        let chatViewModel: ChatViewModel = ChatViewModel.shared
        if (chatViewModel.lastMessage != nil && lastMessage !=  nil && lastMessage! < chatViewModel.lastMessage!) {
            self.localNotify()
        }
    }

    @objc(destroy:)
    func destroy(command: CDVInvokedUrlCommand) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChatClose"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChatViewLoaded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ChatDrain"), object: nil)
    }
}