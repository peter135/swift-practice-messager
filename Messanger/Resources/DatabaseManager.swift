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
    
   
}

//MARK: - account management

extension DatabaseManager {
    
    public func userExists(with email:String,
                           completion:@escaping ((Bool)->Void)){
        
        database.child(email).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    /// inserts new user to database
    public func insertUser(with user:ChatAppUser) {
        database.child(user.emailAddress).setValue([
            "fisrt_name":user.firstName,
            "last_name":user.lastName
        ])
    }
    
}

struct ChatAppUser{
    let firstName:String
    let lastName:String
    let emailAddress:String
//    let profilePictureUlr:String
    
}

