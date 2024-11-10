//
//  FriendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/5/24.
//

import Foundation

class FriendsManager: ObservableObject {
    static let shared = FriendsManager()
    
    @Published var userData: PublicUserRecord?
    
    @Published var recievedLoops: [SharedLoop]?
    @Published var incomingfriendRequests: [FriendRequest] = []
    @Published var outgoingFriendRequests: [FriendRequest] = []
    
    @Published var matchedContacts: [PublicUserRecord] = []
    
    @Published var anonymousLoops: [SharedLoop] = []
    init() {
        
    }
    
    func getRecievedLoops() {
        self.recievedLoops = UserCloudKitUtility.getRecievedLoops()
    }
    
    func sendLoopToFriend(sharedLoop: SharedLoop, userID: String) {
        
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
