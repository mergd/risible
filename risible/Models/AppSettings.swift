//
//  AppSettings.swift
//  risible
//
//  Created by William on 10/25/25.
//

import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let lastOpenedDate = "lastOpenedDate"
        static let defaultRefreshInterval = "defaultRefreshInterval"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
    
    var lastOpenedDate: Date? {
        get {
            defaults.object(forKey: Keys.lastOpenedDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: Keys.lastOpenedDate)
        }
    }
    
    var defaultRefreshInterval: TimeInterval {
        get {
            let value = defaults.double(forKey: Keys.defaultRefreshInterval)
            return value > 0 ? value : 3600
        }
        set {
            defaults.set(newValue, forKey: Keys.defaultRefreshInterval)
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }
    
    private init() {}
    
    func updateLastOpenedDate() {
        lastOpenedDate = Date()
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
