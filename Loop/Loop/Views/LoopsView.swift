//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

import SwiftUI
import Darwin

struct LoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedTab = "recent"
    @State private var selectedLoop: Loop?
    @State private var selectedMonthId: MonthIdentifier?
    @State private var backgroundOpacity = 1.0
    
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            FlowingBackground(color: accentColor)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                tabNavigation
                    .padding(.top, 15)
                
                if selectedTab == "recent" {
                    RecentLoopsView(selectedLoop: $selectedLoop)
                } else {
                    if let monthId = selectedMonthId {
                        MonthDetailView(monthId: monthId) {
                            withAnimation {
                                selectedMonthId = nil
                            }
                        }
                    } else {
                        MonthsGridView(selectedMonthId: $selectedMonthId)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                backgroundOpacity = 0.3
            }
            Task {
                await loopManager.loadActiveMonths()
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .center, spacing: 0) {
                    Text("journal")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(textColor)
                    
                    HStack(spacing: 4) {
                        Text("see")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.gray)
                        Text("your")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.gray)
                        Text("reflections")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    .padding(.top, -5)

                }
//
//                Spacer()
//                
//                if !loopManager.hasCompletedToday {
//                    CircularProgress(
//                        progress: CGFloat(loopManager.currentPromptIndex) / CGFloat(loopManager.dailyPrompts.count),
//                        color: accentColor
//                    )
//                    .frame(width: 50, height: 50)
//                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var tabNavigation: some View {
        Menu {
            Button("recent") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "recent"
                }
            }
            Button("past") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "past"
                }
            }
        } label: {
            ZStack {

                HStack(spacing: 8) {
                    Text(selectedTab)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    backgroundColor,
                                    Color(hex: "FFFFFF")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .cornerRadius(28)
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
                .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.trailing)
                }
                .padding(.horizontal)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct RecentLoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedLoop: Loop?
    @State private var loadingMore = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                ForEach(loopManager.recentDates, id: \.self) { date in
                    DaySection(
                        date: date,
                        loops: loopManager.loopsByDate[date] ?? [],
                        selectedLoop: $selectedLoop
                    )
                }
                
                if loadingMore {
                    ProgressView()
                        .frame(height: 50)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .task {
            if loopManager.recentDates.isEmpty {
                await loadInitialLoops()
            }
        }
    }
    
    private func loadInitialLoops() async {
        loadingMore = true
        loopManager.fetchRecentDates(limit: 10) {
            loadingMore = false
        }
    }
}

struct DaySection: View {
    let date: Date
    let loops: [Loop]
    @Binding var selectedLoop: Loop?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(formatDate())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Rectangle()
                    .fill(textColor.opacity(0.1))
                    .frame(height: 1)
            }
            
            ForEach(loops) { loop in
                LoopCard(loop: loop) {
                    selectedLoop = loop
                }
            }
        }
    }
    
    private func formatDate() -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        }
    }
}

struct LoopCard: View {
    let loop: Loop
    let action: () -> Void
    @State private var showDeleteConfirmation = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(formatTime())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                WaveformIndicator(color: accentColor)
            }
            
            Text(loop.promptText)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                AudioWaveform(color: accentColor)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15)
        )
        .scaleEffect(isPressed ? 0.97 : 1)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .onTapGesture(perform: action)
        .alert("Delete Loop", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await LoopManager.shared.deleteLoop(withID: loop.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this loop? This action cannot be undone.")
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: loop.timestamp)
    }
}

struct MonthsGridView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedMonthId: MonthIdentifier?
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(loopManager.activeMonths, id: \.self) { monthId in
                    MonthCard(monthId: monthId) {
                        withAnimation {
                            selectedMonthId = monthId
                            Task {
                                await loopManager.loadMonthData(monthId: monthId)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct MonthCard: View {
    let monthId: MonthIdentifier
    @State private var summary: MonthSummary?
    @State private var backgroundOpacity: Double = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            if let summary = summary {
                Text("\(summary.totalEntries)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(Color(hex: "F0F0F0"))
                    .offset(x: 10, y: -5)
                    .opacity(backgroundOpacity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monthName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text(String(monthId.year))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                if let summary = summary {
                    Text("\(summary.totalEntries) memories")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
        .task {
            await loadSummary()
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.year = monthId.year
        components.month = monthId.month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    private func loadSummary() async {
        do {
            summary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
            withAnimation(.easeOut(duration: 0.8)) {
                backgroundOpacity = 1
            }
        } catch {
            print("Error loading month summary: \(error)")
        }
    }
}


struct MonthDetailView: View {
    let monthId: MonthIdentifier
    let onBack: () -> Void
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedLoop: Loop?
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(accentColor)
            }
            
            if let summary = loopManager.selectedMonthSummary {
                ScrollView {
                    VStack(spacing: 24) {
                        Text(monthTitle)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(textColor)
                        
                        ForEach(groupedLoops(summary.loops), id: \.0) { date, loops in
                            DaySection(date: date, loops: loops, selectedLoop: $selectedLoop)
                        }
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
    }
    
    private var monthTitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.year = monthId.year
        components.month = monthId.month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    private func groupedLoops(_ loops: [Loop]) -> [(Date, [Loop])] {
        let grouped = Dictionary(grouping: loops) { loop in
            Calendar.current.startOfDay(for: loop.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

struct WaveformIndicator: View {
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2, height: getHeight(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
    
    private func getHeight(for index: Int) -> CGFloat {
        isAnimating ? [8, 16, 8][index] : 12
    }
}

struct AudioWaveform: View {
    let color: Color
    @State private var waveformData: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.3))
                    .frame(width: 2, height: waveformData[safe: index] ?? 12)
            }
        }
        .frame(height: 32)
        .onAppear {
            waveformData = (0..<40).map { _ in
                CGFloat.random(in: 4...32)
            }
        }
    }
}

struct CircularProgress: View {
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, lineWidth: 4)
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 3))/3")
                    .font(.system(size: 12, weight: .medium))
                Text("today")
                    .font(.system(size: 10, weight: .regular))
            }
            .foregroundColor(color)
        }
    }
}

struct FlowingBackground: View {
    let color: Color
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                phase = time.truncatingRemainder(dividingBy: 6)
                
                for i in 0..<3 {
                    let path = createWavePath(
                        in: size,
                        phase: phase + Double(i) * .pi / 3,
                        amplitude: Double(20 + i * 5)
                    )
                    
                    context.opacity = 0.1 - Double(i) * 0.02
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        )
                    )
                }
            }
        }
    }
    
    private func createWavePath(in size: CGSize, phase: Double, amplitude: Double) -> Path {
        var path = Path()
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 5) {
            let normalizedX = x / width
            let wavePhase1 = normalizedX * 4 * .pi + phase
            let wavePhase2 = normalizedX * 2 * .pi + phase * 1.5
            
            let sinComponent = Darwin.sin(wavePhase1) * amplitude
            let cosComponent = Darwin.cos(wavePhase2) * (amplitude * 0.5)
            
            let y = midHeight + sinComponent + cosComponent
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct SpringyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    LoopsView()
}
