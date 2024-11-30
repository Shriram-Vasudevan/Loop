//
//  SettingsModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/27/24.
//

import Foundation

import SwiftUI

enum ContactMethod: Identifiable {
    case email(String)
    case phone(String)
    
    var id: String {
        switch self {
        case .email: return "email"
        case .phone: return "phone"
        }
    }
    
    var icon: String {
        switch self {
        case .email: return "envelope"
        case .phone: return "phone"
        }
    }
    
    var title: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        }
    }
    
    var value: String {
        switch self {
        case .email(let email): return email
        case .phone(let phone): return phone
        }
    }
}

struct SettingsRowContent: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    var subtitle: String? = nil
    var isToggle: Bool = false
    var toggleValue: Bool? = nil
    var action: (() -> Void)? = nil
}

struct WebViewData: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}
