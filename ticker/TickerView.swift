//
//  TickerView.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import Combine

var showSeconds: Bool = Storage.bool(.showSeconds)

struct TickerView: View {
	@State var tickerHistory: [[Ticker]] = [Storage.tickerArray().compactMap { Ticker(from: $0) }]
	@State var versionsBack: Int = 0
	@State var selectedTicker: Int = Storage.int(.selected)
	@State var isActive: Bool = false
	@State var updater: Bool = false
//	@State var remainingPower: Int = getRemainingPower()
	
	var tickers: [Ticker] { tickerHistory[tickerHistory.count - 1 - versionsBack] }
	var currentTicker: Ticker? { tickers.isEmpty ? nil : tickers[selectedTicker] }
	
    var body: some View {
		HStack {
			Spacer()
			VStack(spacing: 0) {
				Spacer()
				VStack(alignment: .trailing, spacing: 0) {
					ForEach(0..<Int(tickers.count), id: \.self) { i in
						Text(tickers[i].getString())
							.bold(isActive && i == selectedTicker)
							.opacity(tickers[i].active ? 1 : (isActive ? 0.3 : 0))
					}
					Text((isActive ? getDateString() : "") + getCurrentTime())
					Spacer().frame(height: (updater ? 2 : 2))
				}
				.fixedSize()
			}
		}
		.frame(width: 500, height: 500)
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didBecomeActiveNotification)) { _ in
			isActive = true
			for ticker in tickers {
				ticker.flashing = false
			}
//			if tickers.isEmpty {
//				setTickers([Ticker()])
//				selectedTicker = 0
//				Storage.set(selectedTicker, for: .selected)
//			}
		}
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didResignActiveNotification)) { _ in
			isActive = false
			let topActive = tickers.firstIndex(where: { $0.active }) ?? tickers.count
			let bottomInactive = tickers.lastIndex(where: { !$0.active }) ?? 0
			guard tickers.contains(where: { $0.offsetChange != nil }) || topActive < bottomInactive else { return }
			let lastCurrentTicker = currentTicker
			var newTickers = tickers
			for (i, ticker) in newTickers.enumerated() {
				newTickers[i] = ticker.offsetResolved()
			}
			setTickers(newTickers.filter({ !$0.active }) + newTickers.filter({ $0.active }))
			selectedTicker = tickers.firstIndex(where: { $0 === lastCurrentTicker }) ?? selectedTicker
			Storage.set(selectedTicker, for: .selected)
		}
		.background(KeyPressHelper(keyDownFunc))
		.onAppear {
			deleteTimer = deleteTimerFunc
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
				updater.toggle()
			})
//			Timer.scheduledTimer(withTimeInterval: 100, repeats: true, block: { _ in
//				remainingPower = getRemainingPower()
//			})
		}
    }
	
	func getDateString() -> String {
		let dateComp = Calendar.current.dateComponents([.day, .hour], from: .now)
//		let year = (dateComp.year ?? 0) - 1997
		let hour = (dateComp.hour ?? 0)
		
		return "\(dateComp.day ?? 0)." + (hour == 0 ? "0." : "")
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
	
//	func getTimeView() -> some View {
//		let time = getCurrentTime().split(separator: ".")
//		let power = remainingPower
//		let color: Color
//
//		switch power {
//		case 80...100: color = Color(.displayP3, red: 0, green: 0.85, blue: 0.3)
//		case 50..<80: color = .white
//		case 20..<50: color =  Color(.displayP3, red: 0.88, green: 0.62, blue: 0.0, opacity: 1.0)
//		default: color = Color(.displayP3, red: 1, green: 0.0, blue: 0.0, opacity: 1.0)
//		}
//
//		return Text(time[0]) + Text(".").foregroundColor(color) + Text(time[1])
//	}
	
	func keyDownFunc(event: NSEvent) {
		updater.toggle()
		
		if event.keyCode == 53 { // esc
			if currentTicker?.offsetChange != nil {
				currentTicker?.resetOffset()
			} else {
				NSApplication.shared.hide(nil)
				NSApplication.shared.unhideWithoutActivation()
			}
		}
		
		if event.modifierFlags.contains(.command) {
			if event.characters == "e" {
				setTickers([Ticker()] + tickers)
				selectedTicker = 0
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "z" {
				if event.modifierFlags.contains(.shift) {
					versionsBack = max(versionsBack - 1, 0)
				} else {
					versionsBack = min(versionsBack + 1, tickerHistory.count - 1)
				}
			} else if event.characters == "??" {
				NSApp.terminate(self)
			} else if event.characters == "c" {
				guard let copyString = currentTicker?.getTimeString(copy: true) else { return }
				NSPasteboard.general.declareTypes([.string], owner: nil)
				NSPasteboard.general.setString(copyString, forType: .string)
			}
			return
		}
		
		guard let currentTicker else { return }
		
		if event.characters == " " {
			if event.modifierFlags.contains(.shift) {
				currentTicker.name += " "
			} else {
				setCurrentTicker(currentTicker.activityToggled())
			}
		} else if event.characters == "+" && currentTicker.offsetChange == nil {
			currentTicker.offsetType = .pos
			currentTicker.equivalentOffset = false
			currentTicker.offsetChange = ""
		} else if event.characters == "-" && currentTicker.offsetChange == nil {
			currentTicker.offsetType = .neg
			currentTicker.equivalentOffset = false
			currentTicker.offsetChange = ""
		} else if event.characters == ">" && currentTicker.offsetChange == nil {
			currentTicker.offsetType = .zero
			currentTicker.equivalentOffset = false
			currentTicker.offsetChange = ""
		} else if event.characters == "=" {
			currentTicker.equivalentOffset.toggle()
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
			if currentTicker.offsetChange != nil {
				if !(currentTicker.offsetChange?.isEmpty ?? true) {
					currentTicker.offsetChange?.removeLast()
				}
			} else if !currentTicker.name.isEmpty {
				currentTicker.name.removeLast()
			}
		} else if event.specialKey == .carriageReturn {
			setCurrentTicker(currentTicker.offsetResolved())
		} else if event.specialKey == nil {
			if currentTicker.offsetChange != nil {
				for c in (event.characters ?? "").filter({ "0123456789.-".contains($0) }) {
					currentTicker.offsetChange?.append(c)
				}
			} else {
				currentTicker.name += event.characters ?? ""
			}
		}
	}
	
	func deleteTimerFunc() {
		if tickers.count > selectedTicker {
			var newTickers = tickers
			newTickers.remove(at: selectedTicker)
			selectedTicker %= max(1, newTickers.count)
			setTickers(newTickers)
			Storage.set(selectedTicker, for: .selected)
		}
	}
	
	func storeTickers() {
		Storage.set(tickers.map { $0.toDict() }, for: .tickers)
	}
}

func getCurrentTime() -> String {
	let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: .now)
	let hour = (comp.hour ?? 0) // TODO find a better way to do this
//	let fraction = ((comp.minute ?? 0)*60 + (comp.second ?? 0))/36
//	return String(format: "%01d.%02d", hour, fraction)
	return (hour != 0 ? "\(hour)." : "") + "\(comp.minute ?? 0)" + (showSeconds ? ".\(comp.second ?? 0)" : "")
}

//func getCurrentDTime() -> String {
//	let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: .now)
//	let hour = comp.hour ?? 0
//	let fraction = ((comp.minute ?? 0)*60 + (comp.second ?? 0))/36
//	return String(format: "%01d.%02d", hour, fraction)
// //	return String(hour*100 + (comp.minute ?? 0))
//}

