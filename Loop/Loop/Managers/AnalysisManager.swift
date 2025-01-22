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
    
    private func calculateQuantitativeMetrics(_ transcript: String) -> QuantitativeMetrics {
        let totalWords = transcript.split(separator: " ").count
        
        let totalDuration = getDuration(for: transcript)
        
        let count = 1
        print("[AnalysisManager] Quantitative metrics calculated - Words: \(totalWords), Duration: \(totalDuration)s")
        
        return QuantitativeMetrics(
            totalWordCount: totalWords,
            totalDurationSeconds: totalDuration,
            averageWordsPerRecording: Double(totalWords),
            averageDurationPerRecording: totalDuration
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
    
    private func getDuration(for transcript: String) -> Double {
        print("[AnalysisManager] Getting duration for response")
        return 0.0
    }
    
    
    func performAnalysisForUnguidedEntry(transcript: String) {
        let metrics = calculateQuantitativeMetrics(transcript)
        let today = Calendar.current.startOfDay(for: Date()) // Get the start of the current day

        print("[AnalysisManager] Starting to update metrics in Core Data")

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        fetchRequest.fetchLimit = 1

        do {
            if let existingMetrics = try context.fetch(fetchRequest).first {
                // Update existing metrics
                let currentWords = existingMetrics.value(forKey: "totalWords") as? Int ?? 0
                let currentDuration = existingMetrics.value(forKey: "totalDuration") as? Double ?? 0
                let currentEntryCount = existingMetrics.value(forKey: "entryCount") as? Int ?? 0

                existingMetrics.setValue(currentWords + metrics.totalWordCount, forKey: "totalWords")
                existingMetrics.setValue(currentDuration + metrics.totalDurationSeconds, forKey: "totalDuration")
                existingMetrics.setValue(currentEntryCount + 1, forKey: "entryCount")

                try context.save()
                print("[AnalysisManager] ✅ Successfully updated metrics in Core Data")
            } else {
                // Create new metrics for today
                guard let dayMetricsEntity = NSEntityDescription.entity(forEntityName: "DayMetricsEntity", in: context) else {
                    print("[AnalysisManager] 🚨 Failed to get DayMetrics entity description")
                    return
                }

                let newMetrics = NSManagedObject(entity: dayMetricsEntity, insertInto: context)
                newMetrics.setValue(today, forKey: "date")
                newMetrics.setValue(metrics.totalWordCount, forKey: "totalWords")
                newMetrics.setValue(metrics.totalDurationSeconds, forKey: "totalDuration")
                newMetrics.setValue(1, forKey: "entryCount")

                try context.save()
                print("[AnalysisManager] ✅ Successfully created new metrics in Core Data")
            }
        } catch {
            print("[AnalysisManager] 🚨 Failed to update metrics in Core Data: \(error)")
        }
    }

    func saveDayMetricsToCoreData(analysis: DailyAnalysis) {
        let today = Calendar.current.startOfDay(for: Date())
        print("[AnalysisManager] Starting to save metrics to Core Data")

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
        fetchRequest.predicate = NSPredicate(format: "date == %@", today as NSDate)
        fetchRequest.fetchLimit = 1

        do {
            if let existingMetrics = try context.fetch(fetchRequest).first {
                // Update existing metrics
                existingMetrics.setValue(analysis.aiAnalysis.moodData?.rating, forKey: "moodRating")
                existingMetrics.setValue(analysis.aiAnalysis.sleepData?.hours, forKey: "sleepHours")
                existingMetrics.setValue(analysis.quantitativeMetrics.totalWordCount, forKey: "totalWords")
                existingMetrics.setValue(analysis.quantitativeMetrics.totalDurationSeconds, forKey: "totalDuration")
                existingMetrics.setValue(analysis.aiAnalysis.fillerAnalysis.totalCount, forKey: "fillerWordCount")
                existingMetrics.setValue(Date(), forKey: "timeOfEntry")
                existingMetrics.setValue(!ReflectionSessionManager.shared.getTodaysCachedResponses().isEmpty, forKey: "isCompleted")
                existingMetrics.setValue(ReflectionSessionManager.shared.getTodaysCachedResponses().count, forKey: "entryCount")
                
                // Add recurring themes if they exist
                if let themes = analysis.aiAnalysis.recurringThemes?.themes {
                    existingMetrics.setValue(themes.joined(separator: ","), forKey: "recurringThemes")
                }
                
                // Save key moments
                saveKeyMoments(analysis: analysis)
                
                try context.save()
                print("[AnalysisManager] ✅ Successfully updated metrics in Core Data")
            } else {
                // Create new metrics for today
                guard let dayMetricsEntity = NSEntityDescription.entity(forEntityName: "DayMetricsEntity", in: context) else {
                    print("[AnalysisManager] 🚨 Failed to get DayMetrics entity description")
                    return
                }

                let metrics = NSManagedObject(entity: dayMetricsEntity, insertInto: context)
                let responses = ReflectionSessionManager.shared.getTodaysCachedResponses()

                metrics.setValue(today, forKey: "date")
                metrics.setValue(analysis.aiAnalysis.moodData?.rating, forKey: "moodRating")
                metrics.setValue(analysis.aiAnalysis.sleepData?.hours, forKey: "sleepHours")
                metrics.setValue(analysis.quantitativeMetrics.totalWordCount, forKey: "totalWords")
                metrics.setValue(analysis.quantitativeMetrics.totalDurationSeconds, forKey: "totalDuration")
                metrics.setValue(analysis.aiAnalysis.fillerAnalysis.totalCount, forKey: "fillerWordCount")
                metrics.setValue(Date(), forKey: "timeOfEntry")
                metrics.setValue(!responses.isEmpty, forKey: "isCompleted")
                metrics.setValue(responses.count, forKey: "entryCount")
                
                // Add recurring themes if they exist
                if let themes = analysis.aiAnalysis.recurringThemes?.themes {
                    metrics.setValue(themes.joined(separator: ","), forKey: "recurringThemes")
                }
                
                // Save key moments
                saveKeyMoments(analysis: analysis)
                
                try context.save()
                print("[AnalysisManager] ✅ Successfully created new metrics in Core Data")
            }
        } catch {
            print("[AnalysisManager] 🚨 Failed to save or update metrics in Core Data: \(error)")
        }
    }

    private func saveKeyMoments(analysis: DailyAnalysis) {
        guard let momentEntity = NSEntityDescription.entity(forEntityName: "KeyMomentEntity", in: context) else {
            print("[AnalysisManager] 🚨 Failed to get KeyMoment entity description")
            return
        }
        
        // Save standout moment if exists
        if let standoutAnalysis = analysis.aiAnalysis.standoutAnalysis,
           let keyMoment = standoutAnalysis.keyMoment {
            let standoutMoment = NSManagedObject(entity: momentEntity, insertInto: context)
            standoutMoment.setValue(Date(), forKey: "date")
            standoutMoment.setValue(keyMoment, forKey: "content")
            standoutMoment.setValue(analysis.aiAnalysis.moodData?.rating, forKey: "associatedMood")
            standoutMoment.setValue(standoutAnalysis.category?.rawValue, forKey: "category")
            standoutMoment.setValue(standoutAnalysis.sentiment?.rawValue, forKey: "sentiment")
            standoutMoment.setValue("standout", forKey: "momentType")
        }
        
        // Save additional moments if they exist
        if let additionalMoments = analysis.aiAnalysis.additionalKeyMoments?.moments {
            for moment in additionalMoments {
                let additionalMoment = NSManagedObject(entity: momentEntity, insertInto: context)
                additionalMoment.setValue(Date(), forKey: "date")
                additionalMoment.setValue(moment.keyMoment, forKey: "content")
                additionalMoment.setValue(analysis.aiAnalysis.moodData?.rating, forKey: "associatedMood")
                additionalMoment.setValue(moment.category.rawValue, forKey: "category")
                additionalMoment.setValue(moment.sourceType.rawValue, forKey: "sourceType")
                additionalMoment.setValue("additional", forKey: "momentType")
            }
        }
    }
    
    func markFollowUpComplete() {
        isFollowUpCompletedToday = true
        UserDefaults.standard.set(true, forKey: "FollowUpCompletedToday")
    }
}
