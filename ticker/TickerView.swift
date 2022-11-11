//
//  TickerView.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import Combine

struct TickerView: View {
	@State var time: (Int, Int) = TickerView.getCurrentTime()
	@State var tickers: [Ticker] = []
	@State var selectedTicker: Int = 0
	@State var isActive: Bool = false
	@State var updater: Bool = false
	
	var currentTicker: Ticker? { tickers.isEmpty ? nil : tickers[selectedTicker] }
	
    var body: some View {
		VStack(spacing: 0) {
			Spacer()
			VStack(alignment: .trailing, spacing: 0) {
				ForEach(0..<Int(tickers.count), id: \.self) { i in
					Text(tickers[i].name + " " + String(format: "%01d.%02d", tickers[i].time.0, (tickers[i].time.1*100)/3600 % 100))
						.bold(isActive && i == selectedTicker)
						.opacity(tickers[i].active ? 1 : (isActive ? 0.3 : 0))
				}
				Text("     " + String(format: "%01d.%02d", time.0, (time.1*100)/3600 % 100))
				Spacer().frame(height: (updater ? 2 : 2))
			}
			.fixedSize()
		}
		.frame(height: 500)
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didBecomeActiveNotification)) { _ in
			isActive = true
		}
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didResignActiveNotification)) { _ in
			isActive = false
			tickers = tickers.filter { !$0.active } + tickers.filter { $0.active }
		}
		.background(KeyPressHelper(keyDownFunc))
		.onAppear {
			deleteTimer = deleteTimerFunc
			Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
				time = TickerView.getCurrentTime()
			})
		}
    }
	
	static func getCurrentTime() -> (Int, Int) {
		let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: .now)
		return ((comp.hour ?? 0) % 12, (comp.minute ?? 0)*60 + (comp.second ?? 0))
	}
	
	func keyDownFunc(event: NSEvent) {
		updater.toggle()
		
		if event.modifierFlags.contains(.command) {
			if event.characters == "e" {
				tickers = [Ticker()] + tickers
			}
			return
		}
		
		if event.characters == " " {
			if let start = currentTicker?.start {
				currentTicker?.offset += Int(Date().timeIntervalSince(start))
				currentTicker?.start = nil
			} else {
				currentTicker?.start = Date()
			}
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
		} else if event.specialKey == .downArrow {
			selectedTicker = min(tickers.count - 1, selectedTicker + 1)
		} else if event.specialKey == .tab {
			selectedTicker = (selectedTicker + 1) % tickers.count
		} else if event.specialKey == .backTab {
			selectedTicker = (tickers.count + selectedTicker - 1) % tickers.count
		} else if event.specialKey == .delete {
			if !(currentTicker?.name.isEmpty ?? false) {
				currentTicker?.name.removeLast()
			}
		} else if event.specialKey == nil {
			currentTicker?.name += event.characters ?? ""
		}
	}
	
	func deleteTimerFunc() {
		if tickers.count > selectedTicker {
			tickers.remove(at: selectedTicker)
			selectedTicker %= max(1, tickers.count)
		}
	}
}

class Ticker {
	var start: Date?
	var name: String
	var offset: Int
	var offsetChange: String? = nil
	var posOffset: Bool = false
	var equivalentOffset: Bool = false
	var active: Bool { start != nil }
	var time: (Int, Int) {
		let total: Int
		if let start { total = Int(Date().timeIntervalSince(start)) + offset }
		else { total = offset }
		return (total / 3600, total % 3600)
	}
	
	init() {
		start = Date.now
		name = ""
		offset = 0
	}
}
