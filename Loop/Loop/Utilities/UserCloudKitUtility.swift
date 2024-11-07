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
    
    static func getCurrentUserData() async throws -> PublicUserRecord? {
        let privateDB = container.privateCloudDatabase
        
        let query = CKQuery(recordType: "UserRecord", predicate: NSPredicate(value: true))
        
        do {
            let (matchingRecords, _) = try await privateDB.records(matching: query, resultsLimit: 1)
            
            guard let record = matchingRecords.first?.1,
                  let userRecord = UserRecord.from(record: try record.get()) else {
                print("No private user record found")
                return nil
            }
            
            // Then query public database
            let publicDB = container.publicCloudDatabase
            let publicQuery = CKQuery(
                recordType: "PublicUserRecord",
                predicate: NSPredicate(format: "UserID == %@", argumentArray: [userRecord.userID])
            )
            
            let (publicRecords, _) = try await publicDB.records(matching: publicQuery, resultsLimit: 1)
            
            guard let publicRecord = publicRecords.first?.1,
                  let publicUserRecord = PublicUserRecord.from(record: try publicRecord.get()) else {
                print("No public user record found")
                return nil
            }
            
            return publicUserRecord
        } catch {
            print("Error fetching records: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func getPublicUserData(userID: String) -> PublicUserRecord? {
        let publicDB = container.publicCloudDatabase
        guard let userID = self.userData?.userID else { return nil }
        
        let query = CKQuery(recordType: "PublicUserRecord", predicate: NSPredicate(format: "UserID == %@", argumentArray: [userID]))
        let queryOperation = CKQueryOperation(query: query)
        
        var userRecord: PublicUserRecord?
        
        queryOperation.recordFetchedBlock = { record in
            if let uRecord = record as? PublicUserRecord { 
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
        let userID = UUID().uuidString

        let userRecord = CKRecord(recordType: "UserRecord")
        userRecord["UserID"] = userID
        userRecord["Name"] = name
        userRecord["Username"] = username
        userRecord["Phone"] = phoneNumber
        
        let publicUserRecord = CKRecord(recordType: "PublicUserRecord")
        publicUserRecord["UserID"] = userID
        publicUserRecord["Name"] = name
        publicUserRecord["Username"] = username
        publicUserRecord["Phone"] = phoneNumber
        publicUserRecord["Friends"] = [] as CKRecordValue
                
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

    static func findMatchingContactsInCloudKit(completion: @escaping (Result<[CKRecord], Error>) -> Void) async {
            print("Starting findMatchingContactsInCloudKit function")
            
            DispatchQueue.global(qos: .userInitiated).async {
                let contactStore = CNContactStore()
                
                contactStore.requestAccess(for: .contacts) { granted, error in
                    if let error = error {
                        print("Error requesting contact access: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            completion(.failure(UserCloudKitError.contactAccessDenied))
                        }
                        return
                    }
                    
                    guard granted else {
                        print("Access to contacts denied by user.")
                        DispatchQueue.main.async {
                            completion(.failure(UserCloudKitError.contactAccessDenied))
                        }
                        return
                    }
                    
                    print("Access to contacts granted.")
                    
                    do {
                        let contactNumbers = try fetchContactPhoneNumbers()
                        print("Fetched contact numbers: \(contactNumbers)")
                        Task {
                            try await processBatches(contactNumbers: contactNumbers)
                        }
                    } catch {
                        print("Error fetching contact phone numbers: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
        
    static func findMatchingContactsInCloudKit() async throws -> [CKRecord] {
            print("Starting findMatchingContactsInCloudKit function")
            
            let contactStore = CNContactStore()
            let granted = try await contactStore.requestAccess(for: .contacts)
            
            guard granted else {
                print("Access to contacts denied by user.")
                throw UserCloudKitError.contactAccessDenied
            }
            
            print("Access to contacts granted.")
            
            let contactNumbers = try fetchContactPhoneNumbers()
            print("Fetched contact numbers: \(contactNumbers)")
            
            return try await processBatches(contactNumbers: contactNumbers)
        }
        
        private static func fetchContactPhoneNumbers() throws -> [String] {
            print("Starting fetchContactPhoneNumbers function")
            
            let contactStore = CNContactStore()
            var phoneNumbers = [String]()
            
            let keysToFetch = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                for phoneNumber in contact.phoneNumbers {
                    let strippedNumber = stripPhoneNumber(phoneNumber.value.stringValue)
                    print("Original phone number: \(phoneNumber.value.stringValue), Stripped: \(strippedNumber)")
                    phoneNumbers.append(strippedNumber)
                }
            }
            
            print("Total formatted phone numbers fetched: \(phoneNumbers.count)")
            return phoneNumbers
        }
        
        private static func processBatches(contactNumbers: [String]) async throws -> [CKRecord] {
            print("Starting processBatches with contactNumbers: \(contactNumbers)")
            
            let batchSize = 75
            let batches = stride(from: 0, to: contactNumbers.count, by: batchSize).map {
                Array(contactNumbers[$0..<min($0 + batchSize, contactNumbers.count)])
            }
            
            var allMatchedRecords = [CKRecord]()
            
            for (index, batch) in batches.enumerated() {
                print("Processing batch \(index + 1) of \(batches.count) with \(batch.count) contact numbers")
                let records = try await performBatchQuery(contactNumbers: batch)
                allMatchedRecords.append(contentsOf: records)
            }
            
            print("All batches completed successfully. Total matched records: \(allMatchedRecords.count)")
            return allMatchedRecords
        }
        
    private static func stripPhoneNumber(_ number: String) -> String {
        print("Stripping phone number: \(number)")
        
        let stripped = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if stripped.hasPrefix("1") && stripped.count == 11 {
            print("US number with country code 1, removing prefix.")
            return String(stripped.dropFirst())
        } else if stripped.count == 10 {
            print("Valid 10-digit number.")
            return stripped
        }
        
        print("Unusual phone number format detected: \(stripped) (original: \(number))")
        return stripped
    }
    
        private static func performBatchQuery(contactNumbers: [String]) async throws -> [CKRecord] {
            print("Performing batch query for contact numbers: \(contactNumbers)")
            
            let publicDatabase = container.publicCloudDatabase
            var matchedRecords = [CKRecord]()
            
            try await withThrowingTaskGroup(of: [CKRecord].self) { group in
                // Process up to 5 queries concurrently to avoid overwhelming CloudKit
                let batchSize = 5
                for batch in stride(from: 0, to: contactNumbers.count, by: batchSize) {
                    let end = min(batch + batchSize, contactNumbers.count)
                    let currentBatch = Array(contactNumbers[batch..<end])
                    
                    for number in currentBatch {
                        group.addTask {
                            let query = CKQuery(
                                recordType: "PublicUserRecord",
                                predicate: NSPredicate(format: "Phone == %@", number)
                            )
                            
                            let (records, _) = try await publicDatabase.records(matching: query, resultsLimit: 1)
                            
                            if let record = try records.first?.1.get() {
                                if let recordPhone = record["Phone"] as? String {
                                    print("✅ Found match for phone: \(recordPhone)")
                                }
                                return [record]
                            } else {
                                print("❌ No match found for phone: \(number)")
                                return []
                            }
                        }
                    }
                    
                    // Collect results from this batch
                    for try await batchResults in group {
                        matchedRecords.append(contentsOf: batchResults)
                    }
                }
            }
            
            print("✨ Batch query completed. Total matched records: \(matchedRecords.count)")
            return matchedRecords
        }

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
    
    static func getFriendRequests() async -> [FriendRequest] {
        guard let userID = self.userData?.userID else {
            return []
        }
        
        let publicDB = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "FriendRequest", predicate: NSPredicate(format: "RecipientID == %@", argumentArray: [userID]))
        
        var friendRequests: [FriendRequest] = []
        do {
            let (publicRecords, _) = try await publicDB.records(matching: query)
            friendRequests = publicRecords.compactMap { id, result in
                if let record = try? result.get() {
                    return FriendRequest.from(record: record)
                } else {
                    return nil
                }
            }
        } catch {
            return friendRequests
        }
        
        return friendRequests
    }
}

enum UserCloudKitError: Error {
    case contactAccessDenied
    case contactFetchError(Error)
    case cloudKitError(Error)
    case batchProcessingError([Error])
}
