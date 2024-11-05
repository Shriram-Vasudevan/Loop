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
    
    static var userID: String?
    
    static func addUserData() {
        let privateDB = container.privateCloudDatabase
        
        let userRecord = CKRecord(recordType: "UserRecord")
    }
    
    static func getUserData() {
        let privateDB = container.privateCloudDatabase
        
        let query = CKQuery(recordType: "UserRecord", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        
        //        var selectedUserRecord: UserRecord?
        //        queryOperation.recordFetchedBlock = { record in
        //            if let userRecord = UserRec.from(record: record) {
        //
        //            }
        //        }
        
//        queryOperation.queryCompletionBlock = { _, error in
//
//        }
//
        privateDB.add(queryOperation)
        
    }
    
    static func createUser(username: String, phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRecord = CKRecord(recordType: "UserRecord")
        userRecord["UserID"] = UUID().uuidString as CKRecordValue
        userRecord["Username"] = username as CKRecordValue
        userRecord["Phone"] = phoneNumber as CKRecordValue
        
        let container = CKContainer.default()
        
        container.privateCloudDatabase.save(userRecord) { privateRecord, privateError in
            if let privateError = privateError {
                completion(.failure(privateError))
                return
            }
            
            container.publicCloudDatabase.save(userRecord) { publicRecord, publicError in
                if let publicError = publicError {
                    completion(.failure(publicError))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    static func findMatchingContactsInCloudKit(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let contactStore = CNContactStore()
        
        contactStore.requestAccess(for: .contacts) { granted, error in
            guard granted, error == nil else {
                completion(.failure(error ?? NSError(domain: "Contacts Access Denied", code: 1, userInfo: nil)))
                return
            }

            let keysToFetch = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            var contactPhoneNumbers = Set<String>()
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            do {
                try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                    for phoneNumber in contact.phoneNumbers {
                        let strippedNumber = stripPhoneNumber(phoneNumber.value.stringValue)
                        contactPhoneNumbers.insert(strippedNumber)
                    }
                }
                
                fetchCloudKitUserRecords { result in
                    switch result {
                    case .success(let records):
                        let matchedRecords = records.filter { record in
                            if let phone = record["Phone"] as? String {
                                let strippedPhone = stripPhoneNumber(phone)
                                return contactPhoneNumbers.contains(strippedPhone)
                            }
                            return false
                        }
                        completion(.success(matchedRecords))
                        
                    case .failure(let fetchError):
                        completion(.failure(fetchError))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func fetchCloudKitUserRecords(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let publicDatabase = container.publicCloudDatabase
        let query = CKQuery(recordType: "UserRecord", predicate: NSPredicate(value: true))
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(records ?? []))
            }
        }
    }
    
    private static func stripPhoneNumber(_ number: String) -> String {
        return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    static func sendLoopToOtherUser(recipientID: String, loop: Loop, availableAt: Date, anonymous: Bool) {
        let publicDatabase = container.publicCloudDatabase
        
        guard let userID = self.userID else { return }
        let record = CKRecord(recordType: "SharedLoop")
        record["ID"] = loop.id as CKRecordValue
        record["Data"] = loop.data
        record["Prompt"] = loop.promptText as CKRecordValue
        record["SenderID"] = userID as CKRecordValue
        record["RecipientID"] = recipientID as CKRecordValue
        record["AvailableAt"] = availableAt as CKRecordValue
        record["Anonymous"] = anonymous as CKRecordValue
        
        publicDatabase.save(record) { record, error in
            //handle error
        }
    }
    
    static func getRecievedLoops() {
        let publicDatabase = container.publicCloudDatabase
        guard let userID = self.userID else { return }
        
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

        //return loops idk
    }
    
}
