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
//var checkinThreshold: Double = 2520
var lastAc = 0
var warning = false

// Load framework
let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

struct TickerView: View {
    @State var tickerHistory: [[Ticker]] = {
        var storedTickers = Storage.tickerArray().compactMap { Ticker(from: $0) }
        if ProjectTimer.state == .project {
            storedTickers = storedTickers + [ProjectTimer.getProjectTicker()]
        } else if ProjectTimer.state == .cooldown {
            storedTickers = storedTickers + [ProjectTimer.getCooldownTicker()]
        }
        return [storedTickers]
    }()
	@State var versionsBack: Int = 0
	@State var selectedTicker: Int = Storage.int(.selected)
	@State var isActive: Bool = false
	@State var updater: Bool = false
	@State var blockTime: Date? = nil
	@State var hiding: Bool = false
	@State var flashing: Bool = false
    @State var tabDown: String? = nil
//	@State var nextCheckin: Date? = nil
	@State var activeCountdowns = 2
//	@State var remainingPower: Int = getRemainingPower()
    
    @State var screenResChanged = NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
	
    var tickers: [Ticker] {
        if let projectTicker = ProjectTimer.main {
            tickerHistory[tickerHistory.count - 1 - versionsBack] + [projectTicker]
        } else {
            tickerHistory[tickerHistory.count - 1 - versionsBack]
        }
    }
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
                            .foregroundStyle(tickers[i] as? ProjectTimer != nil ? (ProjectTimer.state == .cooldown ? .purple : .yellow) : .white)
							.background(tickers[i].visible || isActive ? .black.opacity(0.5) : .clear)
					}
					let time = getCurrentTime(withDay: showDays || isActive)
					if !showDays && isActive {
						HStack(spacing: 0) {
							Text(time.day).opacity(0.3)
							Text(time.time)
						}
						.background(.black.opacity(0.5))
						.bold(true)
                    } else {
                        Text((showDays ? time.day : "") + time.time)
							.italic(isActive)
							.background(.black.opacity(0.5))
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
//			nextCheckin = nil
//			for ticker in tickers {
//				ticker.flashing = false
//			}
//			if tickers.isEmpty {
//				setTickers([Ticker()])
//				selectedTicker = 0
//				Storage.set(selectedTicker, for: .selected)
//			}
		}
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
			isActive = false
			showTotals = false
//			setCheckin()
			
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
        .background(KeyPressHelper(keyDownFunc, keyUpFunc))
		.onAppear {
            selectedTicker %= max(1, tickers.count)
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
				updater.toggle()
				monitorTickers()
			})
            print(ProjectTimer.lastEndTime, ProjectTimer.lastStartTime, ProjectTimer.state, selectedTicker)
//			Timer.scheduledTimer(withTimeInterval: 100, repeats: true, block: { _ in
//				remainingPower = getRemainingPower()
//			})
		}
//		.onAppear {
//			wakeFromSleepFunc = {
//				if let (i, walkTicker) = tickers.enumerated().first(where: { $0.element.name.contains("walk") }) {
//					selectedTicker = i
//					let newTicker = walkTicker
//                    guard let start = newTicker.start else { return }
//                    var time = Date().timeIntervalSince(start) + newTicker.offset
//                    if time >= 0 { time += 900 }
//                    let change = Int(time/900)*15
//                    newTicker.offsetType = .neg
//                    newTicker.equivalentOffset = false
//                    newTicker.offsetChange = showSeconds ? "\(change).0" : "\(change)"
//                    setCurrentTicker(newTicker.offsetResolved())
//				}
//			}
//		}
        .onReceive(screenResChanged, perform: { _ in
            redrawWindows()
//                    WindowHelper.refreshScripts()
        })
        .onAppear(perform: redrawWindows)
        .font(Font.custom("Baskerville", size: 14.0))
        .onChange(of: ProjectTimer.lastEndTime, {
            Storage.storeDate(of: .lastEndTime, ProjectTimer.lastEndTime)
        })
        .onChange(of: ProjectTimer.lastStartTime, {
            Storage.storeDate(of: .lastStartTime, ProjectTimer.lastStartTime)
        })
        .onChange(of: ProjectTimer.state, {
            print("changed!", ProjectTimer.state)
            if ProjectTimer.state == .none { // auto deletes cooldown ticker if it goes positive
                while let (i, _) = tickers.enumerated().first(where: { $0.element as? ProjectTimer != nil }) {
                    var newTickers = tickers
                    newTickers.remove(at: i)
                    selectedTicker %= max(1, newTickers.count)
                    setTickers(newTickers)
                    Storage.set(selectedTicker, for: .selected)
                }
            }
            Storage.set(ProjectTimer.state.rawValue, for: .projectTimerState)
        })
	}
	
	func setTickers(_ newTickers: [Ticker]) {
		if versionsBack != 0 {
			tickerHistory.removeLast(versionsBack)
			versionsBack = 0
		}
        if let projectTicker = newTickers.first(where: { $0 as? ProjectTimer != nil }) as? ProjectTimer {
            ProjectTimer.main = projectTicker
        }
        let filteredTickers = newTickers.filter { $0 as? ProjectTimer == nil }
        tickerHistory.append(filteredTickers)
		storeTickers()
	}
	
	func setCurrentTicker(_ newValue: Ticker?) {
		guard let newValue else { return }
		if tickers.isEmpty { return }
        if let projectTicker = newValue as? ProjectTimer {
            print("changing!")
            ProjectTimer.main = projectTicker
        } else {
            var newTickers = tickers
            newTickers[selectedTicker] = newValue
            setTickers(newTickers)
        }
	}
	
	func monitorTickers() {
		let hidingTicker = tickers.enumerated().first(where: { $0.element.flashing && !$0.element.name.contains("\\") })
		let flashingTicker = tickers.enumerated().first(where: { $0.element.flashing && $0.element.name.contains("\\") })
        warning = tickers.enumerated().contains(where: { $0.element.nearlyFlashing })
        AppTimers.updateAppTimers(with: tickers)
		
		if let hidingTicker {
			if !hiding {
				if !isActive {
					selectedTicker = hidingTicker.offset
					blockTime = .now.advanced(by: 1)
//					let executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
//					try! Process.run(executableURL, arguments: ["run", "pause"], terminationHandler: nil)
				}
				hiding = true
			}
			if !isActive {
				NSApplication.shared.activate(ignoringOtherApps: true)
			}
			if !hideWindow.isVisible { hideWindow.setIsVisible(true) }
			hideWindow.orderFront(nil)
		} else {
			hiding = false
			hideWindow.close()
		}
		
		if let flashingTicker {
			if !flashing {
				if hiding {
					flashing = true
					return
				}
				if !isActive {
					selectedTicker = flashingTicker.offset
					blockTime = .now.advanced(by: 1)
					NSApplication.shared.activate(ignoringOtherApps: true)
				}
				flashing = true
			}
		} else {
			flashing = false
		}
        
        handleWarningUpdate()
		
//		if let nextCheckin, nextCheckin <= .now {
//			// assumed to not be active bc it's reset when it's active
//			self.nextCheckin = nil
//			activeCountdowns = tickers.reduce(0, { $0 + ($1.validCountdown ? 1 : 0) })
//			if activeCountdowns < 1 || flashing {
//				if let flashingTicker {
//					selectedTicker = flashingTicker.offset
//				}
//				blockTime = .now.advanced(by: 1)
//				NSApplication.shared.activate(ignoringOtherApps: true)
//			}
//		}
	}
	
//	func setCheckin() {
//		if flashing {
//			nextCheckin = .now.advanced(by: 60)
//			return
//		}
//		
//		checkinThreshold = abs(tickers.first(where: { $0.name == "checkin" })?.offset ?? 2520)
//		if checkinThreshold < 60 { return }
//		tickers.forEach { _ = $0.getTimeString() }
//		activeCountdowns = tickers.reduce(0, { $0 + ($1.validCountdown ? 1 : 0) })
//		if activeCountdowns < 1 {
//			nextCheckin = .now.advanced(by: 300)
//		}
//	}
	
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
                currentTicker?.resetOffset(eq: false)
			} else {
				NSApplication.shared.hide(nil)
				NSApplication.shared.unhideWithoutActivation()
			}
			
			updater.toggle()
		}
		
        if event.specialKey == .tab {
            if tabDown == nil { tabDown = "" }
        } else if let tabDown, event.characters != "" {
            self.tabDown = tabDown + (event.characters ?? "")
            return
        }
        
        if event.modifierFlags.contains(.command) {
            if event.characters == "s" { // vera may want to change this back to space, along with other changes
                if let currentTicker {
                    setCurrentTicker(currentTicker.activityToggled())
                }
            } else if event.characters == "w" {
                NSApplication.shared.hide(nil)
                NSApplication.shared.unhideWithoutActivation()
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
                selectedTicker %= max(1, tickers.count)
//			} else if event.characters == "œ" {
//				NSApp.terminate(self)
			} else if event.characters == "c" {
				guard let copyString = currentTicker?.getTimeString(copy: true) else { return }
				NSPasteboard.general.declareTypes([.string], owner: nil)
				NSPasteboard.general.setString(copyString, forType: .string)
			} else if event.characters == "a" {
				showTotals.toggle()
			} else if event.characters == "i" { // make this d for vera
				showDays.toggle()
				Storage.set(showDays, for: .showDays)
			} else if event.characters == "t" {
				showSeconds.toggle()
				Storage.set(showSeconds, for: .showSeconds)
			} else if event.characters == "f" {
				if tickers.count > selectedTicker {
					var newTickers = tickers
                    if let projectTicker = currentTicker as? ProjectTimer {
                        if ProjectTimer.cooldownEndTime < .now {
                            ProjectTimer.main = nil
                            selectedTicker %= max(1, tickers.count)
                            ProjectTimer.state = .none
                        } else if ProjectTimer.state == .project {
                            if projectTicker.wasNegative || ProjectTimer.activeProject {
                                print("set last end time")
                                ProjectTimer.lastEndTime = .now
                            }
                            ProjectTimer.main = ProjectTimer.getCooldownTicker()
                            print("pt", ProjectTimer.main?.getTimeString(), tickers.last?.getTimeString())
                        } else {
                            projectTicker.visible = false
                        }
                    } else {
                        newTickers.remove(at: selectedTicker)
                        selectedTicker %= max(1, newTickers.count)
                    }
					setTickers(newTickers)
					Storage.set(selectedTicker, for: .selected)
				}
			} else if event.characters == "d" {
				selectedTicker = (selectedTicker + 1) % tickers.count
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "∂" {
				selectedTicker = (tickers.count + selectedTicker - 1) % tickers.count
				Storage.set(selectedTicker, for: .selected)
			} else if event.characters == "®" { // option r
				if let currentTicker {
					if currentTicker.offsetChange == nil {
						currentTicker.offsetType = .zero
						currentTicker.equivalentOffset = false
						currentTicker.offsetChange = ""
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
			} else if event.characters == "£" { // option 3
				if let currentTicker {
					currentTicker.offsetType = .pos
					currentTicker.equivalentOffset = false
					currentTicker.offsetChange = ""
				}
			} else if event.characters == "©" { // option g
				if currentTicker?.offsetChange != nil {
                    currentTicker?.resetOffset(eq: false)
				}
			} else if event.characters == "r" {
                if let currentTicker {
                    currentTicker.offsetType = .zero
                    currentTicker.equivalentOffset = true
                    if currentTicker.offsetChange == nil {
                        currentTicker.offsetChange = ""
                    }
                }
//				if let currentTicker {
//					let newTicker = currentTicker
//                    guard let start = newTicker.start else { return }
//                    var time = Date().timeIntervalSince(start) + newTicker.offset
//                    if time >= 0 { time += 900 }
//                    let change = Int(time/900)*15
//                    newTicker.offsetType = .neg
//                    newTicker.equivalentOffset = false
//                    newTicker.offsetChange = showSeconds ? "\(change).0" : "\(change)"
//                    setCurrentTicker(newTicker.offsetResolved())
//				}
            } else if event.characters == "´" { // option e
                guard ProjectTimer.state == .none else { return }
                guard ProjectTimer.main == nil else { return }
                ProjectTimer.main = ProjectTimer()
                selectedTicker = tickers.count - 1
                Storage.set(selectedTicker, for: .selected)
            }
			
			updater.toggle()
			return
		}
		
		guard let currentTicker else { return }
		
		if event.characters == "+" {
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
            if currentTicker.offsetChange != nil {
                setCurrentTicker(currentTicker.offsetResolved())
                return
            }
//			selectedTicker = (selectedTicker + 1) % tickers.count
//			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .backTab {
//			selectedTicker = (tickers.count + selectedTicker - 1) % tickers.count
//			Storage.set(selectedTicker, for: .selected)
		} else if event.specialKey == .delete {
			guard (blockTime ?? .now) <= .now else { return }
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
			guard (blockTime ?? .now) <= .now else { return }
			setCurrentTicker(currentTicker.offsetResolved())
		} else if event.specialKey == nil {
			guard (blockTime ?? .now) <= .now else { return }
			if currentTicker.offsetChange != nil {
				for c in (event.characters ?? "").filter({ "0123456789.-;".contains($0) }) {
					currentTicker.offsetChange?.append(c)
				}
			} else {
				currentTicker.name += event.characters ?? ""
			}
		}
		
		updater.toggle()
	}
    
    func keyUpFunc(event: NSEvent) {
        if event.specialKey == .tab {
            if let tabDown, tabDown != "" {
                let newTicker = Ticker()
                newTicker.name = tabDown
                newTicker.offsetChange = ""
                newTicker.offsetType = .neg
                setTickers([newTicker] + tickers)
                selectedTicker = 0
                Storage.set(selectedTicker, for: .selected)
                self.tabDown = nil
            }
        }
    }
	
	func storeTickers() {
		Storage.set(tickers.compactMap { $0.toDict() }, for: .tickers)
	}
}

func getCurrentTime(withDay: Bool = false) -> (day: String, time: String) {
	let comp = Calendar.current.dateComponents([.day, .hour, .minute, .second, .weekday], from: .now)
	let hours = comp.hour ?? 0
	let weekday = ["x", "u", "m", "t", "w", "r", "f", "s"][comp.weekday ?? 0]
//	let hours = ((comp.hour ?? 0) + 11) % 12 + 1 // vera's
    return (weekday + ":" + String(comp.day ?? 0) + ".", (hours == 0 ? "0." : "") + tickerString(neg: false, days: 0, hours: hours, minutes: comp.minute ?? 0, seconds: comp.second ?? 0))
//    return (weekday + ":" + String(comp.day ?? 0) + ".", (showDays ? weekday + ":" : (withDay ? "" : ",")) + tickerString(neg: false, days: showDays ? comp.day ?? 0 : 0, hours: hours, minutes: comp.minute ?? 0, seconds: comp.second ?? 0))
	
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

