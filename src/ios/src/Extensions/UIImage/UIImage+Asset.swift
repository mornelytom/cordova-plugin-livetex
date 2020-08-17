//
//  UIImage+Asset.swift
//  LivetexMessaging
//
//  Created by Livetex on 30.06.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

extension UIImage {

    convenience init?(asset: LivetexAsset) {
        self.init(named: asset.rawValue)
    }

}
