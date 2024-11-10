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
            
            self.userData = userRecord
            
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
    
    
    static func getPublicUserData(userID: String) async -> PublicUserRecord? {
        let publicDB = container.publicCloudDatabase

        let query = CKQuery(recordType: "PublicUserRecord", predicate: NSPredicate(format: "UserID == %@", argumentArray: [userID]))
        
        do {
            let (publicRecords, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            
            guard let publicRecord = publicRecords.first?.1,
                  let publicUserRecord = PublicUserRecord.from(record: try publicRecord.get()) else {
                print("No public user record found")
                return nil
            }
            
            return publicUserRecord
        } catch {
            print("Error fetching public user record: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func getPublicUserData(phone: String) async -> PublicUserRecord? {
        let publicDB = container.publicCloudDatabase

        let query = CKQuery(recordType: "PublicUserRecord", predicate: NSPredicate(format: "Phone == %@", argumentArray: [phone]))
        
        do {
            let (publicRecords, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            
            print(publicRecords)
            guard let publicRecord = publicRecords.first?.1,
                  let publicUserRecord = PublicUserRecord.from(record: try publicRecord.get()) else {
                print("No public user record found")
                return nil
            }
            
            return publicUserRecord
        } catch {
            print("Error fetching public user record: \(error.localizedDescription)")
            return nil
        }
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
    
    static func findMatchingContactsInCloudKit() async throws -> [CKRecord] {
        print("Starting optimized findMatchingContactsInCloudKit function")
        
        let contactStore = CNContactStore()
        let granted = try await contactStore.requestAccess(for: .contacts)
        
        guard granted else {
            print("Access to contacts denied by user.")
            throw UserCloudKitError.contactAccessDenied
        }
        
        print("Access to contacts granted.")
        
        let contactNumbers = try await fetchContactPhoneNumbers()
        print("Fetched contact numbers: \(contactNumbers.count)")
        
        let matchedRecords = try await processBatchesConcurrently(contactNumbers: Array(Set(contactNumbers)))
        return Array(Set(matchedRecords))  // Remove any duplicate records
    }
    
    private static func fetchContactPhoneNumbers() async throws -> Set<String> {
        print("Starting fetchContactPhoneNumbers function")
        
        let contactStore = CNContactStore()
        var phoneNumbers = Set<String>()
        
        let keysToFetch = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        // Create a task to perform the contact enumeration
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
                    for phoneNumber in contact.phoneNumbers {
                        let strippedNumber = stripPhoneNumber(phoneNumber.value.stringValue)
                        phoneNumbers.insert(strippedNumber)
                    }
                }
                continuation.resume(returning: phoneNumbers)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private static func processBatchesConcurrently(contactNumbers: [String]) async throws -> [CKRecord] {
        print("Starting concurrent batch processing for \(contactNumbers.count) numbers")
        
        let batchSize = 150 // Increased batch size for better throughput
        let batches = stride(from: 0, to: contactNumbers.count, by: batchSize).map {
            Array(contactNumbers[$0..<min($0 + batchSize, contactNumbers.count)])
        }
        
        // Process all batches concurrently
        async let batchResults = withTaskGroup(of: [CKRecord].self) { group in
            for batch in batches {
                group.addTask {
                    do {
                        return try await performBatchQueryConcurrently(contactNumbers: batch)
                    } catch {
                        print("Error processing batch: \(error)")
                        return []
                    }
                }
            }
            
            var allRecords = [CKRecord]()
            for await batchResult in group {
                allRecords.append(contentsOf: batchResult)
            }
            return allRecords
        }
        
        return try await batchResults
    }
    
    private static func stripPhoneNumber(_ number: String) -> String {
        let stripped = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if stripped.hasPrefix("1") && stripped.count == 11 {
            return String(stripped.dropFirst())
        } else if stripped.count == 10 {
            return stripped
        }
        
        return stripped
    }
    
    private static func performBatchQueryConcurrently(contactNumbers: [String]) async throws -> [CKRecord] {
        print("Performing concurrent batch query for \(contactNumbers.count) numbers")
        
        let publicDatabase = container.publicCloudDatabase
        
        // Create concurrent queries for each phone number
        async let queries = withTaskGroup(of: [CKRecord].self) { group in
            for number in contactNumbers {
                group.addTask {
                    do {
                        let query = CKQuery(
                            recordType: "PublicUserRecord",
                            predicate: NSPredicate(format: "Phone == %@", number)
                        )
                        
                        let (records, _) = try await publicDatabase.records(
                            matching: query,
                            resultsLimit: 1  // Limit to 1 since we only need one match per number
                        )
                        
                        if let record = try records.first?.1.get(),
                           record["Phone"] as? String != nil {
                            return [record]
                        }
                    } catch {
                        print("Error querying for number \(number): \(error)")
                    }
                    return []
                }
            }
            
            var allRecords = [CKRecord]()
            for await result in group {
                allRecords.append(contentsOf: result)
            }
            return allRecords
        }
        
        return try await queries
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
    
    static func makeFriendRequest(to userID: String, completion: @escaping (FriendRequest?, Error?) -> Void) {
        guard let senderID = self.userData?.userID else {
            print("🚫 Error: User ID not found. Cannot proceed with friend request.")
            completion(nil, UserCloudKitError.friendRequestFailed)
            return
        }
        
        print("✅ User ID found: \(senderID)")
        print("📨 Initiating friend request to recipient with ID: \(userID)")

        let record = CKRecord(recordType: "FriendRequest")
        let uniqueID = UUID().uuidString
        record["ID"] = uniqueID as CKRecordValue
        record["SenderID"] = senderID as CKRecordValue
        record["RecipientID"] = userID as CKRecordValue
        record["IsAccepted"] = false as CKRecordValue
        
        print("📄 FriendRequest Record Created:")
        print("   - Record ID: \(uniqueID)")
        print("   - Sender ID: \(senderID)")
        print("   - Recipient ID: \(userID)")
        print("   - IsAccepted: false")
        
        let publicDB = container.publicCloudDatabase
        print("🌐 Saving FriendRequest record to the public database...")

        publicDB.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving FriendRequest record: \(error.localizedDescription)")
                    completion(nil, UserCloudKitError.friendRequestFailed)
                } else if let savedRecord = savedRecord {
                    print("✅ FriendRequest record saved successfully.")
                    print("   - Record ID: \(savedRecord.recordID)")
                    print("   - Saved Sender ID: \(savedRecord["SenderID"] ?? "N/A")")
                    print("   - Saved Recipient ID: \(savedRecord["RecipientID"] ?? "N/A")")
                    print("   - Saved IsAccepted: \(savedRecord["IsAccepted"] ?? "N/A")")
                    
                    let record = FriendRequest.from(record: savedRecord)
                    completion(record, nil)
                } else {
                    print("⚠️ Unexpected outcome: Record was neither saved nor did an error occur.")
                    completion(nil, UserCloudKitError.friendRequestFailed)
                }
            }
        }
    }

    static func getIncomingFriendRequests() async -> [FriendRequest] {
        guard let userID = self.userData?.userID else {
            print("Error: No userID found in userData. Returning an empty list.")
            return []
        }
        
        print("Starting to fetch incoming friend requests for userID: \(userID)")
        let publicDB = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "FriendRequest", predicate: NSPredicate(format: "RecipientID == %@", argumentArray: [userID]))
        
        var friendRequests: [FriendRequest] = []
        
        do {
            let (publicRecords, _) = try await publicDB.records(matching: query)
            print("Fetched \(publicRecords.count) friend requests from database.")
            
            friendRequests = publicRecords.compactMap { id, result in
                if let record = try? result.get() {
                    print("Successfully parsed FriendRequest with ID: \(id.recordName)")
                    print("Request ID: \(record["ID"])")
                    return FriendRequest.from(record: record)
                } else {
                    print("Error: Failed to parse FriendRequest with ID: \(id.recordName)")
                    return nil
                }
            }
        } catch {
            print("Error fetching friend requests: \(error.localizedDescription)")
            return friendRequests
        }
        
        print("Returning \(friendRequests.count) friend requests.")
        return friendRequests
    }

    
    static func getOutgoingFriendRequests() async -> [FriendRequest] {
        guard let userID = self.userData?.userID else {
            return []
        }
        
        let publicDB = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "FriendRequest", predicate: NSPredicate(format: "SenderID == %@", argumentArray: [userID]))
        
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
    
    static func acceptFriendRequest(requestID: String, senderID: String, recipientID: String) async throws {
        print("Starting friend request acceptance process")
        print("Request ID: \(requestID)")
        print("Sender ID: \(senderID)")
        print("Recipient ID: \(recipientID)")
        
        let publicDB = container.publicCloudDatabase
        
        let predicate = NSPredicate(format: "ID == %@", requestID)
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        
        do {
            let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
            guard let friendRequestRecord = results.first?.1 else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Friend request not found"])
            }
            
            let id = try friendRequestRecord.get().recordID
            try await publicDB.deleteRecord(withID: id)
        } catch {
            print("Error in friend request deletion: \(error.localizedDescription)")
            throw error
        }

        let senderPredicate = NSPredicate(format: "UserID == %@", senderID)
        let recipientPredicate = NSPredicate(format: "UserID == %@", recipientID)
        
        let senderQuery = CKQuery(recordType: "PublicUserRecord", predicate: senderPredicate)
        let recipientQuery = CKQuery(recordType: "PublicUserRecord", predicate: recipientPredicate)
        
        do {
            let (senderResults, _) = try await publicDB.records(matching: senderQuery, resultsLimit: 1)
            
            let (recipientResults, _) = try await publicDB.records(matching: recipientQuery, resultsLimit: 1)
            print("Recipient results count: \(recipientResults.count)")
            
            guard let sender = try senderResults.first?.1.get() else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sender not found"])
            }
            
            guard let recipient = try recipientResults.first?.1.get() else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recipient not found"])
            }
            

            var senderFriends = sender["Friends"] as? [String] ?? []
            
            if !senderFriends.contains(recipientID) {
                senderFriends.append(recipientID)
                sender["Friends"] = senderFriends
            } else {
                print("Recipient already in sender's friend list")
            }
            
            var recipientFriends = recipient["Friends"] as? [String] ?? []
            print("Current recipient friends: \(recipientFriends)")
            
            if !recipientFriends.contains(senderID) {
                recipientFriends.append(senderID)
                recipient["Friends"] = recipientFriends
                print("Updated recipient friends: \(recipientFriends)")
            } else {
                print("Sender already in recipient's friend list")
            }
            
            let operation = CKModifyRecordsOperation(recordsToSave: [sender, recipient])
            operation.savePolicy = .changedKeys
            
            let operationGroup = DispatchGroup()
            operationGroup.enter()
            
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("Successfully saved updated records")
                case .failure(let error):
                    print("Failed to save records: \(error.localizedDescription)")
                    if let ckError = error as? CKError {
                        print("CloudKit error code: \(ckError.code.rawValue)")
                        print("CloudKit error description: \(ckError.localizedDescription)")
                        if let serverRecord = ckError.serverRecord {
                            print("Server record details: \(serverRecord)")
                        }
                    }
                }
                operationGroup.leave()
            }
            
            publicDB.add(operation)
            
            operationGroup.wait()
        } catch {
            print("Error in user records processing: \(error.localizedDescription)")
            if let ckError = error as? CKError {
                print("CloudKit error code: \(ckError.code.rawValue)")
                print("CloudKit error description: \(ckError.localizedDescription)")
            }
            throw error
        }
    }
    
    static func declineFriendRequest(requestID: String) async throws {
        let publicDB = container.publicCloudDatabase

        let predicate = NSPredicate(format: "ID == %@", requestID)
        let query = CKQuery(recordType: "FriendRequest", predicate: predicate)
        
        let (results, _) = try await publicDB.records(matching: query, resultsLimit: 1)
        guard let friendRequestRecord = results.first?.1 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Friend request not found"])
        }
        
        let id = try friendRequestRecord.get().recordID
        try await publicDB.deleteRecord(withID: id)
    }
}

enum UserCloudKitError: Error {
    case contactAccessDenied
    case contactFetchError(Error)
    case cloudKitError(Error)
    case batchProcessingError([Error])
    case friendRequestFailed
}
