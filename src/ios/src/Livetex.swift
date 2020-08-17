//
//  Livetex.swift
//  cordova-plugin-livetex
//
//  Created by Leandr Khaliullov on 2020-08-14.
//  Copyright © 2020 Simdev, LCC. All rights reserved.
//


@objc(Livetex) class Livetex : CDVPlugin {
    @objc(init:)
    func initilize(command: CDVInvokedUrlCommand) {
        NSLog("init Livetex")
    }

    @objc(open:)
    func open(command: CDVInvokedUrlCommand) {
        NSLog("open Livetex")
    }

    @objc(callback:)
    func callback(command: CDVInvokedUrlCommand) {
        NSLog("callback Livetex")
    }

    @objc(destroy:)
    func destroy(command: CDVInvokedUrlCommand) {
        NSLog("destroy Livetex")
    }
}

