//
//  Settings.swift
//  LivetexMessaging
//
//  Created by Livetex on 29.06.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

private struct LivetexKey {
    static let visitorToken = "com.livetex.visitorToken"
}

class LivetexSettings {

    var visitorToken: String? {
        get {
            return UserDefaults.standard.string(forKey: LivetexKey.visitorToken)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: LivetexKey.visitorToken)
        }
    }

}
