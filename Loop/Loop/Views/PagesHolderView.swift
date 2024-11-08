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
                            InsightsView()
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
                                        
                                        Text("Insights")
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
                            = try await UserCloudKitUtility.getCurrentUserData() else { return }
                    print("the userid \(userData.userID)")
                    
                    let name = await UserCloudKitUtility.getPublicUserData(phone: "9736109630")?.name
                    
                    print("the name \(name)")
                }
            }
        }
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
