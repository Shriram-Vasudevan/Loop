//
//  PagesHolderView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct PagesHolderView: View {
    @State var pageType: PageType
    
    
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    switch pageType {
                        case .home:
                            HomeView()
                        case .loopCenter:
                            LoopsView()
                        case .settings:
                            SettingsView()
                        case .friends:
                            FriendsView()
                    }
                    
                    Spacer()
                                                        
                    HStack {
                        ZStack {
                            VStack {
                                Button(action: {
                                    pageType = .home
                                }, label: {
                                    VStack {
                                        Image(pageType == .home ? "HomeAccent" : "HomeWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Home")
                                            .font(.caption)
                                            .foregroundColor(pageType == .home ? accentColor : .white)
                                    }
                                    .padding(.bottom)
                                })
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                        }
                        
                        ZStack {
                            VStack {
                                Button(action: {
                                    pageType = .loopCenter
                                }, label: {
                                    VStack {
                                        Image(pageType == .loopCenter ? "InsightsAccent" : "InsightsWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Loop")
                                            .font(.caption)
                                            .foregroundColor(pageType == .loopCenter ? accentColor : .white)
                                    }
                                    .padding(.bottom)
                                })
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                        }
                        
                        ZStack {
                            VStack {
                                Button(action: {
                                    pageType = .settings
                                }, label: {
                                    VStack {
                                        Image(pageType == .settings ? "HomeAccent" : "HomeWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Settings")
                                            .font(.caption)
                                            .foregroundColor(pageType == .settings ? accentColor : .white)
                                    }
                                    .padding(.bottom)
                                })
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                        }
                        
                        ZStack {
                            VStack {
                                Button(action: {
                                    pageType = .friends
                                }, label: {
                                    VStack {
                                        Image(pageType == .friends ? "HomeAccent" : "HomeWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Friends")
                                            .font(.caption)
                                            .foregroundColor(pageType == .friends ? accentColor : .white)
                                    }
                                    .padding(.bottom)
                                })
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                        }

                        
                    }
                    
                    
                }
            }
            .background(
//                WaveBackground()
//                    .edgesIgnoringSafeArea(.all)
            )
            .onAppear {
                Task {
                    guard let userData
                            = try await UserCloudKitUtility.getCurrentUserData() else { 
                        print("failed")
                        return }
                    FriendsManager.shared.userData = userData
                    print("HERE")
                    FriendsManager.shared.incomingfriendRequests = await UserCloudKitUtility.getIncomingFriendRequests()
                    FriendsManager.shared.outgoingFriendRequests = await UserCloudKitUtility.getOutgoingFriendRequests()
                }
            }
        }
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
