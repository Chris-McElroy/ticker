//
//  ProjectTimer.swift
//  ticker
//
//  Created by 4 on '24.12.22.
//

import SwiftUI

class ProjectTimer: Ticker {
    static var main: ProjectTimer? = nil
    static var lastStartTime: Date = Storage.getDate(of: .lastStartTime)
    static var lastEndTime: Date = Storage.getDate(of: .lastEndTime)
    static var state: State = .none
    
    // TODO make it so you can't name these
    
    static var cooldownEndTime: Date {
        lastEndTime + projectTime
    }
    
    static var activeProject: Bool {
        return Date.now <= lastEndTime
    }
    
    static var activeCooldown: Bool {
        return Date.now > lastEndTime && cooldownEndTime > Date.now
    }
    
    static var projectTime: TimeInterval {
        lastStartTime.distance(to: lastEndTime)
    }
    
    static func initStaticVars() {
        let storedState = State(rawValue: Storage.int(.projectTimerState)) ?? .none
        
        if activeProject || (activeCooldown && storedState == .project) {
            state = .project
            main = ProjectTimer(name: "", origin: lastStartTime, start: lastStartTime, offset: -projectTime, visible: true)
        } else if activeCooldown {
            state = .cooldown
            main = ProjectTimer(name: "", origin: lastEndTime, start: lastEndTime, offset: -projectTime, visible: true)
        } else {
            state = .none
            main = nil
        }
    }
    
    override func offsetResolved() -> Ticker {
        print("resolving?", offsetChange, offset, ProjectTimer.state)
        guard var offsetChange else { return self }
        
        guard offset == 0 else { self.offsetChange = nil; return self }
        guard ProjectTimer.state == .none else { self.offsetChange = nil; return self }
        
        let now = Date.now
        
        let negative = offsetChange.first == "-"
        if negative { offsetChange.removeFirst() }
        
        let minEq = offsetChange.first == ";" && equivalentOffset
        if minEq { offsetChange.removeFirst() }
        
        var offsetComp: [Double] = []
        for nString in offsetChange.split(separator: ".") {
            guard let n = Double(nString) else { return self }
            offsetComp.append(n)
        }
        
        guard !offsetComp.isEmpty && offsetComp.count <= (showSeconds ? 4 : 3) else {
            self.offsetChange = nil
            return self
        }
        
        let days: Double = (offsetComp.count >= (showSeconds ? 4 : 3)) ? offsetComp[offsetComp.count - (showSeconds ? 4 : 3)] : 0
        let hours: Double = (offsetComp.count >= (showSeconds ? 3 : 2)) ? offsetComp[offsetComp.count - (showSeconds ? 3 : 2)] : 0
        let min: Double = (offsetComp.count >= (showSeconds ? 2 : 1)) ? offsetComp[offsetComp.count - (showSeconds ? 2 : 1)] : 0
        let seconds: Double = showSeconds ? offsetComp[offsetComp.count - 1] : 0
        
        var newOffset = days*86400 + hours*3600 + min*60 + seconds
        if negative { newOffset = -newOffset }
        
        if equivalentOffset {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
            var eqAmt: Double = Double(3600*(comp.hour ?? 0))
            eqAmt += Double(60*(comp.minute ?? 0))
            eqAmt += Double(comp.second ?? 0)
            eqAmt += Double((comp.nanosecond ?? 0))/1000000000
            
            if minEq {
                newOffset += Double(3600*(comp.hour ?? 0))
            }
            
            newOffset = eqAmt - newOffset
        }
        
        print("fe", newOffset, offsetType)
        guard (offsetType == .neg ? -newOffset : newOffset) < 0 else { return self }
        
        ProjectTimer.state = .project
        ProjectTimer.lastStartTime = now
        ProjectTimer.lastEndTime = now + (offsetType == .neg ? newOffset : -newOffset)
        
        print("returning!")
        return ProjectTimer(name: name, origin: now, start: now,
                      offset: (offsetType == .neg ? -newOffset : newOffset), visible: visible)
    }
    
    override func activityToggled() -> Ticker {
        return self
    }
    
    static func getProjectTicker() -> ProjectTimer {
        ProjectTimer.state = .project
        let start = ProjectTimer.lastStartTime
        let offset = -ProjectTimer.lastStartTime.distance(to: ProjectTimer.lastEndTime)
        return ProjectTimer(name: "", origin: start, start: start, offset: offset, visible: true)
    }
    
    static func getCooldownTicker() -> ProjectTimer {
        ProjectTimer.state = .cooldown
        let start = ProjectTimer.lastEndTime
        let offset = -ProjectTimer.lastStartTime.distance(to: ProjectTimer.lastEndTime)
        print("cool", ProjectTimer.lastEndTime, ProjectTimer.lastStartTime, -ProjectTimer.lastStartTime.distance(to: ProjectTimer.lastEndTime), offset, start)
        return ProjectTimer(name: "", origin: start, start: start, offset: offset, visible: true)
    }
    
    override func toDict() -> [String: Any]? { return nil }
    
    enum State: Int {
        case none = 0, project = 1, cooldown = 2
    }
}
