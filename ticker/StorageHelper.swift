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
    
    @Published var lastStartTime: TimeInterval
    @Published var lastEndTime: TimeInterval
    
    var ref: DatabaseReference!
    var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
    
    init() {
        ref = Database.database().reference()
        lastStartTime = Storage.getDate(of: .lastStartTime)
        lastEndTime = Storage.getDate(of: .lastEndTime)
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
                print("got change")
                guard let otherID = dict.keys.first(where: { $0 != self.myID }) else { return }
                guard let otherStart = dict[otherID]?[Key.lastStartTime.rawValue] else { return }
                guard let otherEnd = dict[otherID]?[Key.lastEndTime.rawValue] else { return }
                if otherStart !~ self.lastStartTime {
                    if otherStart > self.lastEndTime {
                        print("got new start")
                        self.lastStartTime = otherStart
                        self.lastEndTime = otherEnd
                        self.storeDates()
                        self.resetProjectTimer()
                    }
                } else if otherEnd !~ self.lastEndTime {
                    if otherEnd < self.lastEndTime {
                        print("got new end")
                        self.lastEndTime = otherEnd
                        self.storeDate(of: .lastEndTime, self.lastEndTime)
                        self.resetProjectTimer()
                    }
                }
            }
        })
        
        resetProjectTimer()
    }
    
    func resetProjectTimer() {
        let start = Date.init(timeIntervalSinceReferenceDate: lastStartTime)
        let end = Date.init(timeIntervalSinceReferenceDate: lastEndTime)
        if activeProject {
            ProjectTimer.state = .project
            Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
            ProjectTimer.main = ProjectTimer(name: "", origin: start, start: start, offset: -projectTime, visible: true)
        } else if activeCooldown {
            ProjectTimer.state = .cooldown
            Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
            ProjectTimer.main = ProjectTimer(name: "", origin: end, start: end, offset: -projectTime, visible: true)
        } else {
            ProjectTimer.state = .none
            Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
            ProjectTimer.main = nil
        }
    }
    
    func storeDate(of key: Key, _ date: TimeInterval) {
        UserDefaults.standard.set(date, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(date)
    }
    
    func storeDates() {
        UserDefaults.standard.set(lastStartTime, forKey: Key.lastStartTime.rawValue)
        UserDefaults.standard.set(lastEndTime, forKey: Key.lastEndTime.rawValue)
        ref.child(myID).setValue([Key.lastStartTime.rawValue: lastStartTime, Key.lastEndTime.rawValue: lastEndTime])
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
    
    var cooldownEndTime: TimeInterval {
        lastEndTime + projectTime
    }
    
    var activeProject: Bool {
        return Date.now.timeIntervalSinceReferenceDate <= lastEndTime
    }
    
    var activeCooldown: Bool {
        return Date.now.timeIntervalSinceReferenceDate > lastEndTime && cooldownEndTime > Date.now.timeIntervalSinceReferenceDate
    }
    
    var projectTime: TimeInterval {
        lastEndTime - lastStartTime
    }
}

infix operator ~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence

extension Double {
    static func ~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) < 0.00001
    }
    
    static func !~(lhs: Double, rhs: Double) -> Bool {
        return abs(lhs - rhs) >= 0.00001
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
    case lastStartTime = "lastStartTime"
    case lastEndTime = "lastEndTime"
    case projectTimerState = "projectTimerState"
    case uuid = "uuid"
}
