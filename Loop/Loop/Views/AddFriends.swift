//
//  AddFriends.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import SwiftUI
import CloudKit

struct AddFriends: View {
    @State private var matchedContacts: [CKRecord] = []
    @State private var friendRequestsSent: Set<String> = []
    @State private var loading = true
    
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            WaveBackground()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Add Friends")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .padding(.horizontal)

                if loading {
                    Spacer()
                    ProgressView("Searching Contacts...")
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    Spacer()
                } else if matchedContacts.isEmpty {
                    Spacer()
                    Text("No contacts using Loop found.")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(matchedContacts, id: \.recordID) { contact in
                                FriendContactWidget(contact: contact, friendRequestsSent: $friendRequestsSent)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                findMatchingContacts()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func findMatchingContacts() {
        UserCloudKitUtility.findMatchingContactsInCloudKit { result in
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .success(let records):
                    matchedContacts = records
                case .failure(let error):
                    print("Error finding matching contacts: \(error)")
                }
            }
        }
    }
}

// MARK: - Friend Contact Widget
struct FriendContactWidget: View {
    let contact: CKRecord
    @Binding var friendRequestsSent: Set<String>
    
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                if let username = contact["Username"] as? String {
                    Text(username)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                if let phone = contact["Phone"] as? String {
                    Text(phone)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if friendRequestsSent.contains(contact.recordID.recordName) {
                Text("Request Sent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.15))
                    .cornerRadius(12)
            } else {

                Button(action: {
                    sendFriendRequest(to: contact.recordID.recordName)
                }) {
                    Text("Add Friend")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func sendFriendRequest(to userID: String) {
        UserCloudKitUtility.makeFriendRequest(to: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    friendRequestsSent.insert(userID)
                case .failure(let error):
                    print("Error sending friend request: \(error)")
                }
            }
        }
    }
}


#Preview {
    AddFriends()
}
