//
//  FirstLaunchManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/15/24.
//

import Foundation
import AVFoundation
import CloudKit

class FirstLaunchManager {
    private let hasLaunchedKey = "hasLaunchedBefore"
    
    static let shared = FirstLaunchManager()
    
    private init() {}
    
    var isFirstLaunch: Bool {
        get {
            return !UserDefaults.standard.bool(forKey: hasLaunchedKey)
        }
        set {
            UserDefaults.standard.set(!newValue, forKey: hasLaunchedKey)
        }
    }
    
    func useIntroView() async -> Bool {
        if let userName = UserDefaults.standard.string(forKey: "userName"), !userName.isEmpty {
            return false
        }
        
        if let _ = try? await UserCloudKitUtility.getCurrentUserData() {
            return false
        }
        
        return isFirstLaunch
    }
    
    func markAsLaunched() {
        isFirstLaunch = false
    }
    
    func requestVideoAndAudioPermissions(completion: @escaping (Bool) -> Void) {
        let videoPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)

        if videoPermission == .authorized && audioPermission == .authorized {
            completion(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        completion(granted)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }

    func checkiCloudAccountStatus(completion: @escaping (CKAccountStatus) -> Void) {
        CKContainer.default().accountStatus { accountStatus, error in
            if let error = error {
                print("Error checking iCloud account status: \(error.localizedDescription)")
            }
            completion(accountStatus)
        }
    }
}
