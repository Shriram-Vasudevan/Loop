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
}
