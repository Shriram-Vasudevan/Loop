//
//  FriendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/4/24.
//

import SwiftUI

import SwiftUI

struct FriendsView: View {
    @ObservedObject var friendsManager = FriendsManager.shared
    @State var showAddFriendsSheet = false
    @State private var friends: [PublicUserRecord] = []
    @State private var loading = true
    @State private var errorMessage: String?
    @State private var backgroundOpacity: Double = 0
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            // Animated background from HomeView
//            HomeBackground()
//                .opacity(backgroundOpacity)
//                .onAppear {
//                    withAnimation(.easeIn(duration: 1.2)) {
//                        backgroundOpacity = 1
//                    }
//                }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    
                    if loading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        content
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                await loadFriends()
            }
        }
        .fullScreenCover(isPresented: $showAddFriendsSheet) {
            AddFriends()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("friends")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Spacer()
            
            Button(action: { showAddFriendsSheet = true }) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
    
    private var content: some View {
        VStack(spacing: 32) {
            if !friends.isEmpty {
                friendsSection
            }
            
            anonymousLoopsSection
            
            if friends.isEmpty {
                emptyStateView
            }
        }
    }
    
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("shared loops")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            LazyVStack(spacing: 16) {
                ForEach(friends, id: \.userID) { friend in
                    NavigationLink(destination: LoopChatView(friend: friend)) {
                        FriendLoopCard(friend: friend)
                    }
                }
            }
        }
    }
    
    private var anonymousLoopsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("anonymous loops")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    anonymousLoopCards
                }
                .padding(.bottom, 8) // For shadow space
            }
        }
    }

    private var anonymousLoopCards: some View {
        Group {
            if friendsManager.anonymousLoops.isEmpty {
                placeholderLoopCards
            } else {
                actualLoopCards
            }
        }
    }

    private var placeholderLoopCards: some View {
        ForEach(0..<3) { index in
            AnonymousLoopCard(
                quote: mysteriousQuotes[index % mysteriousQuotes.count],
                date: Date().addingTimeInterval(Double(-index * 86400))
            )
        }
    }

    private var actualLoopCards: some View {
        ForEach(friendsManager.anonymousLoops, id: \.id) { loop in
            AnonymousLoopCard(
                quote: loop.prompt,
                date: loop.timestamp
            )
        }
    }
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: 300)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(accentColor)
            
            Text(message)
                .font(.system(size: 18, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
            
            Button(action: {
                Task {
                    await loadFriends()
                }
            }) {
                Text("try again")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
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
            
            Text("share your reflections")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Button(action: { showAddFriendsSheet = true }) {
                Text("add friends")
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
        .padding(.top, 40)
    }
    
    private func loadFriends() async {
        loading = true
        errorMessage = nil
        friends = []
        
        guard let userData = friendsManager.userData else {
            loading = false
            errorMessage = "Unable to load user data"
            return
        }
        
        for friendID in userData.friends {
            if let friendData = await UserCloudKitUtility.getPublicUserData(userID: friendID) {
                friends.append(friendData)
            }
        }
        
        loading = false
    }
    
    private let mysteriousQuotes = [
        "In silence, truth speaks volumes...",
        "Every reflection holds a story untold",
        "Whispers of wisdom from unknown souls",
        "Through others' eyes, we see ourselves"
    ]
}

struct FriendLoopCard: View {
    let friend: PublicUserRecord
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor.opacity(0.2), accentColor.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                
                Text(friend.name.prefix(1).uppercased())
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(textColor)
                
                Text("2 shared loops")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        )
    }
}

struct AnonymousLoopCard: View {
    let quote: String
    let date: Date
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quote icon
            Image(systemName: "quote.bubble")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(accentColor)
            
            // Quote text
            Text(quote)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Date
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .light))
                Text(formatDate(date))
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundColor(textColor.opacity(0.6))
        }
        .frame(width: 200, height: 180)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.white.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    FriendsView()
}
