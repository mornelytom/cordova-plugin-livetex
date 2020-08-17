//
//  FollowTextMessageCollectionViewCell.swift
//  LivetexMessaging
//
//  Created by Livetex on 06.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import MessageKit

class FollowTextMessageCollectionViewCell: TextMessageCollectionViewCell {

    private let followMessageView = FollowMessageView(frame: .zero)

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        followMessageView.text = nil
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? CustomMessagesCollectionViewLayoutAttributes else {
            return
        }
        followMessageView.frame = CGRect(x: attributes.followMessageViewInsets.left,
                                         y: attributes.followMessageViewInsets.top,
                                         width: messageContainerView.bounds.width - attributes.followMessageViewInsets.horizontal,
                                         height: 20)
        messageLabel.frame.origin.y = 20
    }

    // MARK: - Configuration

    override func setupSubviews() {
        super.setupSubviews()

        messageContainerView.addSubview(followMessageView)
    }

    override func configure(with message: MessageType,
                            at indexPath: IndexPath,
                            and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard case let .custom(data) = message.kind,
              case let .follow(text, messageText) = data as? CustomType,
              let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            return
        }

        let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
        messageLabel.textColor = textColor
        followMessageView.tintColor = textColor
        followMessageView.isCancelButtonHidden = true
        followMessageView.text = text
        messageLabel.text = messageText
    }
    
}
