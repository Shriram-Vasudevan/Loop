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
    
    static func getCurrentUserData() -> PublicUserRecord? {
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
                print("Error fetching Record: \(error.localizedDescription)")
            }
        }
        
        privateDB.add(queryOperation)
        
        guard let selectedUserRecord = selectedUserRecord else { return nil }
        
        let publicQuery = CKQuery(recordType: "PublicUserRecord", predicate: NSPredicate(format: "%@", argumentArray: [selectedUserRecord.userID]))
        let pubicQueryOperation = CKQueryOperation(query: query)
        pubicQueryOperation.resultsLimit = 1
        
        var userRecord: PublicUserRecord?
        pubicQueryOperation.recordFetchedBlock = { record in
            if let userRecord = UserRecord.from(record: record) {
                self.userData = userRecord
            }
        }
        
        pubicQueryOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("Error fetching Record: \(error.localizedDescription)")
            }
        }
        
        return userRecord
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
        // Move the entire operation to a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            // First check contacts authorization
            let contactStore = CNContactStore()
            
            contactStore.requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    print("Contact access request error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(UserCloudKitError.contactFetchError(error)))
                    }
                    return
                }
                
                guard granted else {
                    print("Contact access denied by user.")
                    DispatchQueue.main.async {
                        completion(.failure(UserCloudKitError.contactAccessDenied))
                    }
                    return
                }
                
                // Fetch contact numbers in background
                Task {
                    do {
                        let contactNumbers = try await prepareContactPhoneNumbers()
                        try await performBatchQueries(with: contactNumbers, completion: completion)
                    } catch {
                        print("Error during contact number preparation or batch query execution: \(error)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }

    private static func performBatchQueries(
        with contactNumbers: [String],
        completion: @escaping (Result<[CKRecord], Error>) -> Void
    ) async throws {
        let publicDatabase = container.publicCloudDatabase
        let batchSize = 5  // Reduce batch size to limit complexity
        var allMatchedRecords = [CKRecord]()
        var batchErrors = [Error]()
        
        // Create smaller batches of phone numbers to avoid complex predicates
        let batches = stride(from: 0, to: contactNumbers.count, by: batchSize).map { start -> [String] in
            let end = min(start + batchSize, contactNumbers.count)
            return Array(contactNumbers[start..<end])
        }
        
        // Process each batch concurrently
        await withTaskGroup(of: Result<[CKRecord], Error>.self) { group in
            for batch in batches {
                group.addTask {
                    await processBatch(batch, database: publicDatabase)
                }
            }
            
            // Collect results from all batches
            for await result in group {
                switch result {
                case .success(let records):
                    allMatchedRecords.append(contentsOf: records)
                case .failure(let error):
                    print("Batch processing error: \(error)")
                    batchErrors.append(error)
                }
            }
        }
        
        // Handle final results
        DispatchQueue.main.async {
            if batchErrors.isEmpty {
                completion(.success(allMatchedRecords))
            } else {
                print("Completed with batch errors: \(batchErrors)")
                completion(.failure(UserCloudKitError.batchProcessingError(batchErrors)))
            }
        }
    }

    private static func processBatch(_ numbers: [String], database: CKDatabase) async -> Result<[CKRecord], Error> {
        let predicates = numbers.map { NSPredicate(format: "Phone == %@", $0) }
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        let query = CKQuery(recordType: "PublicUserRecord", predicate: compoundPredicate)
        
        do {
            let records = try await database.records(matching: query)
            return .success(records.matchResults.compactMap { result in
                do {
                    return try result.1.get()
                } catch {
                    print("Failed to retrieve record result for \(result.0): \(error)")
                    return nil
                }
            })
        } catch {
            // Check if the error is due to the predicate complexity
            print("CloudKit query error: \(error.localizedDescription)")
            if error.localizedDescription.contains("Invalid predicate") {
                print("Predicate too complex for CloudKit. Consider further reducing batch size.")
            }
            return .failure(UserCloudKitError.cloudKitError(error))
        }
    }


    private static func prepareContactPhoneNumbers() async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
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
                print("Successfully fetched and formatted \(formattedNumbers.count) contact numbers.")
                continuation.resume(returning: formattedNumbers)
            } catch {
                print("Error fetching contacts: \(error.localizedDescription)")
                continuation.resume(throwing: UserCloudKitError.contactFetchError(error))
            }
        }
    }

    private static func stripPhoneNumber(_ number: String) -> String {
        let stripped = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        print("Stripped phone number: \(stripped)")
        return stripped
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

enum UserCloudKitError: Error {
    case contactAccessDenied
    case contactFetchError(Error)
    case cloudKitError(Error)
    case batchProcessingError([Error])
}
