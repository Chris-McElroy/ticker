//
//  TickerView.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import Combine

struct TickerView: View {
	@State var tickerHistory: [[Ticker]] = [Storage.tickerArray().compactMap { Ticker(from: $0) }]
	@State var versionsBack: Int = 0
	@State var selectedTicker: Int = Storage.int(.selected)
	@State var isActive: Bool = false
	@State var updater: Bool = false
	@State var remainingPower: Int = getRemainingPower()
	
	var tickers: [Ticker] { tickerHistory[tickerHistory.count - 1 - versionsBack] }
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
					getTimeView()
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
			for ticker in tickers {
				ticker.offsetResolved()
			}
			setTickers(tickers.filter { !$0.active } + tickers.filter { $0.active })
			// TODO STS
		}
		.background(KeyPressHelper(keyDownFunc))
		.onAppear {
			deleteTimer = deleteTimerFunc
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
				updater.toggle()
			})
			Timer.scheduledTimer(withTimeInterval: 100, repeats: true, block: { _ in
				remainingPower = getRemainingPower()
			})
		}
    }
	
	func setTickers(_ newTickers: [Ticker]) {
		if versionsBack != 0 {
			tickerHistory.removeLast(versionsBack)
			versionsBack = 0
		}
		tickerHistory.append(newTickers)
		storeTickers()
	}
	
	func setCurrentTicker(_ newValue: Ticker?) {
		guard let newValue else { return }
		if tickers.isEmpty { return }
		var newTickers = tickers
		newTickers[selectedTicker] = newValue
		setTickers(newTickers)
	}
	
	func getTimeView() -> some View {
		let time = getCurrentTime().split(separator: ".")
		let power = remainingPower
		let color: Color
		
		switch power {
		case 80...100: color = Color(.displayP3, red: 0, green: 1, blue: 1)
		case 50..<80: color = .white
		case 20..<50: color = Color(.displayP3, red: 1.0, green: 0.75, blue: 0.0, opacity: 1.0)
		default: color = Color(.displayP3, red: 1, green: 0.0, blue: 0.0, opacity: 1.0)
		}
		
		return Text(time[0]) + Text(".").foregroundColor(color) + Text(time[1])
	}
	
	func keyDownFunc(event: NSEvent) {
		updater.toggle()
		
		if event.modifierFlags.contains(.command) {
			if event.characters == "e" {
				setTickers([Ticker()] + tickers)
				selectedTicker = 0
				Storage.set(selectedTicker, for: .selected)
			}
			return
		}
		
		if event.characters == " " {
			setCurrentTicker(currentTicker?.activityToggled())
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

struct Ticker {
	let name: String
	let start: Date?
	let offset: Double
	@State var offsetChange: String? = nil
	@State var posOffset: Bool = false
	@State var equivalentOffset: Bool = false
	var active: Bool { start != nil }
	
	init() {
		name = ""
		start = Date.now
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
	
	func offsetResolved() -> Ticker {
		guard let offsetChange else { return self }
		
		var newOffset = (Double(offsetChange) ?? 0)
		if equivalentOffset {
			newOffset = (Double(getCurrentTime()) ?? 0) - newOffset
		}
		
		let totalOffsetChange: Double
		if posOffset {
			totalOffsetChange = newOffset*3600
		} else {
			totalOffsetChange = -newOffset*3600
		}
		
		return Ticker(name: name, start: start, offset: offset + totalOffsetChange)
	}
	
	func activityToggled() -> Ticker {
		if let start {
			return Ticker(name: name, start: nil, offset: Date().timeIntervalSince(start))
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
