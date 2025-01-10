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
    
    @Published var lastStartTime: Date
    @Published var lastEndTime: Date
    
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
                        print(authResult?.additionalUserInfo)
                    }
                }
            }
        }
        _ = ref.observe(DataEventType.value, with: { snapshot in
            if let dict = snapshot.value as? [String: [String: Double]] {
                guard let mostRecent = dict.max(by: { l, r in
                    // TODO test this once 4 has it too!
                    if l.value[Key.lastStartTime.rawValue] == r.value[Key.lastStartTime.rawValue] {
                        return (l.value[Key.lastEndTime.rawValue] ?? 0) > (r.value[Key.lastEndTime.rawValue] ?? 0)
                    }
                    return (l.value[Key.lastStartTime.rawValue] ?? 0) < (r.value[Key.lastStartTime.rawValue] ?? 0)
                }) else { return }
                if mostRecent.key != self.myID {
                    if let newStart = mostRecent.value[Key.lastStartTime.rawValue], newStart != self.lastStartTime.timeIntervalSinceReferenceDate {
                        self.lastStartTime = Date.init(timeIntervalSinceReferenceDate: newStart)
                        self.storeDate(of: .lastStartTime, self.lastStartTime)
                    }
                    if let newEnd = mostRecent.value[Key.lastEndTime.rawValue], newEnd != self.lastEndTime.timeIntervalSinceReferenceDate {
                        self.lastEndTime = Date.init(timeIntervalSinceReferenceDate: newEnd)
                        self.storeDate(of: .lastEndTime, self.lastEndTime)
                    }
                }
            }
        })
        
        let storedState = ProjectTimer.State(rawValue: Storage.int(.projectTimerState)) ?? .none
        
        if activeProject || (activeCooldown && storedState == .project) {
            ProjectTimer.state = .project
            ProjectTimer.main = ProjectTimer(name: "", origin: lastStartTime, start: lastStartTime, offset: -projectTime, visible: true)
        } else if activeCooldown {
            ProjectTimer.state = .cooldown
            ProjectTimer.main = ProjectTimer(name: "", origin: lastEndTime, start: lastEndTime, offset: -projectTime, visible: true)
        } else {
            ProjectTimer.state = .none
            ProjectTimer.main = nil
        }
    }
    
    func storeDate(of key: Key, _ date: Date) {
        let timeElapsed = date.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(timeElapsed, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(timeElapsed)
    }
    
    func storeDates() {
        let startDouble = lastStartTime.timeIntervalSinceReferenceDate
        let endDouble = lastEndTime.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(startDouble, forKey: Key.lastStartTime.rawValue)
        UserDefaults.standard.set(endDouble, forKey: Key.lastEndTime.rawValue)
        ref.child(myID).setValue([Key.lastStartTime.rawValue: startDouble, Key.lastEndTime.rawValue: endDouble])
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
    
    static func getDate(of key: Key) -> Date {
        let timeElapsed = getDouble(for: key)
        return Date.init(timeIntervalSinceReferenceDate: timeElapsed)
    }
    
    static func storeDate(of key: Key, _ date: Date) {
        let timeElapsed = date.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(timeElapsed, forKey: key.rawValue)
    }
    
    static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
    
    var cooldownEndTime: Date {
        lastEndTime + projectTime
    }
    
    var activeProject: Bool {
        return Date.now <= lastEndTime
    }
    
    var activeCooldown: Bool {
        return Date.now > lastEndTime && cooldownEndTime > Date.now
    }
    
    var projectTime: TimeInterval {
        lastStartTime.distance(to: lastEndTime)
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
