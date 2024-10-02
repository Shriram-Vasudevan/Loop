//
//  LoopManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit

class LoopManager: ObservableObject {
    static let shared = LoopManager()
    
    @Published var loopRevealDate: Date?
    @Published var retrieveUserLoops: Bool = false
    
    init() {
        getLoopRevealDate()
    }
    
    func getLoopRevealDate() {
        if loopRevealDate == nil {
            print("Fetching loop reveal date...")
            LoopCloudKitUtility.getLoopRevealDate { loopRevealDate in
                if let date = loopRevealDate?.date {
                    print("Received loop reveal date from CloudKit: \(date)")
                    
                    let localRevealDate = Calendar.current.date(byAdding: .second, value: TimeZone.current.secondsFromGMT(), to: date)
                    
                    DispatchQueue.main.sync {
                        self.loopRevealDate = localRevealDate
                        print("Set local reveal date: \(String(describing: self.loopRevealDate))")
                    }
                } else {
                    print("Failed to retrieve loop reveal date.")
                }
            }
        }
    }

    
    func getTodaysLoops() {
        
    }
    
    func addLoop(audioURL: URL, prompt: String) {
        let ckAsset = CKAsset(fileURL: audioURL)
        
        
    }
}
