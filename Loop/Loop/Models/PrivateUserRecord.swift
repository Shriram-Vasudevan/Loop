//
//  PrivateUserRecord.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation
import CloudKit

struct UserRecord {
    var userID: String
    var name: String
    var username: String
    var phone: String
    
    static func from(record: CKRecord) -> UserRecord? {
        guard let userID = record["UserID"] as? String,
              let username = record["Username"] as? String,
              let name = record["Name"] as? String,
              let phone = record["Phone"] as? String else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        return UserRecord(userID: userID, name: name, username: username, phone: phone)
    }
}
