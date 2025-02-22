//
//  ChatViewController.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Kingfisher
import SafariServices
import BFRImageViewer
import LivetexCore

class ChatViewController: MessagesViewController, InputBarAccessoryViewDelegate {

    private let titleView = TitleView()

    private let avatarView = OperatorAvatarView()

    private let viewModel = ChatViewModel.shared

    private let estimationView = EstimationView()

    private let messageInputBarView = MessageInputBarView()

    private lazy var typingFunction = DebouncedFunction(timeInterval: 2) { [weak self] in
        self?.setTypingIndicatorViewHidden(true, animated: true)
    }

    override var inputAccessoryView: UIView? {
        return messageInputBarView
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        configureCollectionView()
        super.viewDidLoad()
        if #available(iOS 13.0, *) {  // temporary disable dark theme
            overrideUserInterfaceStyle = .light
        }

        configureInputBar()
        configureViewModel()
        configureNavigationItem()
        // configureEstimationView()
        NotificationCenter.default.post(name: Notification.Name("ChatViewLoaded"), object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navigationBarFrame = navigationController?.navigationBar.frame ?? .zero
        titleView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: 0.7 * navigationBarFrame.width,
                                 height: navigationBarFrame.height)

        avatarView.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))

        layoutEstimationView()
    }

    private func layoutEstimationView() {
        let offset = viewModel.isEmployeeEstimated ? EstimationView.viewHeight : 0
        estimationView.frame = CGRect(x: view.safeAreaLayoutGuide.layoutFrame.minX,
                                      y: view.safeAreaLayoutGuide.layoutFrame.minY - offset,
                                      width: view.safeAreaLayoutGuide.layoutFrame.width,
                                      height: EstimationView.viewHeight)

        messagesCollectionView.contentInset.top = viewModel.isEmployeeEstimated ? 0 : EstimationView.viewHeight
        messagesCollectionView.scrollIndicatorInsets.top = viewModel.isEmployeeEstimated ? 0 : EstimationView.viewHeight
    }

    // MARK: - Configuration

    private func configureEstimationView() {
        view.addSubview(estimationView)

        estimationView.onEstimateAction = { [weak self] action in
            self?.viewModel.sendEvent(ClientEvent(.rating(action == .up ? "1" : "0")))
        }
    }

    private func configureViewModel() {
        viewModel.onDepartmentReceived = { [weak self] departments in
            guard let self = self, !departments.isEmpty else {
                return
            }

            guard departments.count > 1 else {
                self.viewModel.sendEvent(ClientEvent(.department(departments.first?.id ?? "")))
                return
            }

            let actions = departments.map { department in
                return UIAlertAction(title: department.name, style: .default) { _ in
                    self.viewModel.sendEvent(ClientEvent(.department(department.id)))
                }
            }

            let alertController = UIAlertController(title: "Выбор отдела",
                                                    message: "Выберите куда направить ваше обращение",
                                                    preferredStyle: .actionSheet)
            alertController.addActions(actions)
            self.present(alertController, animated: true)
        }

        viewModel.onLoadMoreMessages = { [weak self] newMessages in
            self?.viewModel.messages.insert(contentsOf: newMessages, at: 0)
            self?.messagesCollectionView.reloadDataAndKeepOffset()
        }

        viewModel.onMessageCallback = {}

        viewModel.onMessagesReceived = { [weak self] newMessages in
            guard let self = self else {
                return
            }

            let updates = {
                self.messagesCollectionView.performBatchUpdates({
                    let count = self.viewModel.messages.count
                    let indexSet = IndexSet(integersIn: count..<count + newMessages.count)
                    self.viewModel.messages.append(contentsOf: newMessages)
                    self.messagesCollectionView.insertSections(indexSet)
                }, completion: { _ in
                    self.messagesCollectionView.scrollToBottom(animated: true)
                    NotificationCenter.default.post(name: Notification.Name("ChatDrain"), object: nil)
                })
            }

            if self.viewModel.messages.isEmpty {
                updates()
            } else {
                if self.isTypingIndicatorHidden {
                    updates()
                } else {
                    self.setTypingIndicatorViewHidden(true,
                                                      animated: true,
                                                      whilePerforming: updates,
                                                      completion: nil)
                }
            }
        }

        viewModel.onDialogStateReceived = { [weak self] dialog in
            
            self?.titleView.title = "Служба поддержки"
            self?.titleView.subtitle = dialog.employeeStatus?.rawValue
            self?.avatarView.setImage(with: URL(string: dialog.employee?.avatarUrl ?? ""))

            UIView.animate(withDuration: 0.5) {
                self?.layoutEstimationView()
            }
        }

        viewModel.onTypingReceived = { [weak self] in
            self?.typingFunction.call()
            self?.setTypingIndicatorViewHidden(false, animated: true, completion: { _ in
                self?.messagesCollectionView.scrollToBottom(animated: true)
                NotificationCenter.default.post(name: Notification.Name("ChatDrain"), object: nil)
            })
        }

        viewModel.onAttributesReceived = { [weak self] in
            let alertController = UIAlertController(title: "Атрибуты",
                                                    message: "Необходимо указать обязательные атрибуты",
                                                    preferredStyle: .alert)

            let placeholder = NSMutableAttributedString(string: "* Имя")
            placeholder.setAttributes([.foregroundColor: UIColor.red,
                                       .baselineOffset: 1], range: NSRange(location: 0, length: 1))

            alertController.addTextField { textField in
                textField.attributedPlaceholder = placeholder
            }
            alertController.addTextField { textField in
                textField.placeholder = "Телефон"
                textField.keyboardType = .phonePad
            }
            alertController.addTextField { textField in
                textField.placeholder = "Email"
                textField.keyboardType = .emailAddress
            }
            let accept = UIAlertAction(title: "OK", style: .default) { _ in
                let attributes = Attributes(name: alertController.textFields?[0].text ?? "",
                                            phone: alertController.textFields?[1].text ?? "",
                                            email: alertController.textFields?[2].text ?? "")
                self?.viewModel.user.displayName = alertController.textFields?[0].text ?? ""
                self?.viewModel.sendEvent(ClientEvent(.attributes(attributes)))
            }
            alertController.addActions(accept)
            self?.present(alertController, animated: true)
        }
    }

    private func configureCollectionView() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(TextMessageCollectionViewCell.self)
        messagesCollectionView.register(SystemMessageCollectionViewCell.self)
        messagesCollectionView.register(FollowTextMessageCollectionViewCell.self)
        messagesCollectionView.delegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 0,
                                                                                                   bottom: 0,
                                                                                                   right: 16)))
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 0,
                                                                                                   bottom: 0,
                                                                                                   right: 0)))
        layout?.setMessageIncomingAvatarPosition(AvatarPosition(vertical: .messageTop))
        layout?.setMessageIncomingAccessoryViewSize(.zero)
        layout?.setMessageOutgoingAccessoryViewSize(.zero)
        layout?.setMessageIncomingAccessoryViewPadding(.zero)
        layout?.setMessageOutgoingAccessoryViewPadding(.zero)
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))

        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
    }

    @objc(closeChat)
    private func closeChat() {
        NotificationCenter.default.post(name: Notification.Name("ChatClose"), object: nil)
    }

    private func configureNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarView)
        navigationItem.titleView = titleView
        let backBtn = UIBarButtonItem()
        var scale: CGFloat = 0.5
        var image: UIImage = UIImage.scale(image: UIImage(asset: .back)!, by: scale)!
        backBtn.image = image
        // backBtn.tintColor = UIColor.Theme.white  // temporary disable dark theme
        backBtn.tintColor = UIColor(hex: 0x6D3AF7, alpha: 1)
        backBtn.action = #selector(closeChat)
        backBtn.target = self
        navigationItem.leftBarButtonItem = backBtn
    }

    private func configureInputBar() {
        messageInputBarView.delegate = self

        messageInputBarView.onAttachmentButtonTapped = { [weak self] in
            self?.sendAttachment()
        }
    }

    // MARK: - Send attachment

    private func sendAttachment() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if #available(iOS 13.0, *) {  // temporary disable dark theme
            alertController.overrideUserInterfaceStyle = .light
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        let cancel = UIAlertAction(title: "Отменить", style: .cancel)
        let library = UIAlertAction(title: "Фото", style: .default) { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }
        library.setValue(UIImage(asset: .photo), forKey: "image")
        let camera = UIAlertAction(title: "Камера", style: .default) { _ in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }
        camera.setValue(UIImage(asset: .camera), forKey: "image")
        let documents = UIAlertAction(title: "Документ", style: .default) { _ in
            let documentPickerController = UIDocumentPickerViewController(documentTypes: [], in: .open)
            documentPickerController.delegate = self
            documentPickerController.allowsMultipleSelection = false
            self.present(documentPickerController, animated: true)
        }
        documents.setValue(UIImage(asset: .document), forKey: "image")
        alertController.addActions(camera, library, documents, cancel)
        alertController.view.tintColor = .black
        present(alertController, animated: true)
    }

    // MARK: - Send message

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        messageInputBarView.inputTextView.text = ""
        messageInputBarView.invalidatePlugins()
        messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let followMessage = viewModel.followMessage {
            viewModel.followMessage = nil
            viewModel.sendEvent(ClientEvent(.text("> \(followMessage)\n\(trimmedText)")))
        } else {
            viewModel.sendEvent(ClientEvent(.text(trimmedText)))
        }
    }

    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        guard !text.isEmpty else {
            return
        }

        messagesCollectionView.scrollToBottom()
        NotificationCenter.default.post(name: Notification.Name("ChatDrain"), object: nil)
        viewModel.sendEvent(ClientEvent(.typing(text)))
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }

        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        switch message.kind {
        case .text:
            let cell = messagesCollectionView.dequeueReusableCell(TextMessageCollectionViewCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            if #available(iOS 13.0, *) {
                cell.messageContainerView.isUserInteractionEnabled = true
                cell.messageContainerView.addInteraction(UIContextMenuInteraction(delegate: self))
            }
            return cell
        case let .custom(value):
            guard let type = value as? CustomType else {
                return super.collectionView(collectionView, cellForItemAt: indexPath)
            }

            switch type {
            case .system:
                let cell = messagesCollectionView.dequeueReusableCell(SystemMessageCollectionViewCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            case .follow:
                let cell = messagesCollectionView.dequeueReusableCell(FollowTextMessageCollectionViewCell.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
        default:
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }

    // MARK: - UIScrollViewDelegate

    override func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {
        if indexPath.section == 0, viewModel.isContentLoaded, !viewModel.isLoadingMore {
            viewModel.loadMoreMessagesIfNeeded()
        }
    }

}

extension ChatViewController: MessagesDataSource {

    func currentSender() -> SenderType {
        return viewModel.user
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard viewModel.isPreviousMessageSameDate(at: indexPath.section) else {
            return NSAttributedString(string: DateFormatter.relativeDate.string(from: message.sentDate),
                                      attributes: [.font: UIFont.boldSystemFont(ofSize: 10),
                                                   .foregroundColor: UIColor.darkGray])
        }

        return nil
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName,
                                  attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}

extension ChatViewController: UIContextMenuInteractionDelegate {

    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let point = interaction.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: point),
              case let .text(value) = viewModel.messages[indexPath.section].kind else {
            return nil
        }

        let message = viewModel.messages[indexPath.section]
        let testView = FollowMessageView(name: message.sender.displayName, text: value)
        viewModel.followMessage = value
        testView.onCancelAction = { [weak self] in
            self?.viewModel.followMessage = nil
            self?.messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }

        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { action in
            let answer = UIAction(title: "Ответить", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
                self.messageInputBarView.topStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.messageInputBarView.topStackView.addArrangedSubview(testView)
            }

            let copy = UIAction(title: "Скопировать", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = value
            }

            return UIMenu(title: "", children: [answer, copy])
        }

        return configuration
    }

}

extension ChatViewController: MessageCellDelegate {

    func didSelectURL(_ url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true)
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              case let .photo(item) = viewModel.messages[indexPath.section].kind, let url = item.url,
              let imageSource = BFRBackLoadedImageSource(initialImage: item.placeholderImage, hiResURL: url),
              let viewController = BFRImageViewController(imageSource: [imageSource]) else {
            return
        }

        present(viewController, animated: true)
    }

}

extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        switch message.kind {
        case .photo:
            return .messageGray
        default:
            return isFromCurrentSender(message: message) ? .messageBlue : .messageGray
        }
    }

    func enabledDetectors(for message: MessageType,
                          at indexPath: IndexPath,
                          in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url]
    }

    func textColor(for message: MessageType,
                   at indexPath: IndexPath,
                   in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return .darkText
        // return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType,
                            and message: MessageType,
                            at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        return [.foregroundColor: UIColor.black,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: UIColor.black]
        // return [.foregroundColor: isFromCurrentSender(message: message) ? UIColor.white : UIColor.black,
         //       .underlineStyle: NSUnderlineStyle.single.rawValue,
         //       .underlineColor: isFromCurrentSender(message: message) ? UIColor.white : UIColor.black]
    }

    func messageStyle(for message: MessageType,
                      at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .bubble
    }

    func configureMediaMessageImageView(_ imageView: UIImageView,
                                        for message: MessageType,
                                        at indexPath: IndexPath,
                                        in messagesCollectionView: MessagesCollectionView) {
        guard case let .photo(item) = message.kind, let imageURL = item.url else {
            return
        }

        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: .network(ImageResource(downloadURL: imageURL)))
    }

    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        let placeholderImage = UIImage(asset: .account)
        guard let chatMessage = message as? ChatViewModel.ChatMessage,
              let urlString = chatMessage.creator.employee?.avatarUrl,
              let resourceURL = URL(string: urlString) else {
            avatarView.backgroundColor = .clear
            avatarView.set(avatar: Avatar(image: placeholderImage))
            return
        }

        avatarView.kf.setImage(with: ImageResource(downloadURL: resourceURL), placeholder: placeholderImage)
    }

}

extension ChatViewController: MessagesLayoutDelegate {

    func cellTopLabelHeight(for message: MessageType,
                            at indexPath: IndexPath,
                            in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return viewModel.isPreviousMessageSameDate(at: indexPath.section) ? 0 : 24
    }

    func messageTopLabelHeight(for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isFromCurrentSender(message: message) ? 0 : 20
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.5) else {
            picker.dismiss(animated: true)
            return
        }

        viewModel.sessionService?.upload(data: data, fileName: "image.png", mimeType: "image/jpeg") { [weak self] result in
            switch result {
            case let .success(attachment):
                self?.viewModel.sendEvent(ClientEvent(.file(attachment)))
            case let .failure(error):
                print(error.localizedDescription)
            }
        }

        picker.dismiss(animated: true)
    }

}

extension ChatViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let data = try? Data(contentsOf: url) else {
            return
        }

        
    }

}