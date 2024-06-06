//
//  DatabaseManager.swift
//  Messanger
//
//  Created by apple on 2024/6/4.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress:String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
}

//MARK: - account management

extension DatabaseManager {
    
    public func userExists(with email:String,
                           completion:@escaping (Bool) -> Void){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    /// inserts new user to database
    public func insertUser(with user:ChatAppUser, completion:@escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "fisrt_name":user.firstName,
            "last_name":user.lastName
        ]) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var userCollections = snapshot.value as? [[String:String]] {
                    /// append user dictionary
                    let newElement =  ["name":user.firstName+" "+user.lastName,
                                       "email":user.safeEmail
                                      ]
                    userCollections.append(newElement)
                    
                    self.database.child("users").setValue(userCollections) { error,_ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }else{
                    /// create that array
                    let newCollection:[[String:String]] = [
                        ["name":user.firstName+" "+user.lastName,
                         "email":user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { error,_ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                    
            }
//            completion(true)
        }
    }
    
    
    public func getAllUsers(completion:@escaping (Result<[[String:String]],Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError:Error {
        case failedToFetch
    }
    
}


//MARK: - sending messages / conversations

extension DatabaseManager {
    
    /// create a new conversation with first message sent
    public func createNewConversation(with otherEmail:String,
                                      name:String,
                                      firstMessage:Message,
                                      completion:@escaping (Bool) -> Void) {
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                return
            }
            
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateformatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
               case .text(let messageText):
                   message = messageText
                   break
               case .attributedText(_):
                   break
               case .photo(_):
                   break
               case .video(_):
                   break
               case .location(_):
                   break
               case .emoji(_):
                   break
               case .audio(_):
                   break
               case .contact(_):
                   break
               case .linkPreview(_):
                   break
               case .custom(_):
                   break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversationData:[String:Any] = [
                "id":conversationID,
                "name":name,
                "other_user_email":otherEmail,
                "latest_message":[
                    "date":dateString,
                    "message":message,
                    "is_read":false
                ]
            ]
            
            let recipient_newConversationData:[String:Any] = [
                "id":conversationID,
                "name":"Self",
                "other_user_email":safeEmail,
                "latest_message":[
                    "date":dateString,
                    "message":message,
                    "is_read":false
                ]
            ]
            
            // update recipient converstaion
            self?.database.child("\(otherEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self]snapshot in
                
                if var conversations = snapshot.value as? [[String:Any]] {
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherEmail)/conversations").setValue(conversations)
                    
                }else {
                    self?.database.child("\(otherEmail)/conversations").setValue([recipient_newConversationData])
                }
                
            })
            
            
            
            // update current user conversation
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverstaion(name:name,
                                                    conversationID: conversationID,
                                                    firstMessage: firstMessage,
                                                    compeltion: completion)
                }
                
            }else {
                // create conversation
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverstaion(name:name,
                                                    conversationID: conversationID,
                                                    firstMessage: firstMessage,
                                                    compeltion: completion)
                }
                
            }
            
        }
        
        
    }
    
    
    private func finishCreatingConverstaion(name:String,
                                            conversationID:String,
                                            firstMessage:Message,
                                            compeltion:@escaping (Bool) -> Void) {
        
        var message = ""
        switch firstMessage.kind {
           case .text(let messageText):
               message = messageText
               break
           case .attributedText(_):
               break
           case .photo(_):
               break
           case .video(_):
               break
           case .location(_):
               break
           case .emoji(_):
               break
           case .audio(_):
               break
           case .contact(_):
               break
           case .linkPreview(_):
               break
           case .custom(_):
               break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateformatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            compeltion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage:[String:Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content":message,
            "date":dateString,
            "sender_email":currentUserEmail,
            "is_read":false,
            "name":name
        ]
        
        let value:[String:Any] = [
            "messages":[
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                compeltion(false)
                return
            }
            
            compeltion(true)
        }
        
    }
    
    /// fetch and return all conversation for the user passed the email
    public func getAllConversations(for email:String, completions:@escaping (Result<[Conversation],Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completions(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations:[Conversation] = value.compactMap({dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
                
                
            })
            
            completions(.success(conversations))
            
        }
        
    }
    
    /// gets all messsages from a given converstaion
    public func getAllMessagesForConverstaion(with id:String,completion:@escaping (Result<[Message],Error>) -> Void){
        database.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages:[Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateformatter.date(from:dateString) else {
                    return nil
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
                
            })
    
            completion(.success(messages))
            
        }
        
    }
    
    /// sends a message with taget
    public func sendMessage(to converstaion:String,message:Message,completion:@escaping (Bool) -> Void){
        
    }
    
}


struct ChatAppUser{
    let firstName:String
    let lastName:String
    let emailAddress:String
    
    var safeEmail:String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    
    var profilePictureFileName:String {
        return "\(safeEmail)_profile_picture.png"
    }
}

