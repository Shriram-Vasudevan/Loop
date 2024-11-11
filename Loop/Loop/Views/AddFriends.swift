//
//  AddFriends.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import SwiftUI
import CloudKit

struct AddFriends: View {
    @ObservedObject var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var backgroundOpacity: Double = 0
    @State private var searchText = ""
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            // Animated background from HomeView
//            HomeBackground(accentColor: accentColor, secondaryColor: <#Color#>)
//                .opacity(backgroundOpacity)
//                .onAppear {
//                    withAnimation(.easeIn(duration: 1.2)) {
//                        backgroundOpacity = 1
//                    }
//                }
//            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    
                    if !friendsManager.incomingfriendRequests.isEmpty {
                        pendingRequestsSection
                            .transition(.opacity)
                    }
                    
                    connectSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                if friendsManager.matchedContacts.isEmpty {
                    await findMatchingContacts()
                } else {
                    loading = false
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("connect")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            // Inspirational quote
            Text("share your journey with others")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("pending connections")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(friendsManager.incomingfriendRequests, id: \.id) { request in
                        PendingRequestCard(
                            request: request,
                            onError: { error in
                                errorMessage = error
                                showError = true
                            },
                            accepted: { isAccepted in
                                handleRequestResponse(request: request, accepted: isAccepted)
                            }
                        )
                    }
                }
                .padding(.bottom, 8) // For shadow space
            }
        }
    }
    
    private var connectSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("discover friends")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            if loading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if friendsManager.matchedContacts.isEmpty {
                emptyStateView
            } else {
                contactsGrid
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                .scaleEffect(1.5)
            
            Text("finding your friends")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical, 20)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(accentColor)
            
            Text(error)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task { await findMatchingContacts() }
            }) {
                Text("try again")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.2")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(accentColor)
            }
            
            Text("invite friends to loop")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Text("share your daily reflections with friends")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task { await findMatchingContacts() }
            }) {
                Text("refresh")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
    }
    
    private var contactsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(friendsManager.matchedContacts, id: \.userID) { contact in
                ContactBubble(contact: contact) { error in
                    errorMessage = error
                    showError = true
                }
            }
        }
    }
    
    // Functionality methods remain the same
    private func findMatchingContacts() async {
        loading = true
        errorMessage = nil
        
        do {
            let matchedContacts = try await UserCloudKitUtility.findMatchingContactsInCloudKit()
            var friendRecords: [PublicUserRecord] = []
            
            for contact in matchedContacts {
                guard let record = await UserCloudKitUtility.getPublicUserData(
                    userID: contact["UserID"] as? String ?? "nil"
                ) else { continue }
                
                if record.phone == UserCloudKitUtility.userData?.phone { continue }
                friendRecords.append(record)
            }
            
            friendsManager.matchedContacts = friendRecords
            loading = false
        } catch {
            loading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleRequestResponse(request: FriendRequest, accepted: Bool) {
        Task {
            if accepted {
                try? await UserCloudKitUtility.acceptFriendRequest(
                    requestID: request.id,
                    senderID: request.senderID,
                    recipientID: request.recipientID
                )
                FriendsManager.shared.userData?.friends.append(request.senderID)
            } else {
                try? await UserCloudKitUtility.declineFriendRequest(requestID: request.id)
            }
            friendsManager.incomingfriendRequests.removeAll { $0.id == request.id }
        }
    }
}

struct ContactBubble: View {
    let contact: PublicUserRecord
    let onError: (String) -> Void
    
    @State private var isProcessing = false
    @ObservedObject var friendsManager = FriendsManager.shared
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Text(contact.name.prefix(1).uppercased())
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            VStack(spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                
                Text(contact.phone)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.5))
                    .lineLimit(1)
            }
            
            if isRequestSent {
                Text("sent")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(accentColor)
            } else {
                Button(action: sendFriendRequest) {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("connect")
                                .font(.system(size: 14, weight: .regular))
                        }
                    }
                    .frame(width: isProcessing ? 24 : nil)
                }
                .disabled(isProcessing)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
    }
    
    private var isRequestSent: Bool {
        friendsManager.outgoingFriendRequests.contains { $0.recipientID == contact.userID }
    }
    
    private func sendFriendRequest() {
        guard !isProcessing else { return }
        isProcessing = true
        
        UserCloudKitUtility.makeFriendRequest(to: contact.userID) { record, error in
            isProcessing = false
            
            if let error = error {
                onError(handleFriendRequestError(error))
                return
            }
            
            if let friendRequest = record {
                friendsManager.outgoingFriendRequests.append(friendRequest)
            }
        }
    }
    
    private func handleFriendRequestError(_ error: Error) -> String {
        if let cloudError = error as? CKError {
            switch cloudError.code {
            case .networkUnavailable:
                return "Please check your internet connection"
            case .notAuthenticated:
                return "Please sign in to iCloud"
            default:
                return "Failed to send request"
            }
        }
        return "An unexpected error occurred"
    }
}

struct PendingRequestCard: View {
    let request: FriendRequest
    let onError: (String) -> Void
    let accepted: (Bool) -> Void
    
    @State private var isProcessing = false
    @State private var publicUserRecord: PublicUserRecord?
    @State private var isHovered = false
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Avatar and Name Section
            VStack(spacing: 16) {
                // Avatar Circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.15),
                                    accentColor.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            accentColor.opacity(0.2),
                                            accentColor.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    if let record = publicUserRecord {
                        Text(record.name.prefix(1).uppercased())
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(accentColor)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    }
                }
                
                // Name and Status
                VStack(spacing: 6) {
                    Text(publicUserRecord?.name ?? "Loading...")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 12, weight: .light))
                        Text("wants to connect")
                            .font(.system(size: 14, weight: .light))
                    }
                    .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                // Accept Button
                Button(action: { handleResponse(accepted: true) }) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))
                            Text("accept")
                                .font(.system(size: 15, weight: .regular))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.15), radius: 8, y: 4)
                }
                .disabled(isProcessing)
                
                // Decline Button
                Button(action: { handleResponse(accepted: false) }) {
                    Text("decline")
                        .font(.system(size: 15, weight: .regular))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .foregroundColor(textColor.opacity(0.6))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(textColor.opacity(0.1), lineWidth: 1)
                        )
                }
                .disabled(isProcessing)
            }
        }
        .padding(24)
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.98)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(0.06),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .onAppear {
            Task {
                publicUserRecord = await UserCloudKitUtility.getPublicUserData(userID: request.senderID)
            }
        }
    }
    
    private func handleResponse(accepted: Bool) {
        isProcessing = true
        self.accepted(accepted)
        isProcessing = false
    }
}


struct PulsingLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 1)
            
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 1)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: color))
                .scaleEffect(1.5)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
#Preview {
    AddFriends()
}
