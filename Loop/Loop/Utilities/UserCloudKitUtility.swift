//
//  UserCloudKitUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 9/29/24.
//

import Foundation
import CloudKit

class UserCloudKitUtility {
    static let container = CloudKit.CKContainer(identifier: "iCloud.LoopContainer")
    
    static func addUserData() {
        let privateDB = container.privateCloudDatabase
        
        let userRecord = CKRecord(recordType: "UserRecord")
    }
    
    static func createUser(username: String, phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRecord = CKRecord(recordType: "UserRecord")
        userRecord["UserID"] = UUID().uuidString as CKRecordValue
        userRecord["Username"] = username as CKRecordValue
        userRecord["Phone"] = phoneNumber as CKRecordValue

        container.privateCloudDatabase.save(userRecord) { record, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
