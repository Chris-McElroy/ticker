//
//  TickerView.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import Combine

struct TickerView: View {
	@State var tickers: [Ticker] = Storage.tickerArray().compactMap { Ticker(from: $0) }
	@State var selectedTicker: Int = Storage.int(.selected)
	@State var isActive: Bool = false
	@State var updater: Bool = false
	
	var currentTicker: Ticker? { tickers.isEmpty ? nil : tickers[selectedTicker] }
	
    var body: some View {
		HStack {
			Spacer()
			VStack(spacing: 0) {
				Spacer()
				VStack(alignment: .trailing, spacing: 0) {
					ForEach(0..<Int(tickers.count), id: \.self) { i in
						Text(tickers[i].string)
							.bold(isActive && i == selectedTicker)
							.opacity(tickers[i].active ? 1 : (isActive ? 0.3 : 0))
					}
					Text(getCurrentTime())
					Spacer().frame(height: (updater ? 2 : 2))
				}
				.fixedSize()
			}
		}
		.frame(width: 500, height: 500)
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didBecomeActiveNotification)) { _ in
			isActive = true
		}
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didResignActiveNotification)) { _ in
			isActive = false
			tickers = tickers.filter { !$0.active } + tickers.filter { $0.active }
			for ticker in tickers {
				ticker.resolveOffset()
			}
			storeTickers()
		}
		.background(KeyPressHelper(keyDownFunc))
		.onAppear {
			deleteTimer = deleteTimerFunc
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
				updater.toggle()
			})
		}
    }
	
	func keyDownFunc(event: NSEvent) {
		updater.toggle()
		
		if event.modifierFlags.contains(.command) {
			if event.characters == "e" {
				tickers = [Ticker()] + tickers
				selectedTicker = 0
				storeTickers()
				Storage.set(selectedTicker, for: .selected)
			}
			return
		}
		
		if event.characters == " " {
			if let start = currentTicker?.start {
				currentTicker?.offset += Date().timeIntervalSince(start)
				currentTicker?.start = nil
			} else {
				currentTicker?.start = Date()
			}
			storeTickers()
		} else if event.characters == "+" {
			currentTicker?.posOffset = true
			currentTicker?.equivalentOffset = false
			currentTicker?.offsetChange = ""
		} else if event.characters == "-" {
			currentTicker?.posOffset = false
			currentTicker?.equivalentOffset = false
			currentTicker?.offsetChange = ""
		} else if event.characters == "=" {
			currentTicker?.equivalentOffset.toggle()
		} else if event.specialKey == .upArrow {
			selectedTicker = max(0, selectedTicker - 1)
			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .downArrow {
			selectedTicker = min(tickers.count - 1, selectedTicker + 1)
			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .tab {
			selectedTicker = (selectedTicker + 1) % tickers.count
			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .backTab {
			selectedTicker = (tickers.count + selectedTicker - 1) % tickers.count
			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .delete {
			if currentTicker?.offsetChange != nil {
				if !(currentTicker?.offsetChange?.isEmpty ?? true) {
					currentTicker?.offsetChange?.removeLast()
				}
			} else if !(currentTicker?.name.isEmpty ?? true) {
				currentTicker?.name.removeLast()
				storeTickers()
			}
		} else if event.specialKey == .carriageReturn {
			currentTicker?.resolveOffset()
			storeTickers()
		} else if event.specialKey == nil {
			if currentTicker?.offsetChange != nil {
				for c in (event.characters ?? "").filter({ "0123456789.".contains($0) }) {
					currentTicker?.offsetChange?.append(c)
				}
			} else {
				currentTicker?.name += event.characters ?? ""
				storeTickers()
			}
		}
	}
	
	func deleteTimerFunc() {
		if tickers.count > selectedTicker {
			tickers.remove(at: selectedTicker)
			selectedTicker %= max(1, tickers.count)
			storeTickers()
			Storage.set(selectedTicker, for: .selected)
		}
	}
	
	func storeTickers() {
		Storage.set(tickers.map { $0.toDict() }, for: .tickers)
	}
}

func getCurrentTime() -> String {
	let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: .now)
	let hour = comp.hour ?? 0
	let fraction = ((comp.minute ?? 0)*60 + (comp.second ?? 0))/36
	return String(format: "%01d.%02d", hour, fraction)
}

class Ticker {
	var start: Date?
	var name: String
	var offset: Double
	var offsetChange: String? = nil
	var posOffset: Bool = false
	var equivalentOffset: Bool = false
	var active: Bool { start != nil }
	
	init() {
		start = Date.now
		name = ""
		offset = 0
	}
	
	init?(from dict: [String: Any]) {
		guard let startTime = dict[Key.start.rawValue] as? Double else { return nil }
		guard let name = dict[Key.name.rawValue] as? String else { return nil }
		guard let offset = dict[Key.offset.rawValue] as? Double else { return nil }
		start = startTime == 0 ? nil : Date(timeIntervalSinceReferenceDate: startTime)
		self.name = name
		self.offset = offset
	}
	
	var string: String {
		var fullString = name
		
		let total: Double
		if let start { total = Date().timeIntervalSince(start) + offset }
		else { total = offset }
		let hours = total/3600
		
		fullString += " " + String(format: "%.2f", hours)
		
		if let offsetChange {
			if equivalentOffset {
				fullString += " " + (posOffset ? "+" : "-") + " " + getCurrentTime() + " " + (posOffset ? "-" : "+") + " " + offsetChange
			} else {
				fullString += " " + (posOffset ? "+" : "-") + " " + offsetChange
			}
		}
		
		return fullString
	}
	
	func resolveOffset() {
		guard let offsetChange else { return }
		
		print("bop", offsetChange, Double(offsetChange) ?? 0)
		
		var newOffset = (Double(offsetChange) ?? 0)
		
		if equivalentOffset {
			newOffset = (Double(getCurrentTime()) ?? 0) - newOffset
		}
		
		if posOffset {
			offset += newOffset*3600
		} else {
			offset -= newOffset*3600
		}
		
		self.offsetChange = nil
	}
	
	func toDict() -> [String: Any] {
		[
			Key.start.rawValue: start?.timeIntervalSinceReferenceDate ?? 0,
			Key.name.rawValue: name,
			Key.offset.rawValue: offset
		]
	}
}
