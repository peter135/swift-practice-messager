//
//  StorageManager.swift
//  Messanger
//
//  Created by apple on 2024/6/5.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    /// /images/araz-gmail-com_profile_picture.png
    ///  upload pic to firebase storage with url
    
    public typealias uloadPictureCompletion = (Result<String,Error>) -> Void
    
    public func uploadProfilePicure(with data:Data,
                                    fileName:String,
                                    completion:@escaping uloadPictureCompletion){
        storage.child("images/\(fileName)").putData(data,metadata: nil) { metadata, error in
            guard error == nil else {
                completion(.failure(StorageErros.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    completion(.failure(StorageErros.failedToGetDownloadUrl))
                    return
                    
                }
                let urlString = url.absoluteString
                print("download url return \(urlString)")
                completion(.success(urlString))
            }
        }
        
    }
    
    public enum StorageErros: Error {
       case failedToUpload
       case failedToGetDownloadUrl
    }
    
    
    public func downloadURL(for path:String, completion:@escaping (Result<URL,Error>)->Void) {
        let reference = storage.child(path)
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErros.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
    }
    
}

