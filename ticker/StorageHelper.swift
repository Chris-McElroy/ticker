//
//  StorageHelper.swift
//  ticker
//
//  Created by Chris McElroy on 11/14/22.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase

class Storage: ObservableObject {
    static let main: Storage = Storage()
    
    @Published var projectStart: TimeInterval
    @Published var consumeStart: TimeInterval
    @Published var projectEnd: TimeInterval
    @Published var consumeEnd: TimeInterval
    var projectRatio: Double
    var consumeRatio: Double
    
    var ref: DatabaseReference!
    var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
    
    init() {
        ref = Database.database().reference()
        projectStart = Storage.getDate(of: .projectStart)
        consumeStart = Storage.getDate(of: .consumeStart)
        projectEnd = Storage.getDate(of: .projectEnd)
        consumeEnd = Storage.getDate(of: .consumeEnd)
        projectRatio = Storage.getDouble(for: .projectRatio)
        consumeRatio = Storage.getDouble(for: .consumeRatio)
        
        if projectRatio == 0 { projectRatio = 2.0 }
        if consumeRatio == 0 { consumeRatio = 4.0 }
        
        _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                Storage.set(user.uid, for: .uuid)
                self.myID = user.uid
            } else {
                // should only happen once, when i first use the app
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                        print("Sign in error:", error)
                    }
                }
            }
        }
        _ = ref.observe(DataEventType.value, with: { snapshot in
            if let dict = snapshot.value as? [String: [String: Double]] {
                self.projectRatio = dict[self.myID]?[Key.projectRatio.rawValue] ?? 2.0
                self.consumeRatio = dict[self.myID]?[Key.consumeRatio.rawValue] ?? 4.0
                guard let newDict = dict.first(where: { $0.key != self.myID }) else { return }
                self.setProjectTimes(with: newDict.value)
                self.setConsumeTimes(with: newDict.value)
            }
        })
        
        resetProjectTimer()
        resetConsumeTimer()
    }
    
    func setProjectTimes(with dict: [String: Double]) {
        guard let end = dict[Key.projectEnd.rawValue] else { return }
        if let start = dict[Key.projectStart.rawValue] {
            if start ~> projectStart {
                projectStart = start
                projectEnd = end
                storeProjectDates()
                resetProjectTimer()
            }
        } else if end !~ projectEnd {
            projectEnd = end
            storeDate(of: .projectEnd, projectEnd)
            resetProjectTimer()
        }
    }
    
    func setConsumeTimes(with dict: [String: Double]) {
        guard let end = dict[Key.consumeEnd.rawValue] else { return }
        if let start = dict[Key.consumeStart.rawValue] {
            if start ~> consumeStart {
                consumeStart = start
                consumeEnd = end
                storeConsumeDates()
                resetConsumeTimer()
            }
        } else if end ~< projectEnd {
            projectEnd = end
            storeDate(of: .consumeEnd, consumeEnd)
            resetProjectTimer()
        }
    }
    
    func resetProjectTimer() {
        let start = Date.init(timeIntervalSinceReferenceDate: projectStart)
        let end = Date.init(timeIntervalSinceReferenceDate: projectEnd)
        if Date.now.timeIntervalSinceReferenceDate + 2 <= projectEnd {
            CooldownTimer.projectState = .active
            Storage.set(CooldownTimer.projectState.rawValue, for: .projectTimerState)
            CooldownTimer.project = CooldownTimer(name: "", origin: start, start: start, offset: -projectTime, visible: true, project: true, cooldown: false)
        } else if projectActive || projectCooldown {
            CooldownTimer.projectState = .cooldown
            Storage.set(CooldownTimer.projectState.rawValue, for: .projectTimerState)
            CooldownTimer.project = CooldownTimer(name: "", origin: end, start: end, offset: -projectRatio*projectTime, visible: true, project: true, cooldown: true)
        } else {
            CooldownTimer.projectState = .none
            Storage.set(CooldownTimer.projectState.rawValue, for: .projectTimerState)
            CooldownTimer.project = nil
        }
    }
    
    func resetConsumeTimer() {
        let start = Date.init(timeIntervalSinceReferenceDate: consumeStart)
        let end = Date.init(timeIntervalSinceReferenceDate: consumeEnd)
        if Date.now.timeIntervalSinceReferenceDate + 2 <= consumeEnd {
            CooldownTimer.consumeState = .active
            Storage.set(CooldownTimer.consumeState.rawValue, for: .consumeTimerState)
            CooldownTimer.consume = CooldownTimer(name: "", origin: start, start: start, offset: -consumeTime, visible: true, project: false, cooldown: false)
        } else if consumeActive || consumeCooldown {
            CooldownTimer.consumeState = .cooldown
            Storage.set(CooldownTimer.projectState.rawValue, for: .consumeTimerState)
            CooldownTimer.consume = CooldownTimer(name: "", origin: end, start: end, offset: -consumeRatio*consumeTime, visible: true, project: false, cooldown: true)
        } else {
            CooldownTimer.consumeState = .none
            Storage.set(CooldownTimer.consumeState.rawValue, for: .consumeTimerState)
            CooldownTimer.consume = nil
        }
    }
    
    func storeDate(of key: Key, _ date: TimeInterval) {
        UserDefaults.standard.set(date, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(date)
    }
    
    func storeProjectDates() {
        UserDefaults.standard.set(projectStart, forKey: Key.projectStart.rawValue)
        UserDefaults.standard.set(projectEnd, forKey: Key.projectEnd.rawValue)
        ref.child(myID).child(Key.projectEnd.rawValue).setValue(projectEnd)
        ref.child(myID).child(Key.projectStart.rawValue).setValue(projectStart)
    }
    
    func storeConsumeDates() {
        UserDefaults.standard.set(consumeStart, forKey: Key.consumeStart.rawValue)
        UserDefaults.standard.set(consumeEnd, forKey: Key.consumeEnd.rawValue)
        ref.child(myID).child(Key.consumeEnd.rawValue).setValue(consumeEnd)
        ref.child(myID).child(Key.consumeStart.rawValue).setValue(consumeStart)
    }
    
	static func dictionary(_ key: Key) -> [String: Any]? {
		UserDefaults.standard.dictionary(forKey: key.rawValue)
	}
	
	static func int(_ key: Key) -> Int {
		UserDefaults.standard.integer(forKey: key.rawValue)
	}
	
	static func bool(_ key: Key) -> Bool {
		UserDefaults.standard.bool(forKey: key.rawValue)
	}
	
	static func tickerArray() -> [[String: Any]] {
		UserDefaults.standard.array(forKey: Key.tickers.rawValue) as? [[String: Any]] ?? []
	}
	
	static func string(_ key: Key) -> String? {
		UserDefaults.standard.string(forKey: key.rawValue)
	}
	
	static func set(_ value: Any?, for key: Key) {
		UserDefaults.standard.setValue(value, forKey: key.rawValue)
	}
    
    static func getDate(of key: Key) -> TimeInterval {
        return getDouble(for: key)
    }
    
    static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
    
    
    var projectTime: TimeInterval {
        projectEnd - projectStart
    }
    
    var projectActive: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= projectEnd
    }
    
    var projectCooldownEnd: TimeInterval {
        projectEnd + projectRatio*projectTime
    }
    
    var projectCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > projectEnd && projectCooldownEnd > Date.now.timeIntervalSinceReferenceDate
    }
    
    var consumeTime: TimeInterval {
        consumeEnd - consumeStart
    }
    
    var consumeActive: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= consumeEnd
    }
    
    var consumeCooldownEnd: TimeInterval {
        consumeEnd + consumeRatio*consumeTime
    }
    
    var consumeCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > consumeEnd && consumeCooldownEnd > Date.now.timeIntervalSinceReferenceDate
    }
}

infix operator ~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence
infix operator ~> : ComparisonPrecedence
infix operator ~< : ComparisonPrecedence

extension Double {
    static func ~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) < 0.00001
    }
    
    static func !~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) >= 0.00001
    }
    
    static func ~>(lhs: Double, rhs: Double) -> Bool {
        return lhs > rhs + 0.00001
    }
    
    static func ~<(lhs: Double, rhs: Double) -> Bool {
        return lhs + 0.00001 < rhs
    }
}

enum Key: String {
	case tickers = "tickers"
	case selected = "selected"
	case name = "name"
	case origin = "origin"
	case visible = "visible"
	case start = "start"
	case offset = "offset"
	case showSeconds = "showSeconds"
	case showDays = "showDays"
    case projectStart = "projectStart"
    case consumeStart = "consumeStart"
    case projectEnd = "projectEnd"
    case consumeEnd = "consumeEnd"
    case projectRatio = "projectRatio"
    case consumeRatio = "consumeRatio"
    case projectTimerState = "projectTimerState"
    case consumeTimerState = "consumeTimerState"
    case uuid = "uuid"
}
