//
//  GeneralHelper.swift
//  ticker
//
//  Created by Chris McElroy on 12/28/22.
//

import Foundation

extension Int {
	func toDozenal(minChar: Int = 0) -> String {
		var rem = abs(self)
		var output = ""
		if rem == 0 { return "0" }
		while rem > 0 {
			let digit = rem % 12
			if digit < 10 {
				output = String(digit) + output
			} else {
				output = ([10: "X", 11: "V"][digit] ?? "") + output
			}
			rem /= 12
		}
		if output.count < minChar {
			output = String(repeating: "0", count: minChar - output.count) + output
		}
		if self < 0 { output = "-" + output }
		return output
	}
}

func tickerString(neg: Bool, days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> String {
	if days != 0 {
		return (neg ? "-" : "") + "\(days)." + "\(hours)." + "\(minutes)" + (showSeconds ? ".\(seconds)" : "")
	} else if hours != 0 {
		return (neg ? "-" : "") + "\(hours)." + "\(minutes)" + (showSeconds ? ".\(seconds)" : "")
	} else if minutes != 0 || !showSeconds {
		return (neg ? "-" : "") + "\(minutes)" + (showSeconds ? ".\(seconds)" : "")
	} else {
		return (neg ? "-" : "") + "\(seconds)"
	}
}
