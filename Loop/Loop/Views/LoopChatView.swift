import SwiftUI
import AVKit

struct LoopChatView: View {
    let friend: PublicUserRecord
    @ObservedObject var loopManager = LoopManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedLoop: Loop?
    @State private var showingSendSheet = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var isAddingLoop = false
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            // Clean, minimal background
            Color(hex: "FAFBFC").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chat-style header
                navigationBar
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(loopManager.pastLoops, id: \.self) { loop in
                            SharedLoopBubble(loop: loop) {
                                selectedLoop = loop
                                withAnimation(.spring()) {
                                    isAddingLoop = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Space for button
                }
                
                // Floating action button
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isAddingLoop) {
            SendLoopOverlay(friend: friend)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var navigationBar: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
            }
            
            // Avatar
            Circle()
                .fill(accentColor.opacity(0.1))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(friend.name.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Text("@" + friend.username)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isAddingLoop = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: accentColor.opacity(0.3), radius: 10, y: 5)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
}

struct SharedLoopBubble: View {
    let loop: Loop
    let onTap: () -> Void
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Waveform thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 18))
                            .foregroundColor(accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(loop.promptText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Text(formatDate(loop.timestamp))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textColor.opacity(0.5))
                        
                        Circle()
                            .fill(textColor.opacity(0.3))
                            .frame(width: 3, height: 3)
                        
                        Text("30s")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(accentColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}


#Preview {
    NavigationStack {
        LoopChatView(friend: PublicUserRecord(userID: "", username: "", phone: "", name: "", friends: [""]))
    }
}
