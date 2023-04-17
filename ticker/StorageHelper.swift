//
//  StorageHelper.swift
//  ticker
//
//  Created by Chris McElroy on 11/14/22.
//

import Foundation

class Storage {
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
}

enum Key: String {
	case tickers = "tickers"
	case selected = "selected"
	case name = "name"
	case origin = "origin"
	case start = "start"
	case offset = "offset"
	case showSeconds = "showSeconds"
	case showDays = "showDays"
}
