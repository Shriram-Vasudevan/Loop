//
//  LoopComparison.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation

struct LoopComparison: Codable {
    let date: Date
    let pastLoopDate: Date
    
    let durationComparison: MetricComparison
    
    let wpmComparison: MetricComparison
    let wordCountComparison: MetricComparison
    
    let uniqueWordComparison: MetricComparison
    let vocabularyDiversityComparison: MetricComparison
    let averageWordLengthComparison: MetricComparison
    
    let selfReferenceComparison: MetricComparison
    
    let similarityScore: Double
    let commonWords: [String]
}


enum ComparisonDirection: String, Codable {
    case increase
    case decrease
    case same
}

