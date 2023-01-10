//
//  Ticker.swift
//  ticker
//
//  Created by Chris McElroy on 1/9/23.
//

import Foundation

enum OffsetType: String {
	case pos = "+"
	case neg = "-"
	case zero = ">"
	
	func eqString() -> String {
		self == .pos ? "-" : "+"
	}
}

class Ticker {
	var name: String
	let start: Date?
	let offset: Double
	var offsetChange: String? = nil
	var offsetType: OffsetType = .pos
	var equivalentOffset: Bool = false
	var active: Bool { start != nil }
	var flashing: Bool = false
	var wasNegative: Bool = false
	
	init() {
		name = ""
		start = .now
		offset = 0
	}
	
	init(name: String, start: Date?, offset: Double) {
		self.name = name
		self.start = start
		self.offset = offset
	}
	
	init?(from dict: [String: Any]) {
		guard let startTime = dict[Key.start.rawValue] as? Double else { return nil }
		guard let name = dict[Key.name.rawValue] as? String else { return nil }
		guard let offset = dict[Key.offset.rawValue] as? Double else { return nil }
		start = startTime == 0 ? nil : Date(timeIntervalSinceReferenceDate: startTime)
		self.name = name
		self.offset = offset
	}
	
	func getString() -> String {
		var fullString = name + " "
		fullString += getTimeString()
		
		if let offsetChange {
			if equivalentOffset {
				fullString += " " + offsetType.rawValue + " " + getCurrentTime() + " " + offsetType.eqString() + " " + offsetChange
			} else {
				fullString += " " + offsetType.rawValue + " " + offsetChange
			}
		}
		
		return fullString
	}
	
	func getTimeString(copy: Bool = false) -> String {
		let time: Double
		if let start { time = Date().timeIntervalSince(start) + offset }
		else { time = offset }
		let posTime = abs(time)
		
		if wasNegative && time >= 0 { flashing = true }
		wasNegative = time < 0
		if time < 0 {
			flashing = false
		}
		if flashing && (posTime*2).truncatingRemainder(dividingBy: 2) < 1 { return " " }
		
		let seconds = Int(posTime.rounded(.down)) % 60
		let min = (Int(posTime.rounded(.down))/60) % 60
		let hours = Int(posTime.rounded(.down))/3600
		
		if copy {
			return (time < 0 ? "-" : "") + "\(hours):" + String(format: "%02d", min) + (showSeconds ? ":\(String(format: "%02d", seconds))" : "")
		}
		
		return (time < 0 ? "-" : "") + (hours != 0 ? "\(hours)." : "") + "\(min)" + (showSeconds ? ".\(seconds)" : "")
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
		
		guard !offsetComp.isEmpty && offsetComp.count <= (showSeconds ? 4 : 3) else { return self }
		
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
		
		return Ticker(name: name, start: (offsetType == .zero ? now : start), offset: (offsetType == .zero ? 0 : offset) + (offsetType == .neg ? -newOffset : newOffset))
	}
	
	func resetOffset() {
		offsetChange = nil
		offsetType = .pos
		equivalentOffset = false
	}
	
	func activityToggled() -> Ticker {
		if let start {
			return Ticker(name: name, start: nil, offset: offset + Date().timeIntervalSince(start))
		} else {
			return Ticker(name: name, start: Date(), offset: offset)
		}
	}
	
	func toDict() -> [String: Any] {
		[
			Key.start.rawValue: start?.timeIntervalSinceReferenceDate ?? 0,
			Key.name.rawValue: name,
			Key.offset.rawValue: offset
		]
	}
}
