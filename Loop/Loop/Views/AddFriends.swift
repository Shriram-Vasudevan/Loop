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
    @State private var errorMessage: String?
    @State private var showError = false
    
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            WaveBackground()
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Add Friends")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                if loading {
                    Spacer()
                    ProgressView("Searching Contacts...")
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("Oops!")
                            .font(.system(size: 24, weight: .medium))
                        Text(error)
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        Button("Try Again") {
                            Task {
                                await findMatchingContacts()
                            }
                        }
                        .foregroundColor(accentColor)
                        .padding(.top, 10)
                    }
                    .padding()
                    Spacer()
                } else if matchedContacts.isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Text("No contacts found")
                            .font(.system(size: 18, weight: .medium))
                        Text("None of your contacts are currently using Loop")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Button("Refresh") {
                            Task {
                                await findMatchingContacts()
                            }
                        }
                        .foregroundColor(accentColor)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(matchedContacts, id: \.recordID) { contact in
                                FriendContactWidget(
                                    contact: contact,
                                    friendRequestsSent: $friendRequestsSent,
                                    onError: { error in
                                        errorMessage = error
                                        showError = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                Task {
                    await findMatchingContacts()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func findMatchingContacts() async {
        loading = true
        errorMessage = nil
        
        await UserCloudKitUtility.findMatchingContactsInCloudKit { result in
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .success(let records):
                    matchedContacts = records
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct FriendContactWidget: View {
    let contact: CKRecord
    @Binding var friendRequestsSent: Set<String>
    let onError: (String) -> Void
    
    @State private var isProcessing = false
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
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Add Friend")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .disabled(isProcessing)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(accentColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func sendFriendRequest(to userID: String) {
        guard !isProcessing else { return }
        isProcessing = true
        
        UserCloudKitUtility.makeFriendRequest(to: userID) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success:
                    friendRequestsSent.insert(userID)
                case .failure(let error):
                    onError(handleFriendRequestError(error))
                }
            }
        }
    }
    
    private func handleFriendRequestError(_ error: Error) -> String {
        switch error {
        case let cloudError as CKError:
            switch cloudError.code {
            case .networkUnavailable:
                return "Please check your internet connection and try again."
            case .notAuthenticated:
                return "Please sign in to iCloud to send friend requests."
            case .limitExceeded:
                return "You've sent too many friend requests. Please try again later."
            default:
                return "Failed to send friend request. Please try again."
            }
        default:
            return "An unexpected error occurred. Please try again."
        }
    }
}

#Preview {
    NavigationView {
        AddFriends()
    }
}
