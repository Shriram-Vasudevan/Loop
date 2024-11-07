//
//  FriendRequest.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation
import CloudKit

struct FriendRequest {
    var id: String
    var senderID: String
    var recipientID: String
    
    static func from(record: CKRecord) -> FriendRequest? {
        guard let id = record["ID"] as? String,
              let senderID = record["SenderID"] as? String,
              let recipientID = record["recipientID"] as? String else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        return FriendRequest(id: id, senderID: senderID, recipientID: recipientID)
    }
}
