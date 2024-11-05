//
//  FriendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/4/24.
//

import SwiftUI

struct FriendsView: View {
    @State var showAddFriendsSheet: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showAddFriendsSheet = true
                    }, label: {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(7)
                            .background(
                                Circle()
                                    .foregroundColor(.black)
                            )
                    })
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showAddFriendsSheet, content: {
            AddFriends()
        })
    }
    
   
}

struct FriendWidget: View {
    var body: some View {
        ZStack {
            
        }
    }
}

#Preview {
    FriendsView()
}
