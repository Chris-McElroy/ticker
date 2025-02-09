//
//  CooldownTimer.swift
//  ticker
//
//  Created by 4 on '24.12.22.
//

import SwiftUI

class CooldownTimer: Ticker {
    static var project: CooldownTimer? = nil
    static var consume: CooldownTimer? = nil
    static var projectState: State = CooldownTimer.State(rawValue: Storage.int(.projectTimerState)) ?? .none
    static var consumeState: State = CooldownTimer.State(rawValue: Storage.int(.consumeTimerState)) ?? .none
    
    var project: Bool
    var cooldown: Bool
    
    init(name: String, origin: Date, start: Date?, offset: Double, visible: Bool, project: Bool, cooldown: Bool) {
        self.project = project
        self.cooldown = cooldown
        super.init(name: name, origin: origin, start: start, offset: offset, visible: visible)
    }
    
    var state: State {
        get { project ? CooldownTimer.projectState : CooldownTimer.consumeState }
        set {
            if project {
                CooldownTimer.projectState = newValue
            } else {
                CooldownTimer.consumeState = newValue
            }
        }
    }
    var color: Color {
        if project {
            if cooldown {
                Color(hue: 280/360, saturation: 1, brightness: 1.0)
            } else {
                Color(hue: 45/360, saturation: 1, brightness: 0.90)
            }
        } else {
            if cooldown {
                Color(hue: 200/360, saturation: 1, brightness: 1.0)
            } else {
                Color(hue: 33/360, saturation: 1, brightness: 0.7)
            }
        }
    }
    
    override func offsetResolved() -> Ticker {
        guard var offsetChange else { return self }
        guard offset == 0 else { self.offsetChange = nil; return self }
        guard state == .none && !cooldown else { self.offsetChange = nil; return self }
        
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
        
        state = .active
        Storage.set(CooldownTimer.State.active.rawValue, for: project ? .projectTimerState : .consumeTimerState)
        if project {
            Storage.main.projectStart = now.timeIntervalSinceReferenceDate
            Storage.main.projectEnd = now.timeIntervalSinceReferenceDate + (offsetType == .neg ? newOffset : -newOffset)
            Storage.main.storeProjectDates()
        } else {
            Storage.main.consumeStart = now.timeIntervalSinceReferenceDate
            Storage.main.consumeEnd = now.timeIntervalSinceReferenceDate + (offsetType == .neg ? newOffset : -newOffset)
            Storage.main.storeConsumeDates()
        }
        
        return CooldownTimer(name: name, origin: now, start: now,
                             offset: (offsetType == .neg ? -newOffset : newOffset), visible: visible, project: project, cooldown: false)
    }
    
    override func activityToggled() -> Ticker {
        return self
    }
    
    static func getActiveTicker(for project: Bool) -> CooldownTimer {
        if project { CooldownTimer.projectState = .active }
        else { CooldownTimer.consumeState = .active }
        Storage.set(CooldownTimer.State.active.rawValue, for: project ? .projectTimerState : .consumeTimerState)
        let start = Date.init(timeIntervalSinceReferenceDate: project ? Storage.main.projectStart : Storage.main.consumeStart)
        let offset = -(project ? Storage.main.projectTime : Storage.main.consumeTime)
        return CooldownTimer(name: "", origin: start, start: start, offset: offset, visible: true, project: project, cooldown: false)
    }
    
    static func getCooldownTicker(for project: Bool) -> CooldownTimer {
        if project { CooldownTimer.projectState = .cooldown }
        else { CooldownTimer.consumeState = .cooldown }
        Storage.set(CooldownTimer.State.cooldown.rawValue, for: project ? .projectTimerState : .consumeTimerState)
        let start = Date.init(timeIntervalSinceReferenceDate: project ? Storage.main.projectEnd : Storage.main.consumeEnd)
        let offset = -(project ? Storage.main.projectRatio*Storage.main.projectTime : Storage.main.consumeRatio*Storage.main.consumeTime)
        return CooldownTimer(name: "", origin: start, start: start, offset: offset, visible: true, project: project, cooldown: true)
    }
    
    override func toDict() -> [String: Any]? { return nil }
    
    enum State: Int {
        case none = 0, active = 1, cooldown = 2
    }
}
