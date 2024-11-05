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
                        case .insights:
                            InsightsView()
                        case .friends:
                            FriendsView()
                        case .allLoops:
                            ViewAllLoopsView()
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
                                    pageType = .insights
                                }, label: {
                                    VStack {
                                        Image(pageType == .insights ? "InsightsAccent" : "InsightsWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Insights")
                                            .font(.caption)
                                            .foregroundColor(pageType == .insights ? accentColor : .white)
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
                        
                        ZStack {
                            VStack {
                                Button(action: {
                                    pageType = .allLoops
                                }, label: {
                                    VStack {
                                        Image(pageType == .allLoops ? "HomeAccent" : "HomeWhite")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .aspectRatio(contentMode:  .fill)
                                        
                                        Text("Loops")
                                            .font(.caption)
                                            .foregroundColor(pageType == .allLoops ? accentColor : .white)
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
                WaveBackground()
                    .edgesIgnoringSafeArea(.all)
            )
        }
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
