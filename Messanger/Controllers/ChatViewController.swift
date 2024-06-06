//
//  ChatViewController.swift
//  Messanger
//
//  Created by apple on 2024/6/5.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message:MessageType {
  public var sender: SenderType
  public var messageId: String
  public var sentDate: Date
  public var kind: MessageKind
}

extension MessageKind {
    var messageKindString:String {
        switch self {
            
        case .text(_):
            return "text"
            
        case .attributedText(_):
            return "attributedText"
            
        case .photo(_):
            return "photo"

        case .video(_):
            return "video"

        case .location(_):
            return "location"

        case .emoji(_):
            return "emoji"

        case .audio(_):
            return "audio"

        case .contact(_):
            return "contact"

        case .linkPreview(_):
            return "linkPreview"

        case .custom(_):
            return "custom"

        }
    }
}

struct Sender:SenderType {
    public var photoURL:String
    public var senderId: String
    public var displayName: String
}


class ChatViewController: MessagesViewController {
    
    public static let dateformatter:DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    private var convsersationId:String?
    public var otherUserEmail:String

    private var messages = [Message]()
    private var selfSender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: "Me")
        
    }
    
    init(with email:String, id:String?){
        self.convsersationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messageInputBar.delegate = self
    }
    
    private func listenForMessages(id:String,shouldScrollToBottom:Bool) {
        DatabaseManager.shared.getAllMessagesForConverstaion(with: id) {[weak self] result in
            switch result {
                case .success(let messages):
                    guard !messages.isEmpty else {
                        return
                    }
                    self?.messages = messages
                    DispatchQueue.main.async {
                        self?.messagesCollectionView.reloadDataAndKeepOffset()
                        if shouldScrollToBottom {
                            self?.messagesCollectionView.scrollToLastItem()
                        }
                    }
                
                case .failure(let error):
                    print("failed to get message \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let convsersationId = convsersationId {
            listenForMessages(id:convsersationId,shouldScrollToBottom:true)
        }
    }

}

extension ChatViewController:InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        
        let message  = Message(sender: selfSender,
                               messageId: messageId,
                               sentDate: Date(),
                               kind: .text(text))
        /// send message
        
        if convsersationId == nil {
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name: self.title ?? "user",
                                                         firstMessage: message) {[weak self] success,convId in
                if success {
                    guard let convId = convId else { return }
                    self?.convsersationId = convId
                    print("success \(convId)")
                }else {
                    print("fail")

                }
            }
            
        } else {
            
            guard let convsersationId = convsersationId, let name = self.title else {
                return
            }

            DatabaseManager.shared.sendMessage(to: convsersationId, name: name,newMessage: message) { success in
                if success {
                    print("success sent")

                }else {
                    print("fail to sent")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        // date, otheruser email, sender email
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
              return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateformatter.string(from:Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created messageid:\(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("self sender is nil")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    
}
