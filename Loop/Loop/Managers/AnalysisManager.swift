//
//  AnalysisManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/18/24.
//

import Foundation
import AVFoundation
import Speech
import NaturalLanguage
import Combine
import CoreData
import SwiftUI

class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
    
    @Published private(set) var analysisState: AnalysisState = .notStarted
    @Published var currentDailyAnalysis: DailyAnalysis?
    
    @Published private(set) var isFollowUpCompletedToday: Bool = false
    
    private let dailyAnalysisKey = "DailyAnalysisStore"
        
    lazy var persistentContainer: NSPersistentContainer = {
        print("[AnalysisManager] Initializing persistent container")
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("[AnalysisManager] 🚨 Fatal error loading persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("[AnalysisManager] ✅ Successfully loaded persistent stores")
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        print("[AnalysisManager] Accessing managed object context")
        return persistentContainer.viewContext
    }
    
    init() {
        print("[AnalysisManager] Initializing AnalysisManager")
        loadTodaysAnalysis()
        isFollowUpCompletedToday = UserDefaults.standard.bool(forKey: "FollowUpCompletedToday")
    }
    
    func performAnalysis() async {
        print("[AnalysisManager] Starting analysis process")
        await MainActor.run {
            print("[AnalysisManager] Setting state to retrievingResponses")
            analysisState = .retrievingResponses
        }
        
        let responses = ReflectionSessionManager.shared.getTodaysCachedResponses()
        print("[AnalysisManager] Retrieved \(responses.count) responses for analysis")
        
        guard !responses.isEmpty else {
            print("[AnalysisManager] ⚠️ No responses found for analysis")
            await MainActor.run {
                analysisState = .failed(.noResponses)
            }
            return
        }
        
        do {
            await MainActor.run {
                print("[AnalysisManager] Starting quantitative analysis")
                analysisState = .analyzingQuantitative
            }

            async let quantitativeMetrics = calculateQuantitativeMetrics(responses)

            await MainActor.run {
                print("[AnalysisManager] Starting AI analysis")
                analysisState = .analyzingAI
            }
            
            async let aiAnalysis = AIAnalyzer.shared.analyzeResponses()
            
            let (metrics, analysis) = try await (quantitativeMetrics, aiAnalysis)
            print("[AnalysisManager] ✅ Completed both quantitative and AI analysis")
            
            let dailyAnalysis = DailyAnalysis(
                date: Date(),
                quantitativeMetrics: metrics,
                aiAnalysis: analysis
            )
            
            await MainActor.run {
                print("[AnalysisManager] Saving analysis results")
                self.currentDailyAnalysis = dailyAnalysis
                self.analysisState = .completed(dailyAnalysis)
                saveDailyAnalysis(dailyAnalysis)
                saveDayMetricsToCoreData(analysis: dailyAnalysis)
            }
            
        } catch {
            print("[AnalysisManager] 🚨 Analysis failed with error: \(error)")
            await MainActor.run {
                self.analysisState = .failed(.analysisError(error))
            }
        }
    }
    
    private func calculateQuantitativeMetrics(_ responses: [ReflectionSessionManager.CachedResponse]) -> QuantitativeMetrics {
        print("[AnalysisManager] Calculating quantitative metrics for \(responses.count) responses")
        let totalWords = responses.reduce(0) { total, response in
            total + response.transcript.split(separator: " ").count
        }

        let totalDuration = responses.reduce(0.0) { total, response in
            total + getDuration(for: response)
        }
        
        let count = Double(responses.count)
        print("[AnalysisManager] Quantitative metrics calculated - Words: \(totalWords), Duration: \(totalDuration)s")
        
        return QuantitativeMetrics(
            totalWordCount: totalWords,
            totalDurationSeconds: totalDuration,
            averageWordsPerRecording: Double(totalWords) / count,
            averageDurationPerRecording: totalDuration / count
        )
    }
    
    private func loadTodaysAnalysis() {
        print("[AnalysisManager] Attempting to load today's analysis")
        guard let data = UserDefaults.standard.data(forKey: dailyAnalysisKey),
              let analysis = try? JSONDecoder().decode(DailyAnalysis.self, from: data),
              Calendar.current.isDateInToday(analysis.date) else {
            print("[AnalysisManager] ⚠️ No valid analysis found for today")
            return
        }
        
        print("[AnalysisManager] ✅ Successfully loaded today's analysis")
        self.analysisState = .completed(analysis)
        currentDailyAnalysis = analysis
    }
    
    private func saveDailyAnalysis(_ analysis: DailyAnalysis) {
        print("[AnalysisManager] Attempting to save daily analysis")
        if let encoded = try? JSONEncoder().encode(analysis) {
            UserDefaults.standard.set(encoded, forKey: dailyAnalysisKey)
            print("[AnalysisManager] ✅ Successfully saved daily analysis to UserDefaults")
        } else {
            print("[AnalysisManager] 🚨 Failed to encode and save daily analysis")
        }
    }
    
    private func getDuration(for response: ReflectionSessionManager.CachedResponse) -> Double {
        print("[AnalysisManager] Getting duration for response")
        return 0.0
    }
    
    func saveDayMetricsToCoreData(analysis: DailyAnalysis) {
        print("[AnalysisManager] Starting to save metrics to Core Data")
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "MetricDayEntity", in: context) else {
            print("[AnalysisManager] 🚨 Failed to get MetricDayEntity description")
            return
        }
        
        let metricDay = NSManagedObject(entity: entityDescription, insertInto: context)
        print("[AnalysisManager] Created new MetricDayEntity")
        
        metricDay.setValue(analysis.date, forKey: "date")
        metricDay.setValue(Int(analysis.quantitativeMetrics.totalWordCount), forKey: "totalWords")
        metricDay.setValue(analysis.quantitativeMetrics.totalDurationSeconds, forKey: "recordingSeconds")
        metricDay.setValue(Double(analysis.quantitativeMetrics.totalWordCount) / (analysis.quantitativeMetrics.totalDurationSeconds / 60.0), forKey: "wordsPerMinute")
        metricDay.setValue(Double(analysis.aiAnalysis.mood.rating ?? -1.0), forKey: "moodRating")
        metricDay.setValue(Int(analysis.aiAnalysis.mood.sleep ?? -1), forKey: "sleepRating")
        metricDay.setValue(analysis.aiAnalysis.expression.topics.first?.rawValue, forKey: "primaryTopic")
        print("[AnalysisManager] Set all metric values for MetricDayEntity")
        
        saveNotableElementsToCoreData(analysis.aiAnalysis.notableElements, context: context, mood: analysis.aiAnalysis.mood.rating ?? -1.0)
                
        do {
            try context.save()
            print("[AnalysisManager] ✅ Successfully saved all metrics to Core Data")
        } catch {
            print("[AnalysisManager] 🚨 Failed to save metrics to Core Data: \(error)")
        }
    }
    
    private func saveNotableElementsToCoreData(_ elements: [NotableElement], context: NSManagedObjectContext, mood: Double) {
        guard let momentEntity = NSEntityDescription.entity(forEntityName: "SignificantMomentEntity", in: context) else {
            print("[AnalysisManager] 🚨 Failed to get SignificantMoment entity description")
            return
        }
        
        elements.forEach { element in
            print("The content: \(element.content) and type \(element.type)")
            let moment = NSManagedObject(entity: momentEntity, insertInto: context)
            moment.setValue(Date(), forKey: "date")
            moment.setValue(element.content, forKey: "content")
            moment.setValue(element.type.rawValue, forKey: "momentType")
            moment.setValue(Double(mood), forKey: "associatedMood")
            moment.setValue(element.type.rawValue, forKey: "topic")
            moment.setValue(element.type == .win, forKey: "isWin")
            print("[AnalysisManager] Saved notable element of type: \(element.type.rawValue)")
        }
        print("[AnalysisManager] ✅ Completed saving all notable elements")
    }
    
    func markFollowUpComplete() {
        isFollowUpCompletedToday = true
        UserDefaults.standard.set(true, forKey: "FollowUpCompletedToday")
    }
}
