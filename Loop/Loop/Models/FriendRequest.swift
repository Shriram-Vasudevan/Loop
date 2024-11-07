//
//  FriendRequest.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation
import CloudKit

struct FriendRequest: Hashable {
    var id: String
    var senderID: String
    var recipientID: String
    var isAccepted: Bool
    
    static func from(record: CKRecord) -> FriendRequest? {
        guard let id = record["ID"] as? String,
              let senderID = record["SenderID"] as? String,
              let recipientID = record["RecipientID"] as? String,
              let isAccepted = record["IsAccepted"] as? Bool else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        return FriendRequest(id: id, senderID: senderID, recipientID: recipientID, isAccepted: isAccepted)
    }
}
