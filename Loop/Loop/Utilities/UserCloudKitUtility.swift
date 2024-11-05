//
//  UserCloudKitUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 9/29/24.
//

import Foundation
import CloudKit
import Contacts

class UserCloudKitUtility {
    static let container = CloudKit.CKContainer(identifier: "iCloud.LoopContainer")
    
    static var userData: UserRecord?
    
    static func addUserData() {
        let privateDB = container.privateCloudDatabase
        
        let userRecord = CKRecord(recordType: "UserRecord")
    }
    
    static func getCurrentUserData() {
        let privateDB = container.privateCloudDatabase
        
        let query = CKQuery(recordType: "UserRecord", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        
        var selectedUserRecord: UserRecord?
        queryOperation.recordFetchedBlock = { record in
            if let userRecord = UserRecord.from(record: record) {
                self.userData = userRecord
            }
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("Error fetching LoopRevealDate: \(error.localizedDescription)")
            }
        }
        
        privateDB.add(queryOperation)
        
    }
    
    static func getPublicUserData(userID: String) -> PublicUserRecord? {
        let publicDB = container.publicCloudDatabase
        guard let userID = self.userData?.userID else { return nil }
        
        let query = CKQuery(recordType: "PublicUserRecord", predicate: NSPredicate(format: "UserID == %@", argumentArray: [userID]))
        let queryOperation = CKQueryOperation(query: query)
        
        var userRecord: PublicUserRecord?
        
        queryOperation.recordFetchedBlock = { record in
            if let uRecord = record as? PublicUserRecord { //change obv
                userRecord = uRecord
            }
        }
        
        queryOperation.queryCompletionBlock = { _, error in
            if let error = error {
                print("An error with getting recievd loops occured: \(error)")
            }
        }
        
        publicDB.add(queryOperation)
        
        return userRecord
    }
    
    static func createUser(username: String, phoneNumber: String, name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRecord = CKRecord(recordType: "UserRecord")
        userRecord["UserID"] = UUID().uuidString as CKRecordValue
        userRecord["Name"] = name as CKRecordValue
        userRecord["Username"] = username as CKRecordValue
        userRecord["Phone"] = phoneNumber as CKRecordValue
        
        let publicUserRecord = CKRecord(recordType: "PublicUserRecord")
        publicUserRecord["UserID"] = UUID().uuidString as CKRecordValue
        publicUserRecord["Name"] = name as CKRecordValue
        publicUserRecord["Username"] = username as CKRecordValue
        publicUserRecord["Phone"] = phoneNumber as CKRecordValue
        publicUserRecord["Friends"] = [] as CKRecordValue
        
        let container = CKContainer.default()
        
        container.privateCloudDatabase.save(userRecord) { privateRecord, privateError in
            if let privateError = privateError {
                completion(.failure(privateError))
                return
            }
            
            container.publicCloudDatabase.save(publicUserRecord) { publicRecord, publicError in
                if let publicError = publicError {
                    completion(.failure(publicError))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    static func findMatchingContactsInCloudKit(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let publicDatabase = container.publicCloudDatabase
        let contactNumbers = prepareContactPhoneNumbers()
        
        let batchSize = 10
        var allMatchedRecords = [CKRecord]()
        var batchesCompleted = 0
        let batchCount = Int(ceil(Double(contactNumbers.count) / Double(batchSize)))
        var batchErrors = [Error]()

        for batchStart in stride(from: 0, to: contactNumbers.count, by: batchSize) {
            let batchNumbers = Array(contactNumbers[batchStart..<min(batchStart + batchSize, contactNumbers.count)])
            let predicates = batchNumbers.map { NSPredicate(format: "Phone == %@", $0) }
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            
            let query = CKQuery(recordType: "PublicUserRecord", predicate: compoundPredicate)
            
            publicDatabase.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    batchErrors.append(error)
                } else if let records = records {
                    allMatchedRecords.append(contentsOf: records)
                }
                
                batchesCompleted += 1
                if batchesCompleted == batchCount {
                    if batchErrors.isEmpty {
                        completion(.success(allMatchedRecords))
                    } else {
                        completion(.failure(batchErrors.first!))
                    }
                }
            }
        }
    }
    
    private static func prepareContactPhoneNumbers() -> [String] {
        let contactStore = CNContactStore()
        var formattedNumbers = [String]()

        let keysToFetch = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        do {
            try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                for phoneNumber in contact.phoneNumbers {
                    let strippedNumber = stripPhoneNumber(phoneNumber.value.stringValue)
                    formattedNumbers.append(strippedNumber)
                }
            }
        } catch {
            print("Error accessing contacts: \(error.localizedDescription)")
        }
        return formattedNumbers
    }

    private static func stripPhoneNumber(_ number: String) -> String {
        return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }


    // UserCloudKitUtility.swift
    static func sendLoopToOtherUser(recipientID: String, data: CKAsset, prompt: String, timestamp: Date, availableAt: Date, anonymous: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let publicDatabase = container.publicCloudDatabase
        
        guard let senderID = self.userData?.userID else {
            completion(.failure(NSError(domain: "UserCloudKitUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "User data is missing."])))
            return
        }
        
        let record = CKRecord(recordType: "SharedLoop")
        record["ID"] = UUID().uuidString as CKRecordValue
        record["Data"] = data
        record["Prompt"] = prompt as CKRecordValue
        record["SenderID"] = senderID as CKRecordValue
        record["RecipientID"] = recipientID as CKRecordValue
        record["AvailableAt"] = availableAt as CKRecordValue
        record["Anonymous"] = anonymous as CKRecordValue
        record["Timestamp"] = timestamp as CKRecordValue
        
        publicDatabase.save(record) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    
    static func getRecievedLoops() -> [SharedLoop]? {
        let publicDatabase = container.publicCloudDatabase
        guard let userID = self.userData?.userID else { return nil }
        
        let query = CKQuery(recordType: "SharedLoop", predicate: NSPredicate(format: "RecipientID == %@", argumentArray: [userID]))
        let queryOperation = CKQueryOperation(query: query)
        
        var loops: [SharedLoop] = []
        
        queryOperation.recordFetchedBlock = { record in
            if let loop = record as? SharedLoop { //change obv
                loops.append(loop)
            }
        }
        
        queryOperation.queryCompletionBlock = { _, error in
            if let error = error {
                print("An error with getting recievd loops occured: \(error)")
            }
        }
        
        publicDatabase.add(queryOperation)

        return loops
    }
    
    static func makeFriendRequest(to userID: String, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        guard let senderID = self.userData?.userID else {
            completion(.failure(NSError(domain: "FriendRequestError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
            return
        }
        
        let record = CKRecord(recordType: "FriendRequest")
        record["ID"] = UUID().uuidString as CKRecordValue
        record["SenderID"] = senderID as CKRecordValue
        record["RecipientID"] = userID as CKRecordValue
        
        let publicDB = container.publicCloudDatabase
        publicDB.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else if let savedRecord = savedRecord {
                    completion(.success(savedRecord))
                }
            }
        }
    }

    
}
