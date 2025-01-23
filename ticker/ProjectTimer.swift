//
//  ProjectTimer.swift
//  ticker
//
//  Created by 4 on '24.12.22.
//

import SwiftUI

let projectCooldownRatio: Double = 4.0

class ProjectTimer: Ticker {
    static var main: ProjectTimer? = nil
    static var state: State = ProjectTimer.State(rawValue: Storage.int(.projectTimerState)) ?? .none
    
    override func offsetResolved() -> Ticker {
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
        
        guard (offsetType == .neg ? -newOffset : newOffset) < 0 else { return self }
        
        ProjectTimer.state = .project
        Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
        Storage.main.lastStartTime = now.timeIntervalSinceReferenceDate
        Storage.main.lastEndTime = now.timeIntervalSinceReferenceDate + (offsetType == .neg ? newOffset : -newOffset)
        Storage.main.storeDates()
        
        return ProjectTimer(name: name, origin: now, start: now,
                      offset: (offsetType == .neg ? -newOffset : newOffset), visible: visible)
    }
    
    override func activityToggled() -> Ticker {
        return self
    }
    
    static func getProjectTicker() -> ProjectTimer {
        ProjectTimer.state = .project
        Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
        let start = Date.init(timeIntervalSinceReferenceDate: Storage.main.lastStartTime)
        let offset = -Storage.main.projectTime
        return ProjectTimer(name: "", origin: start, start: start, offset: offset, visible: true)
    }
    
    static func getCooldownTicker() -> ProjectTimer {
        ProjectTimer.state = .cooldown
        Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
        let start = Date.init(timeIntervalSinceReferenceDate: Storage.main.lastEndTime)
        let offset = -projectCooldownRatio*Storage.main.projectTime
        return ProjectTimer(name: "", origin: start, start: start, offset: offset, visible: true)
    }
    
    override func toDict() -> [String: Any]? { return nil }
    
    enum State: Int {
        case none = 0, project = 1, cooldown = 2
    }
}
