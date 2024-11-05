//
//  PublicUserRecord.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation
import CloudKit

struct PublicUserRecord {
    var userID: String
    var username: String
    var phone: String
    var name: String
    var friends: [String]
    
    static func from(record: CKRecord) -> PublicUserRecord? {
        guard let userID = record["UserID"] as? String,
              let username = record["Username"] as? String,
              let name = record["Name"] as? String,
              let friends = record["Friends"]  as? [String],
              let phone = record["Phone"] as? String else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        return PublicUserRecord(userID: userID, username: username, phone: phone, name: name, friends: friends)
    }
}
