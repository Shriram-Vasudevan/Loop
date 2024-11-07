//
//  FriendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation

class FriendsManager: ObservableObject {
    static let shared = FriendsManager()
    
    @Published var friendsID: [String]?
    @Published var recievedLoops: [SharedLoop]?
    @Published var friendRequests: [FriendRequest] = []
    
    @Published var matchedContacts: [PublicUserRecord] = []
    @Published var friendRequestsSent: Set<String> = []
    @Published var recievedRequests: [FriendRequest: PublicUserRecord] = [:]
    
    init() {
        
    }
    
    func getRecievedLoops() {
        self.recievedLoops = UserCloudKitUtility.getRecievedLoops()
    }
    
    func getAllFriends() {
        
    }
    func addFriend() {
        
    }
    
    func removeFriend() {
        
    }
    
    func getFriendData(userID: String) {
        
    }
}
