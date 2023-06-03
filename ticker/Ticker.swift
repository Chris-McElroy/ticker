//
//  Ticker.swift
//  ticker
//
//  Created by Chris McElroy on 1/9/23.
//

import SwiftUI

let sleepQueue = DispatchQueue(label: "sleep")

enum OffsetType: String {
	case pos = "+"
	case neg = "-"
	case zero = "<"
	
	func eqString() -> String {
		self == .neg ? "+" : "-"
	}
}

class Ticker {
	var name: String
	let origin: Date
	let start: Date?
	let offset: Double
	var offsetChange: String? = nil
	var offsetType: OffsetType = .pos
	var equivalentOffset: Bool = false
	var active: Bool { start != nil }
	var visible: Bool = true
	var flashing: Bool = false
	var wasNegative: Bool = false
	var validCountdown: Bool = true
	
	init() {
		name = ""
		origin = .now
		start = origin
		offset = 0
	}
	
	init(name: String, origin: Date, start: Date?, offset: Double, visible: Bool) {
		self.name = name
		self.origin = origin
		self.start = start
		self.offset = offset
		self.visible = visible
	}
	
	init?(from dict: [String: Any]) {
		guard let startTime = dict[Key.start.rawValue] as? Double else { return nil }
		guard let name = dict[Key.name.rawValue] as? String else { return nil }
		guard let originTime = dict[Key.origin.rawValue] as? Double else { return nil }
		guard let offset = dict[Key.offset.rawValue] as? Double else { return nil }
		guard let visible = dict[Key.visible.rawValue] as? Bool else { return nil }
		self.name = name
		origin = Date(timeIntervalSinceReferenceDate: originTime)
		start = startTime == 0 ? nil : Date(timeIntervalSinceReferenceDate: startTime)
		self.offset = offset
		self.visible = visible
	}
	
	func getString() -> String {
		var fullString = name + " "
		fullString += getTimeString()
		
		if let offsetChange {
			if equivalentOffset {
				fullString += " " + offsetType.rawValue + " " + getCurrentTime().time + " " + offsetType.eqString() + " " + offsetChange
			} else {
				fullString += " " + offsetType.rawValue + " " + offsetChange
			}
		}
		
		return fullString
	}
	
	func getTimeString(copy: Bool = false) -> String {
		let time: Double
		if showTotals { time = Date().timeIntervalSince(origin) }
		else if let start { time = Date().timeIntervalSince(start) + offset }
		else { time = offset }
		let posTime = abs(time)
		validCountdown = time < 0 && time > -checkinThreshold
		
		if !showTotals {
			if wasNegative && time >= 0 {
				flashing = true
			}
			
			wasNegative = time < 0
			if time < 0 {
				flashing = false
			}
			if flashing && (posTime*2).truncatingRemainder(dividingBy: 2) < 1 {
				return " "
			}
		}
		
		let seconds = Int(posTime.rounded(.down)) % 60
		let min = (Int(posTime.rounded(.down))/60) % 60
		let hours = Int(posTime.rounded(.down))/3600 % 24
		let days = Int(posTime.rounded(.down))/86400
		
		if copy {
			return (time < 0 ? "-" : "") + "\(hours):" + String(format: "%02d", min) + (showSeconds ? ":\(String(format: "%02d", seconds))" : "")
		}
		
		return tickerString(neg: time < 0, days: days, hours: hours, minutes: min, seconds: seconds)
	}
	
	func offsetResolved() -> Ticker {
		guard var offsetChange else { return self }
		
		let now = Date.now
		
		let negative = offsetChange.first == "-"
		if negative { offsetChange.removeFirst() }
		
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
			
			newOffset = eqAmt - newOffset
		}
		
		return Ticker(name: name, origin: origin, start: (offsetType == .zero ? now : start),
					  offset: (offsetType == .zero ? 0 : offset) + (offsetType == .neg ? -newOffset : newOffset),
					  visible: ((offsetType == .zero && start == nil) ? true : visible))
	}
	
	func resetOffset() {
		offsetChange = nil
		offsetType = .pos
		equivalentOffset = false
	}
	
	func activityToggled() -> Ticker {
		if let start {
			return Ticker(name: name, origin: origin, start: nil, offset: offset + Date().timeIntervalSince(start), visible: false)
		} else {
			return Ticker(name: name, origin: origin, start: Date(), offset: offset, visible: true)
		}
	}
	
	func toDict() -> [String: Any] {
		[
			Key.start.rawValue: start?.timeIntervalSinceReferenceDate ?? 0,
			Key.name.rawValue: name,
			Key.origin.rawValue: origin.timeIntervalSinceReferenceDate,
			Key.offset.rawValue: offset,
			Key.visible.rawValue: visible
		]
	}
}
