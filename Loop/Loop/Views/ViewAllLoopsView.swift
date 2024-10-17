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

    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color.white
    let groupBackgroundColor = Color(hex: "F8F5F7")

    var body: some View {
        ZStack {
            WaveBackground()

            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Your Loops")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    .padding(.horizontal)

                if loading {
                    // Loading Indicator
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    Spacer()
                } else if loopManager.recentDates.isEmpty {
                    // No Loops Found State
                    Spacer()
                    Text("No loops found. Start recording today!")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                } else {
                    // Display Loops by Date with Horizontal Scrolls
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(loopManager.recentDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 10) {
                                    // Date Header
                                    Text(formattedDate(date))
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal)

                                    // Horizontal Scroll of Loops for this Date
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(loopManager.loopsByDate[date] ?? [], id: \.id) { loop in
                                                LoopWidget(loop: loop, accentColor: accentColor)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }

                            // Pagination Trigger: Detect when user reaches the bottom
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

// MARK: - Loop Widget Component
struct LoopWidget: View {
    let loop: Loop
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Loop Icon or Video Preview
            if loop.isVideo {
                VideoPreviewPlaceholder()
            } else {
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(accentColor)
                    .padding(10)
            }

            // Loop Prompt
            Text(loop.promptText)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Play Button for Loop
            Button(action: {
                playLoop(loop)
            }) {
                Text("Play")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func VideoPreviewPlaceholder() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.1))
                .frame(width: 80, height: 80)

            Image(systemName: "video.fill")
                .foregroundColor(accentColor)
                .font(.system(size: 30))
        }
    }

    private func playLoop(_ loop: Loop) {
        print("Playing loop: \(loop.id)")
    }
}


#Preview {
    ViewAllLoopsView()
}
