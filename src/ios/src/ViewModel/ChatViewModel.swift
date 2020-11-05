//
//  ChatViewModel.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import MessageKit
import LivetexCore


@objc(ChatViewModel) class ChatViewModel : NSObject {
    @objc(shared) static let shared = ChatViewModel()

    var onDepartmentReceived: (([Department]) -> Void)?
    var onLoadMoreMessages: (([ChatMessage]) -> Void)?
    var onMessagesReceived: (([ChatMessage]) -> Void)?
    var onDialogStateReceived: ((Conversation) -> Void)?
    var onAttributesReceived: (() -> Void)?
    var onTypingReceived: (() -> Void)?
    var onMessageCallback: (() -> Void)?

    var followMessage: String?
    var messages: [ChatMessage] = []

    var user = Recipient(senderId: UUID().uuidString, displayName: "")

    private(set) var sessionService: LivetexSessionService?

    private let loadMoreOffset = 20

    private(set) var isContentLoaded = false
    private(set) var isLoadingMore = false

    private var isCanLoadMore = true

    private(set) var isEmployeeEstimated = true

    private let settings = LivetexSettings()

    public var lastMessage: Int?

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Configuration

    private func requestAuthentication(deviceToken: String) {
        // settings.visitorToken = nil
        let loginService = LivetexAuthService(token: settings.visitorToken.map { .system($0) },
                                               deviceToken: deviceToken)

        loginService.requestAuthorization { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .success(token):
                    self?.startSession(token: token)
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func startSession(token: SessionToken) {
        settings.visitorToken = token.visitorToken
        sessionService = LivetexSessionService(token: token)
        sessionService?.onEvent = { [weak self] event in
            self?.didReceive(event: event)
        }

        sessionService?.connect()
    }

    func loadMoreMessagesIfNeeded() {
        guard isCanLoadMore else {
            return
        }

        let event = ClientEvent(.getHistory(messages.first?.messageId ?? "", loadMoreOffset))
        sessionService?.sendEvent(event)
        isLoadingMore = true
    }

    // MARK: - Application Lifecycle

    @objc(applicationDidEnterBackground) func applicationDidEnterBackground() {
        sessionService?.disconnect()
    }

    @objc(applicationWillEnterForeground) func applicationWillEnterForeground() {
        sessionService?.connect()
    }

    /* @objc func applicationDidRegisterForRemoteNotifications(_ notification: Notification) {
        let deviceToken = notification.object as? String
        requestAuthentication(deviceToken: deviceToken ?? "")
    } */
    @objc(applicationDidRegisterForRemoteNotifications:) func applicationDidRegisterForRemoteNotifications(deviceToken: String) {
        //let deviceToken = notification.object as? String
        requestAuthentication(deviceToken: deviceToken ?? "")
        NSLog("livetex requestAuthentication")
    }

    // MARK: - Session

    func sendEvent(_ event: ClientEvent) {
        let isConnected = sessionService?.isConnected ?? false
        if !isConnected {
            sessionService?.connect()
        }

        sessionService?.sendEvent(event)
    }

    private func didReceive(event: ServiceEvent) {
        switch event {
        case let .result(result):
            print(result)
        case let .state(result):
            isEmployeeEstimated = result.isEmployeeEstimated
            onDialogStateReceived?(result)
        case .attributes:
            onAttributesReceived?()
        case let .departments(result):
            onDepartmentReceived?(result.departments)
        case let .update(result):
            messageHistoryReceived(items: result.messages)
        case .employeeTyping:
            onTypingReceived?()
        }
    }

    func isPreviousMessageSameDate(at index: Int) -> Bool {
        guard index - 1 >= 0 else {
            return false
        }

        let currentDate = messages[index].sentDate
        let previousDate = messages[index - 1].sentDate
        return Calendar.current.isDate(currentDate, inSameDayAs: previousDate)
    }

    private func convertMessages(_ messages: [Message]) -> [ChatMessage] {
        return messages.map {
            let kind: MessageKind
            let sender = $0.creator.isVisitor ? self.user : Recipient(senderId: "",
                                                                      displayName: $0.creator.employee?.name ?? "")
            switch $0.content {
            case let .text(text):
                let extensions: Set<String> = ["png", "jpg", "jpeg", "gif"]
                if extensions.contains((text as NSString).pathExtension) {
                    kind = .photo(File(url: text))
                } else if text.first == ">" {
                    let texts = text.trimmingCharacters(in: CharacterSet(charactersIn: "> ")).split(separator: "\n")
                    kind = .custom(CustomType.follow(String(texts.first ?? ""), String(texts.last ?? "")))
                } else {
                    kind = $0.creator.type == .system ? .custom(CustomType.system(text)) : .text(text)
                }
            case let .file(attachment):
                kind = .photo(File(url: attachment.url))
            }

            return ChatMessage(sender: sender,
                               messageId: $0.id,
                               sentDate: $0.createdAt,
                               kind: kind,
                               creator: $0.creator)
        }
    }

    private func messageHistoryReceived(items: [Message]) {
        guard !items.isEmpty else {
            isCanLoadMore = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.isLoadingMore = false
            var newMessages = Array(Set(self.convertMessages(items)).subtracting(self.messages))
            let currentDate = self.messages.first?.sentDate ?? Date()
            let receivedDate = newMessages.last?.sentDate ?? Date()
            newMessages.sort(by: { $0.sentDate < $1.sentDate })
            DispatchQueue.main.async {
                if !self.messages.isEmpty, receivedDate.compare(currentDate) == .orderedAscending {
                    self.onLoadMoreMessages?(newMessages)
                } else {
                    self.onMessagesReceived?(newMessages)
                    let lastMessage: Int? = UserDefaults.standard.integer(forKey: "livetex.lastMessage")
                    if (newMessages.last != nil && (lastMessage == nil || lastMessage! < Int(newMessages.last!.sentDate.timeIntervalSince1970))) {
                        self.lastMessage = Int(newMessages.last!.sentDate.timeIntervalSince1970)
                        self.onMessageCallback?()
                    }
                    self.isContentLoaded = true
                }
            }
        }
    }

}
