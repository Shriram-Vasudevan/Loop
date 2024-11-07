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
