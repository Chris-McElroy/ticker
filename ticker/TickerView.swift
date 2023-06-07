//
//  TickerView.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import Combine

var showSeconds: Bool = Storage.bool(.showSeconds)
var showDays: Bool = Storage.bool(.showDays)
var showTotals: Bool = false
var checkinThreshold: Double = 2520
var lastAc = 0

// Load framework
let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

struct TickerView: View {
	@State var tickerHistory: [[Ticker]] = [Storage.tickerArray().compactMap { Ticker(from: $0) }]
	@State var versionsBack: Int = 0
	@State var selectedTicker: Int = Storage.int(.selected)
	@State var isActive: Bool = false
	@State var updater: Bool = false
	@State var flashStart: Date? = nil
	@State var nextCheckin: Date? = nil
	@State var activeCountdowns = 2
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
							.underline(isActive && i == selectedTicker)
							.italic(!tickers[i].active)
							.opacity(tickers[i].visible ? 1 : (isActive ? 0.3 : 0))
					}
					let time = getCurrentTime(withDay: showDays || isActive)
					if !showDays && isActive {
						HStack(spacing: 0) {
							Text(time.day).opacity(0.3)
							Text(time.time.trimmingPrefix(time.day))
						}
						.bold(true)
					} else {
						Text(":" + time.time)
							.italic(isActive)
					}
					Spacer().frame(height: (updater ? 2 : 2))
				}
				.fixedSize()
			}
		}
		.foregroundColor(.white)
//		.foregroundColor(Color(hue: 0, saturation: 0, brightness: 0.5)) // for vera's gray
		.frame(width: 500, height: 500)
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didBecomeActiveNotification)) { _ in
			isActive = true
			nextCheckin = nil
//			for ticker in tickers {
//				ticker.flashing = false
//			}
//			if tickers.isEmpty {
//				setTickers([Ticker()])
//				selectedTicker = 0
//				Storage.set(selectedTicker, for: .selected)
//			}
		}
		.onReceive(NotificationCenter.default.publisher( for: NSApplication.didResignActiveNotification)) { _ in
			isActive = false
			showTotals = false
			setCheckin()
			
			let topVisible = tickers.firstIndex(where: { $0.visible }) ?? tickers.count
			let bottomInvisible = tickers.lastIndex(where: { !$0.visible }) ?? 0
			guard tickers.contains(where: { $0.offsetChange != nil }) || topVisible < bottomInvisible else { return }
			let lastCurrentTicker = currentTicker
			var newTickers = tickers
			for (i, ticker) in newTickers.enumerated() {
				newTickers[i] = ticker.offsetResolved()
			}
			setTickers(newTickers.filter({ !$0.visible }) + newTickers.filter({ $0.visible }))
			selectedTicker = tickers.firstIndex(where: { $0 === lastCurrentTicker }) ?? selectedTicker
			Storage.set(selectedTicker, for: .selected)
		}
		.background(KeyPressHelper(keyDownFunc))
		.onAppear {
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
				updater.toggle()
				monitorTickers()
			})
//			Timer.scheduledTimer(withTimeInterval: 100, repeats: true, block: { _ in
//				remainingPower = getRemainingPower()
//			})
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
	
	func monitorTickers() {
		let flashing = tickers.enumerated().first(where: { $0.element.flashing })
		let shouldHide = tickers.contains(where: { $0.flashing && !$0.name.contains("/") })
		
		if let flashing {
			if flashStart == nil {
				selectedTicker = flashing.offset
				flashStart = .now.advanced(by: isActive ? -10 : 0)
				if shouldHide {
					let executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
					try! Process.run(executableURL, arguments: ["run", "pause"], terminationHandler: nil)
				}
				if !isActive && !shouldHide {
					NSApplication.shared.activate(ignoringOtherApps: true)
				}
			}
			if shouldHide {
				if !hideWindow.isVisible { hideWindow.setIsVisible(true) }
				if !isActive {
					hideWindow.orderFront(nil)
					NSApplication.shared.activate(ignoringOtherApps: true)
				}
			}
		} else {
			flashStart = nil
			hideWindow.close()
		}
		
		if let nextCheckin, nextCheckin <= .now {
			// assumed to not be active bc it's reset when it's active
			self.nextCheckin = nil
			flashStart = .now
			NSApplication.shared.activate(ignoringOtherApps: true)
		}
	}
	
	func setCheckin() {
		let silentFlashing = tickers.contains(where: { $0.flashing && $0.name.contains("/") })
		if silentFlashing {
			nextCheckin = .now.advanced(by: 120)
			return
		}
		
		checkinThreshold = tickers.first(where: { $0.name == "checkin" })?.offset ?? 2520
		tickers.forEach { _ = $0.getTimeString() }
		activeCountdowns = tickers.reduce(0, { $0 + ($1.validCountdown ? 1 : 0) })
		if activeCountdowns < 2 {
			nextCheckin = .now.advanced(by: 300)
		}
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
		if event.keyCode == 53 { // esc
			if currentTicker?.offsetChange != nil {
				currentTicker?.resetOffset()
			} else {
				NSApplication.shared.hide(nil)
				NSApplication.shared.unhideWithoutActivation()
			}
			
			updater.toggle()
		}
		
		if event.modifierFlags.contains(.command) {
			if event.characters == "s" { // vera may want to change this back to space, along with other changes
				if let currentTicker {
					setCurrentTicker(currentTicker.activityToggled())
				}
			} else if event.characters == "e" {
				setTickers([Ticker()] + tickers)
				selectedTicker = 0
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "v" {
				if let currentTicker {
					currentTicker.visible.toggle()
				}
			} else if event.characters == "g" {
				if let currentTicker {
					setCurrentTicker(currentTicker.offsetResolved())
				}
			} else if event.characters == "z" {
				if event.modifierFlags.contains(.shift) {
					versionsBack = max(versionsBack - 1, 0)
				} else {
					versionsBack = min(versionsBack + 1, tickerHistory.count - 1)
				}
//			} else if event.characters == "œ" {
//				NSApp.terminate(self)
			} else if event.characters == "c" {
				guard let copyString = currentTicker?.getTimeString(copy: true) else { return }
				NSPasteboard.general.declareTypes([.string], owner: nil)
				NSPasteboard.general.setString(copyString, forType: .string)
			} else if event.characters == "a" {
				showTotals.toggle()
				//			} else if event.characters == "f" { // make this d for vera
				//				showDays.toggle()
				//				Storage.set(showDays, for: .showDays)
			} else if event.characters == "t" {
				showSeconds.toggle()
				Storage.set(showSeconds, for: .showSeconds)
			} else if event.characters == "f" {
				if tickers.count > selectedTicker {
					var newTickers = tickers
					newTickers.remove(at: selectedTicker)
					selectedTicker %= max(1, newTickers.count)
					setTickers(newTickers)
					Storage.set(selectedTicker, for: .selected)
				}
			} else if event.characters == "d" {
				selectedTicker = (selectedTicker + 1) % tickers.count
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "∂" {
				selectedTicker = (tickers.count + selectedTicker - 1) % tickers.count
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "r" {
				if let currentTicker {
					if currentTicker.offsetChange == nil {
						currentTicker.offsetType = .zero
						currentTicker.equivalentOffset = false
						currentTicker.offsetChange = ""
					} else {
						currentTicker.equivalentOffset.toggle()
					}
				}
			} else if event.characters == "3" {
				if let currentTicker {
					if let offset = currentTicker.offsetChange {
						if !offset.starts(with: "-") {
							currentTicker.offsetChange = "-" + offset
						} else {
							currentTicker.offsetChange = String(offset.dropFirst())
						}
					} else {
						currentTicker.offsetType = .neg
						currentTicker.equivalentOffset = false
						currentTicker.offsetChange = ""
					}
				}
			} else if event.characters == "£" {
				if let currentTicker {
					currentTicker.offsetType = .pos
					currentTicker.equivalentOffset = false
					currentTicker.offsetChange = ""
				}
			} else if event.characters == "©" {
				if currentTicker?.offsetChange != nil {
					currentTicker?.resetOffset()
				}
			} else if event.characters == "®" {
				if let currentTicker {
					let newTicker = currentTicker
					newTicker.offsetType = .zero
					newTicker.equivalentOffset = false
					newTicker.offsetChange = showSeconds ? "-22.0" : "-22"
					setCurrentTicker(newTicker.offsetResolved())
				}
			}
			
			updater.toggle()
			return
		}
		
		guard let currentTicker else { return }
		
		if event.characters == " " {
			if currentTicker.offsetChange == nil {
				currentTicker.name += " "
			}
		} else if event.characters == "+" {
			currentTicker.offsetType = .pos
			currentTicker.equivalentOffset = false
			currentTicker.offsetChange = ""
		} else if event.characters == "-" && currentTicker.offsetChange != "" {
			currentTicker.offsetType = .neg
			currentTicker.equivalentOffset = false
			currentTicker.offsetChange = ""
		} else if event.characters == "<" {
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
			guard (flashStart?.timeIntervalSinceNow ?? -2) < -1 else { return }
			if currentTicker.offsetChange != nil {
				if currentTicker.offsetChange == "" {
					currentTicker.offsetChange = nil
				} else {
					currentTicker.offsetChange?.removeLast()
				}
			} else if !currentTicker.name.isEmpty {
				if event.modifierFlags.contains(.option) {
					currentTicker.name = ""
				} else {
					currentTicker.name.removeLast()
				}
			}
		} else if event.specialKey == .carriageReturn {
			guard (flashStart?.timeIntervalSinceNow ?? -2) < -1 else { return }
			setCurrentTicker(currentTicker.offsetResolved())
		} else if event.specialKey == nil {
			guard (flashStart?.timeIntervalSinceNow ?? -2) < -1 else { return }
			if currentTicker.offsetChange != nil {
				for c in (event.characters ?? "").filter({ "0123456789.-".contains($0) }) {
					currentTicker.offsetChange?.append(c)
				}
			} else {
				currentTicker.name += event.characters ?? ""
			}
		}
		
		updater.toggle()
	}
	
	func storeTickers() {
		Storage.set(tickers.map { $0.toDict() }, for: .tickers)
	}
}

func getCurrentTime(withDay: Bool = false) -> (day: String, time: String) {
	let comp = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: .now)
	let hours = comp.hour ?? 0
//	let hours = ((comp.hour ?? 0) + 11) % 12 + 1 // vera's
	return (withDay ? ":" + String(comp.day ?? 0) + "." : ",", tickerString(neg: false, days: withDay ? comp.day ?? 0 : 0, hours: hours, minutes: comp.minute ?? 0, seconds: comp.second ?? 0))
	
	// from base 10
	// let fraction = ((comp.minute ?? 0)*60 + (comp.second ?? 0))/36
	// return String(format: "%01d.%02d", hour, fraction)
}

//func getCurrentDTime() -> String {
//	let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: .now)
//	let hour = comp.hour ?? 0
//	let fraction = ((comp.minute ?? 0)*60 + (comp.second ?? 0))/36
//	return String(format: "%01d.%02d", hour, fraction)
// //	return String(hour*100 + (comp.minute ?? 0))
//}

