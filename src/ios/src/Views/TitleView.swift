//
//  TitleView.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

class TitleView: UIView {

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            if newValue != title {
                titleLabel.text = newValue
                setNeedsLayout()
            }
        }
    }

    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            if newValue != subtitle {
                subtitleLabel.text = newValue
                subtitleLabel.isHidden = newValue?.isEmpty ?? true
                setNeedsLayout()
            }
        }
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center
        label.textColor = .black
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.frame = CGRect(x: 0,
                                  y: 0,
                                  width: bounds.width,
                                  height: subtitleLabel.isHidden ? bounds.height : titleLabel.font.lineHeight)

        subtitleLabel.frame = CGRect(x: 0,
                                     y: titleLabel.frame.maxY,
                                     width: bounds.width,
                                     height: subtitleLabel.font.lineHeight)
    }

}
