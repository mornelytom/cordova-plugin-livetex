//
//  MessageInputBarView.swift
//  LivetexMessaging
//
//  Created by Livetex on 06.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import InputBarAccessoryView

class MessageInputBarView: InputBarAccessoryView {

    var onAttachmentButtonTapped: (() -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        configure()
    }

    // MARK: - Configuration

    private func configure() {
        backgroundColor = .white
        separatorLine.isHidden = true
        inputTextView.backgroundColor = .white
        inputTextView.textColor = .black
        inputTextView.placeholder = "Введите сообщение"
        topStackViewPadding = UIEdgeInsets(top: 5, left: 40, bottom: 5, right: 40)

        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 36, bottom: 8, right: 36)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 40, bottom: 8, right: 40)
        inputTextView.layer.borderWidth = 2
        inputTextView.layer.cornerRadius = 16
        inputTextView.layer.masksToBounds = true
        inputTextView.autocorrectionType = .yes
        inputTextView.layer.borderColor = UIColor.messageGray.cgColor

        let attachmentButton = InputBarButtonItem().configure {
                $0.image = UIImage(asset: .attachment)?.withRenderingMode(.alwaysOriginal)
                $0.setSize(CGSize(width: 36, height: 36), animated: false)
            }.onTouchUpInside { [weak self] item in
                self?.onAttachmentButtonTapped?()
            }

        setStackViewItems([attachmentButton], forStack: .left, animated: false)

        sendButton.image = UIImage(asset: .send)?.withRenderingMode(.alwaysOriginal)
        sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        sendButton.imageView?.layer.cornerRadius = 16
        inputTextView.addSubview(sendButton)
        inputTextView.addSubview(attachmentButton)
        sendButton.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width*2-60).isActive = true
    }

}