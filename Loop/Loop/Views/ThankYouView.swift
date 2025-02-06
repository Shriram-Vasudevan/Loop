//
//  ThankYouView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct DiscoverView: View {
    @State private var searchText = ""
    @State private var showingFavoritesTip = true
    
    let gridColums = Array(repeating: GridItem(.flexible()), count: 3)
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Image(systemName: "bolt.horizontal.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 25))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
                    
                    Text("Discover")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                    
                    
                    if showingFavoritesTip {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "star")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().stroke(Color.white, lineWidth: 1))
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showingFavoritesTip = false
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 13))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Favorite inspiring images")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Hold down an image and tap the star icon. Favoriting images will help customize what you see here.")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.trailing, 24)
                        }
                        .padding()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<4) { index in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 150, height: 150)
                                        .clipped()
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        HStack {
                            Text("#FreshTake")
                                .font(.system(.title3, design: .default))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("2,218 posts")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Selects section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selects")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Curated by VSCO")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 1),
                            GridItem(.flexible(), spacing: 1),
                            GridItem(.flexible(), spacing: 1)
                        ], spacing: 1) {
                            ForEach(0..<6) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)

        }
    }
}

// Tab Bar View
struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Color.black
                .tabItem {
                    Image(systemName: "house")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(1)
            
            Color.black
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                }
                .tag(2)
            
            Color.black
                .tabItem {
                    Image(systemName: "face.smiling")
                }
                .tag(3)
            
            Color.black
                .tabItem {
                    Image(systemName: "chart.bar")
                }
                .tag(4)
        }
        .accentColor(.white)
    }
}

struct ContentView: View {
    var body: some View {
        TabBarView()
    }
}
#Preview {
    DiscoverView()
}
