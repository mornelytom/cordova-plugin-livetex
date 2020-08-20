//
//  Livetex.swift
//  cordova-plugin-livetex
//
//  Created by Leandr Khaliullov on 2020-08-14.
//  Copyright © 2020 Simdev, LCC. All rights reserved.
//

import LivetexCore


@objc(Livetex) class Livetex : CDVPlugin {
    var chatViewController: ChatViewController?
    private var callbackId: String?

    @objc(init:)
    func initilize(command: CDVInvokedUrlCommand) {
        NSLog("init Livetex")
        let storyboard = UIStoryboard(name: "Livetex", bundle: nil)
        chatViewController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        var chatViewModel: ChatViewModel = ChatViewModel.shared
        chatViewModel.onMessageCallback = {}
    }

    @objc(showChat)
    func showChat() {
        if (!self.chatViewController!.isBeingPresented) {
            var chatViewModel: ChatViewModel = ChatViewModel.shared
            self.viewController.present(self.chatViewController!, animated: true)
            chatViewModel.applicationWillEnterForeground()
        }
    }

    private func initCallback() {
        var chatViewModel: ChatViewModel = ChatViewModel.shared
        chatViewModel.onMessageCallback = {
            NSLog("new message")
            if (self.callbackId != nil && self.topMostController() != self.chatViewController!) {
                var result: CDVPluginResult? = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "receive")
                result?.setKeepCallbackAs(true)
                self.commandDelegate!.send(result, callbackId: self.callbackId)
            }
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

    @objc(hideChat)
    func hideChat() {
        NSLog("hidding chat")
        if (self.topMostController() == self.chatViewController!) {
            NSLog("presented")
            DispatchQueue.main.async {
                self.viewController.dismiss(animated: false)
            }
        }
    }

    @objc(open:)
    func open(command: CDVInvokedUrlCommand) {
        NSLog("open Livetex")
        var nickname = command.arguments[0] as? String ?? ""
        var chatViewModel: ChatViewModel = ChatViewModel.shared
        self.viewController.present(self.chatViewController!, animated: true)
        chatViewModel.onAttributesReceived = {
            let attributes = LivetexCore.Attributes(name: nickname,
                                        phone: "",
                                        email: "")
            chatViewModel.user.displayName = nickname
            chatViewModel.sendEvent(LivetexCore.ClientEvent(.attributes(attributes)))
        }
        self.initCallback()
        chatViewModel.applicationWillEnterForeground()
    }

    @objc(callback:)
    func callback(command: CDVInvokedUrlCommand) {
        NSLog("setting callback Livetex")
        self.callbackId = command.callbackId
        self.initCallback()
    }

    @objc(destroy:)
    func destroy(command: CDVInvokedUrlCommand) {
        NSLog("destroy Livetex")
    }
}

