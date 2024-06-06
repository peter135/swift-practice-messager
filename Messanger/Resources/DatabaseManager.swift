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
    
    /// create a new converstaion with first message sent
    public func createNewConversation(with otherEmail:String,
                                      firstMessage:Message,
                                      completion:@escaping (Bool) -> Void) {
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { snapshot in
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
                "other_user_email":otherEmail,
                "latest_message":[
                    "date":dateString,
                    "message":message,
                    "is_read":false
                ]
            ]
            
            
            if var converstaions = userNode["conversations"] as? [[String:Any]] {
                converstaions.append(newConversationData)
                userNode["converstaions"] = converstaions
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverstaion(conversationID: conversationID,
                                                    firstMessage: firstMessage,
                                                    compeltion: completion)
                }
                
            }else {
                // create conversation
                userNode["converstaions"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConverstaion(conversationID: conversationID,
                                                    firstMessage: firstMessage,
                                                    compeltion: completion)
                }
                
            }
            
        }
        
        
    }
    
    
    private func finishCreatingConverstaion(conversationID:String, firstMessage:Message, compeltion:@escaping (Bool) -> Void) {
        
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
            "is_read":false

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
    public func getAllConversations(for email:String, completions:@escaping (Result<String,Error>) -> Void) {
        
    }
    
    /// gets all messsages from a given converstaion
    public func getAllMessagesForConverstaion(with id:String,completion:@escaping (Result<String,Error>) -> Void){
        
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

