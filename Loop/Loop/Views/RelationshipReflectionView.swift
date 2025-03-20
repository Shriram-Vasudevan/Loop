//
//  RelationshipReflectionView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/17/25.
//

import SwiftUI
import AVKit

struct RelationshipReflection: Identifiable, Codable {
    let id: String
    let relationshipName: String
    let relationshipType: RelationshipType
    let lastReflectionDate: Date?
    let reflectionCount: Int
    var insightSummary: String?
    var strengthsNoted: [String]
    var challengesNoted: [String]
    var priorities: [String]
}

enum RelationshipType: String, Codable, CaseIterable, Identifiable {
    case romantic = "Romantic"
    case family = "Family"
    case friendship = "Friendship"
    case professional = "Professional"
    case selfRelationship = "Self"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .romantic: return "heart.fill"
        case .family: return "house.fill"
        case .friendship: return "person.2.fill"
        case .professional: return "briefcase.fill"
        case .selfRelationship: return "person.fill"
        case .other: return "circle.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .romantic: return Color(hex: "B784A7")
        case .family: return Color(hex: "94A7B7")
        case .friendship: return Color(hex: "A28497")
        case .professional: return Color(hex: "B7A284")
        case .selfRelationship: return Color(hex: "8497A2")
        case .other: return Color(hex: "A7B784")
        }
    }
}

enum RelationshipPromptCategory: String, CaseIterable {
    case connection = "Connection"
    case boundaries = "Boundaries"
    case communication = "Communication"
    case expectations = "Expectations"
    case appreciation = "Appreciation"
    case challenges = "Challenges"
    case growth = "Growth"
    
    var prompts: [String] {
        switch self {
        case .connection:
            return [
                "How connected do you feel to this person right now?",
                "What moments have brought you closer recently?",
                "What activities or conversations deepen your connection?",
                "When do you feel most understood by this person?"
            ]
        case .boundaries:
            return [
                "Are there any boundaries you need to establish or reinforce?",
                "How do you feel when sharing difficult feelings with this person?",
                "What areas of this relationship feel balanced or imbalanced?",
                "Are there expectations that feel uncomfortable to meet?"
            ]
        case .communication:
            return [
                "How would you describe your communication patterns?",
                "What goes unsaid that might need expressing?",
                "When conflicts arise, how do you typically resolve them?",
                "What communication style helps you feel heard by this person?"
            ]
        case .expectations:
            return [
                "What unspoken expectations might exist in this relationship?",
                "Are your needs being met in this relationship?",
                "What assumptions might you be making about the other person's needs?",
                "How aligned are your values and priorities?"
            ]
        case .appreciation:
            return [
                "What qualities do you most appreciate about this person?",
                "What recent actions have you appreciated but not expressed?",
                "How does this relationship enhance your life?",
                "What strengths does this person bring out in you?"
            ]
        case .challenges:
            return [
                "What recurring challenges do you face in this relationship?",
                "Is there a pattern that feels difficult to break?",
                "What triggers tension or distance between you?",
                "What might be preventing deeper understanding?"
            ]
        case .growth:
            return [
                "How has this relationship evolved over time?",
                "What would you like to strengthen in this relationship?",
                "What have you learned about yourself through this relationship?",
                "What small step could improve this relationship?"
            ]
        }
    }
}

// MARK: - Manager

class RelationshipReflectionManager: ObservableObject {
    static let shared = RelationshipReflectionManager()
    
    @Published var relationships: [RelationshipReflection] = []
    @Published var selectedRelationship: RelationshipReflection?
    @Published var selectedPromptCategory: RelationshipPromptCategory = .connection
    @Published var currentPrompt: String = ""
    @Published var isLoading = false
    @Published var newRelationshipName = ""
    @Published var newRelationshipType: RelationshipType = .friendship
    @Published var showingNewRelationship = false
    
    private let premiumManager = PremiumManager.shared
    private let loopManager = LoopManager.shared
    
    private init() {
        loadSampleData()
    }
    
    func loadSampleData() {
        relationships = [
            RelationshipReflection(
                id: UUID().uuidString,
                relationshipName: "Alex",
                relationshipType: .romantic,
                lastReflectionDate: Date().addingTimeInterval(-60*60*24*3),
                reflectionCount: 5,
                insightSummary: "Communication has improved over time. Quality time is important.",
                strengthsNoted: ["Supportive during challenges", "Great listener", "Shared interests"],
                challengesNoted: ["Different communication styles", "Scheduling time together"],
                priorities: ["Weekly date nights", "More open conversations"]
            ),
            RelationshipReflection(
                id: UUID().uuidString,
                relationshipName: "Mom",
                relationshipType: .family,
                lastReflectionDate: Date().addingTimeInterval(-60*60*24*7),
                reflectionCount: 3,
                insightSummary: "Strong bond with occasional boundary issues.",
                strengthsNoted: ["Unconditional support", "Honesty"],
                challengesNoted: ["Respecting adult boundaries", "Different perspectives"],
                priorities: ["Regular calls", "Setting clearer boundaries"]
            ),
            RelationshipReflection(
                id: UUID().uuidString,
                relationshipName: "Jamie",
                relationshipType: .friendship,
                lastReflectionDate: Date().addingTimeInterval(-60*60*24*14),
                reflectionCount: 2,
                insightSummary: "Long-term friendship that needs more attention.",
                strengthsNoted: ["History of trust", "Similar values"],
                challengesNoted: ["Distance makes connection harder"],
                priorities: ["Monthly video calls", "Plan a visit"]
            ),
            RelationshipReflection(
                id: UUID().uuidString,
                relationshipName: "Myself",
                relationshipType: .selfRelationship,
                lastReflectionDate: Date().addingTimeInterval(-60*60*24),
                reflectionCount: 7,
                insightSummary: "Working on self-compassion and boundaries.",
                strengthsNoted: ["Self-awareness", "Resilience"],
                challengesNoted: ["Inner critic", "Perfectionism"],
                priorities: ["Daily self-care", "Mindfulness practice"]
            )
        ]
    }
    
    func selectRandomPrompt() {
        let prompts = selectedPromptCategory.prompts
        if let prompt = prompts.randomElement() {
            currentPrompt = prompt
        }
    }
    
    func addNewRelationship() {
        guard !newRelationshipName.isEmpty else { return }
        
        let newRelationship = RelationshipReflection(
            id: UUID().uuidString,
            relationshipName: newRelationshipName,
            relationshipType: newRelationshipType,
            lastReflectionDate: nil,
            reflectionCount: 0,
            insightSummary: nil,
            strengthsNoted: [],
            challengesNoted: [],
            priorities: []
        )
        
        relationships.append(newRelationship)
        newRelationshipName = ""
        showingNewRelationship = false
    }
    
    func isPremiumFeature() -> Bool {
        return !premiumManager.isUserPremium()
    }
}

// MARK: - Views

struct RelationshipReflectionListView: View {
    @ObservedObject private var relationshipManager = RelationshipReflectionManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var showingPremiumUpgrade = false
    @State private var showingNewRelationship = false
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            if relationshipManager.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if !premiumManager.isUserPremium() {
//                premiumUpgradeView
                Text("Text")
            } else {
                mainContentView
            }
        }
        .navigationTitle("Relationship Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewRelationship) {
            newRelationshipSheet
        }
        .toolbar {
            if premiumManager.isUserPremium() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewRelationship = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(relationshipManager.relationships) { relationship in
                    NavigationLink(destination: RelationshipDetailView(relationship: relationship)) {
                        relationshipCard(relationship)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: {
                    showingNewRelationship = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Relationship")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(accentColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor, lineWidth: 1)
                            .background(Color.white.cornerRadius(12))
                    )
                }
            }
            .padding(20)
        }
    }
    
    private func relationshipCard(_ relationship: RelationshipReflection) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: relationship.relationshipType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(relationship.relationshipType.accentColor)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(relationship.relationshipName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text(relationship.relationshipType.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(accentColor.opacity(0.5))
            }
            
            // Stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflections")
                        .font(.system(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                        .textCase(.uppercase)
                    
                    Text("\(relationship.reflectionCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last reflection")
                        .font(.system(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                        .textCase(.uppercase)
                    
                    Text(relationship.lastReflectionDate != nil ? timeAgoString(from: relationship.lastReflectionDate!) : "Never")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            
            // Insights preview
            if let summary = relationship.insightSummary {
                Text(summary)
                    .font(.system(size: 15))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
    }

    
    private var newRelationshipSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Relationship Details")) {
                    TextField("Name", text: $relationshipManager.newRelationshipName)
                    
                    Picker("Type", selection: $relationshipManager.newRelationshipType) {
                        ForEach(RelationshipType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.accentColor)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
            }
            .navigationTitle("New Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingNewRelationship = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        relationshipManager.addNewRelationship()
                    }
                    .disabled(relationshipManager.newRelationshipName.isEmpty)
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

struct RelationshipDetailView: View {
    let relationship: RelationshipReflection
    @ObservedObject private var relationshipManager = RelationshipReflectionManager.shared
    @State private var showingReflectionPrompt = false
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                relationshipHeader
                
                // Reflections
                reflectionsSection
                
                // Insights
                insightsSection
                
                // Strengths & Challenges
                notesSection
                
                // Priorities
                prioritiesSection
            }
            .padding(20)
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle(relationship.relationshipName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingReflectionPrompt = true
                }) {
                    Text("Reflect")
                        .foregroundColor(relationship.relationshipType.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingReflectionPrompt) {
            RelationshipPromptView(relationship: relationship)
        }
    }
    
    private var relationshipHeader: some View {
        VStack(spacing: 16) {
            // Icon and type
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: relationship.relationshipType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(relationship.relationshipType.accentColor)
                        .cornerRadius(16)
                    
                    Text(relationship.relationshipType.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Spacer()
            }
            
            // Stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(relationship.reflectionCount)")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(relationship.relationshipType.accentColor)
                    
                    Text("Reflections")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.7))
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text(relationship.lastReflectionDate != nil ? formattedDate(relationship.lastReflectionDate!) : "Never")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Last reflection")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var reflectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Recent Reflections")
            
            if relationship.reflectionCount == 0 {
                emptyStateView(
                    icon: "square.and.pencil",
                    message: "No reflections yet. Tap 'Reflect' to start your first entry."
                )
            } else {
                reflectionEntry(
                    date: Date().addingTimeInterval(-60*60*24*3),
                    category: "Communication",
                    excerpt: "We had a good conversation about future plans."
                )
                
                if relationship.reflectionCount > 1 {
                    reflectionEntry(
                        date: Date().addingTimeInterval(-60*60*24*10),
                        category: "Boundaries",
                        excerpt: "Discussed how we can better respect each other's time."
                    )
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Insights")
            
            if let summary = relationship.insightSummary {
                Text(summary)
                    .font(.system(size: 16))
                    .foregroundColor(textColor.opacity(0.8))
                    .lineSpacing(4)
            } else {
                emptyStateView(
                    icon: "lightbulb",
                    message: "Insights will appear after multiple reflections."
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Strengths & Challenges")
            
            if relationship.strengthsNoted.isEmpty && relationship.challengesNoted.isEmpty {
                emptyStateView(
                    icon: "list.bullet",
                    message: "Strengths and challenges will be noted during reflections."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strengths")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                    
                    if relationship.strengthsNoted.isEmpty {
                        Text("None noted yet")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.6))
                            .italic()
                    } else {
                        ForEach(relationship.strengthsNoted, id: \.self) { strength in
                            bulletPoint(strength)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Challenges")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                    
                    if relationship.challengesNoted.isEmpty {
                        Text("None noted yet")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.6))
                            .italic()
                    } else {
                        ForEach(relationship.challengesNoted, id: \.self) { challenge in
                            bulletPoint(challenge)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var prioritiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Priorities & Actions")
            
            if relationship.priorities.isEmpty {
                emptyStateView(
                    icon: "star",
                    message: "Set priorities during reflections."
                )
            } else {
                ForEach(relationship.priorities, id: \.self) { priority in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))
                            .foregroundColor(relationship.relationshipType.accentColor)
                        
                        Text(priority)
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                            .lineSpacing(4)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // Helper views
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
            
            Spacer()
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(relationship.relationshipType.accentColor)
                .padding(.top, 8)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(textColor.opacity(0.8))
            
            Spacer()
        }
    }
    
    private func reflectionEntry(date: Date, category: String, excerpt: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedDate(date))
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
                
                Text(category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(relationship.relationshipType.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(relationship.relationshipType.accentColor.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text(excerpt)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .lineSpacing(4)
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    Text("View")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(relationship.relationshipType.accentColor)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "F9F9F9"))
        .cornerRadius(8)
    }
    
    private func emptyStateView(icon: String, message: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(relationship.relationshipType.accentColor.opacity(0.7))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(textColor.opacity(0.7))
            
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "F9F9F9"))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct RelationshipPromptView: View {
    let relationship: RelationshipReflection
    @ObservedObject private var relationshipManager = RelationshipReflectionManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 60
    @State private var priority = ""
    @State private var currentStep = 0
    
    @Environment(\.dismiss) var dismiss
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            InitialReflectionVisual(index: 1)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
            
            VStack(spacing: 0) {
                // Top Bar
                topBar
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)
                
                if isPostRecording {
                    postRecordingView
                } else {
                    // Content based on step
                    TabView(selection: $currentStep) {
                        categorySelectionView
                            .tag(0)
                        
                        promptView
                            .tag(1)
                        
                        priorityView
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
        }
        .onAppear {
            audioManager.cleanup()
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("\(relationship.relationshipName) Reflection")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(relationship.relationshipType.accentColor.opacity(0.8))
                    }
                    
                    Spacer()
                }
            }
            
            // Progress indicator
            if !isPostRecording {
                ProgressIndicator(
                    totalSteps: 3,
                    currentStep: currentStep,
                    accentColor: relationship.relationshipType.accentColor
                )
            }
        }
        .padding(.top, 16)
    }
    
    private var categorySelectionView: some View {
        VStack(spacing: 24) {
            Text("What aspect would you like to reflect on?")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(RelationshipPromptCategory.allCases, id: \.self) { category in
                        Button(action: {
                            relationshipManager.selectedPromptCategory = category
                            relationshipManager.selectRandomPrompt()
                            withAnimation {
                                currentStep = 1
                            }
                        }) {
                            HStack {
                                Text(category.rawValue)
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(relationship.relationshipType.accentColor.opacity(0.7))
                            }
                            .padding(16)
                            .background(Color(hex: "F9F9F9"))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 24)
                    }
                    
    private var promptView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(relationshipManager.currentPrompt)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                
                Button(action: {
                    relationshipManager.selectRandomPrompt()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Try another prompt")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(relationship.relationshipType.accentColor)
                }
            }
            
            Spacer()
            
            if isRecording {
                HStack(spacing: 12) {
                    PulsingDot()
                    Text("\(timeRemaining)s")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundColor(relationship.relationshipType.accentColor)
                }
                .transition(.opacity)
            }
            
            recordingButton
                .padding(.bottom, 40)
                .padding(.horizontal, 24)
        }
        .padding(.top, 24)
    }
    
    private var priorityView: some View {
        VStack(spacing: 24) {
            Text("What's one priority or action for this relationship?")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            TextField("Enter a priority...", text: $priority)
                .font(.system(size: 17))
                .padding()
                .background(Color(hex: "F9F9F9"))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                completeReflection()
            }) {
                Text("Complete Reflection")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(relationship.relationshipType.accentColor)
                    .cornerRadius(12)
            }
            .disabled(priority.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .padding(.top, 24)
    }
    
    private var recordingButton: some View {
        VStack {
            Button(action: {
                toggleRecording()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 96)
                        .shadow(color: relationship.relationshipType.accentColor.opacity(0.2), radius: 20, x: 0, y: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isRecording ? relationship.relationshipType.accentColor : .white,
                                    isRecording ? relationship.relationshipType.accentColor.opacity(0.9) : .white
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    if isRecording {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 26, height: 26)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        relationship.relationshipType.accentColor,
                                        relationship.relationshipType.accentColor.opacity(0.85)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 74)
                    }
                    
                    if isRecording {
                        PulsingRing(color: relationship.relationshipType.accentColor)
                    }
                }
                .scaleEffect(isRecording ? 1.08 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
            }
            
            if !isRecording {
                Button(action: {
                    withAnimation {
                        currentStep = currentStep < 2 ? currentStep + 1 : 0
                    }
                }) {
                    Text(currentStep < 2 ? "Skip Recording" : "Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(relationship.relationshipType.accentColor.opacity(0.8))
                        .padding(.top, 16)
                }
            }
        }
    }
    
    private var postRecordingView: some View {
        RelationshipLoopAudioConfirmationView(
            audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
            waveformData: generateRandomWaveform(count: 40),
            onComplete: {
                withAnimation {
                    isPostRecording = false
                    if currentStep < 2 {
                        currentStep += 1
                    } else {
                        completeReflection()
                    }
                }
            },
            onRetry: { retryRecording() },
            isReadOnly: false,
            accentColor: relationship.relationshipType.accentColor,
            textColor: textColor
        )
        .padding(.horizontal, 24)
    }
    
    private func toggleRecording() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isRecording.toggle()
            
            if !isRecording {
                audioManager.stopRecording()
                stopTimer()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPostRecording = true
                }
            } else {
                startRecordingWithTimer()
            }
        }
    }
    
    private func startRecordingWithTimer() {
        try? audioManager.prepareForNewRecording()
        audioManager.startRecording()
        timeRemaining = 60
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                audioManager.stopRecording()
                isPostRecording = true
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func retryRecording() {
        audioManager.cleanup()
        isPostRecording = false
        isRecording = false
        timeRemaining = 60
    }
    
    private func completeReflection() {
        // Save priority if entered
        if !priority.isEmpty {
            // In a real implementation, this would update the relationship
            print("Priority saved: \(priority)")
        }
        
        // Save audio if recorded
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            Task {
                do {
                    try await LoopManager.shared.addLoop(
                        mediaURL: audioFileURL,
                        isVideo: false,
                        prompt: relationshipManager.currentPrompt,
                        mood: nil,
                        freeResponse: false,
                        isDailyLoop: false,
                        isFollowUp: false,
                        isSuccess: false,
                        isUnguided: false,
                        isDream: false,
                        isMorningJournal: false
                    )
                } catch {
                    print("Error saving relationship reflection: \(error)")
                }
            }
        }
        
        dismiss()
    }
    
    private func generateRandomWaveform(count: Int, minHeight: CGFloat = 12, maxHeight: CGFloat = 64) -> [CGFloat] {
        return (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

struct RelationshipLoopAudioConfirmationView: View {
    let audioURL: URL
    let waveformData: [CGFloat]
    let onComplete: () -> Void
    let onRetry: () -> Void
    let isReadOnly: Bool
    
    let accentColor: Color
    let textColor: Color
    
    @State private var isWaveformVisible = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Waveform visualization
            HStack(spacing: 3) {
                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accentColor.opacity(0.8))
                        .frame(width: 2, height: isWaveformVisible ? height : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.015),
                            value: isWaveformVisible
                        )
                }
            }
            .frame(height: 64)
            .padding(.bottom, 12)
            
            // Playback controls
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 65)
                        .shadow(color: accentColor.opacity(0.15), radius: 15, x: 0, y: 6)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 25))
                        .foregroundColor(accentColor)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Text("Save Reflection")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accentColor)
                        )
                }
                
                if !isReadOnly {
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .onAppear {
            setupAudioPlayer()
            withAnimation { isWaveformVisible = true }
        }
        .onDisappear(perform: cleanup)
    }
    
    private func setupAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func cleanup() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}


//
//#Preview {
//    RelationshipPromptView(relationship: <#RelationshipReflection#>)
//}
