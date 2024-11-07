//
//  ViewAllLoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/16/24.
//



import SwiftUI

struct ViewAllLoopsView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @State private var loading = true
    @State private var isFetchingMore = false // To track loading state for pagination

    @State private var showPastLoopSheet = false
    @State private var selectedLoop: Loop? // Optional Loop
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color.white
    let groupBackgroundColor = Color(hex: "F8F5F7")

    
    var body: some View {
        ZStack {
            WaveBackground()

            VStack(alignment: .leading, spacing: 16) {
                Text("Your Loops")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .padding(.horizontal)

                if loading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    Spacer()
                } else if loopManager.recentDates.isEmpty {
                    Spacer()
                    Text("No loops found. Start recording today!")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(loopManager.recentDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(formattedDate(date))
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(loopManager.loopsByDate[date] ?? [], id: \.id) { loop in
                                                PastLoopCard(loop: loop, accentColor: accentColor) {
                                                    self.selectedLoop = loop
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            if isFetchingMore {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                                    .padding()
                            } else {
                                Color.clear
                                    .onAppear {
                                        fetchMoreLoops()
                                    }
                            }
                        }
                    }
                }
            }
            .onAppear {
                fetchInitialLoops()
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }


    private func fetchInitialLoops() {
        loading = true
        loopManager.fetchRecentDates(limit: 6) {
            loading = false
        }
    }

    private func fetchMoreLoops() {
        guard !isFetchingMore else { return }
        isFetchingMore = true

        loopManager.fetchNextPageOfDates(limit: 6) {
            isFetchingMore = false
        }
    }
}


#Preview {
    ViewAllLoopsView()
}
