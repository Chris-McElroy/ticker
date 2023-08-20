//
//  tickerApp.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import HotKey

@main
struct tickerApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	var screenResChanged = NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
	
    var body: some Scene {
		WindowGroup(id: "main") {
			TickerView()
				.onReceive(screenResChanged, perform: { _ in
					redrawWindows()
					WindowHelper.refreshScripts()
				})
				.onAppear(perform: redrawWindows)
        }
		.windowResizability(.contentSize)
    }
}

// juicy shit https://stackoverflow.com/questions/64949572/how-to-create-status-bar-icon-menu-with-swiftui-like-in-macos-big-sur
// how i got the quit button, could be useful for other items in the future https://sarunw.com/posts/how-to-make-macos-menu-bar-app/
//class StatusBarController {
//	static var main: StatusBarController = StatusBarController()
//	private var statusBar: NSStatusBar
//	private var statusItem: NSStatusItem
//	let hotKey = HotKey(key: .t, modifiers: [.command, .option])
//
//	init() {
//		statusBar = NSStatusBar.init()
//		// Creating a status bar item having a fixed length
//		statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
//
//		if let statusBarButton = statusItem.button {
//			statusBarButton.title = "  '  "
//		}
//
//		// Add a menu and a menu item
//		let menu = NSMenu()
//		menu.addItem(NSMenuItem(title: "quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
//		statusItem.menu = menu
//
//		hotKey.keyDownHandler = {
//			NSApmplication.shared.activate(ignoringOtherApps: true)
//		}
//	}
//}

var hideWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: [], backing: .buffered, defer: false)
var currentScreen = NSRect(x: 0, y: 0, width: 1000, height: 1000)
var wakeFromSleepFunc: (() -> Void)? = nil

func redrawWindows() {
	guard let screenSize = NSScreen.main?.frame else { return }
	hideWindow.setFrame(NSRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), display: false)
	
	guard let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main-AppWindow-1" }) else { return }
	window.setFrameOrigin(NSPoint(x: screenSize.width - 500, y: 0))
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//	var statusBar: StatusBarController?
	let activationKey = HotKey(key: .a, modifiers: [.option])
	// vera's keys:
//	let activationKey = HotKey(key: .z, modifiers: [.command, .option])
//	let clickableKey = HotKey(key: .a, modifiers: [.option, .shift])
	
	let arrangeSmallKey = HotKey(key: .q, modifiers: [.command, .option])
	let arrangeMediumKey = HotKey(key: .a, modifiers: [.command, .option])
	let arrangeMaxKey = HotKey(key: .z, modifiers: [.command, .option])
	let arrangeLeftKey = HotKey(key: .one, modifiers: [.command])
	let arrangeRightKey = HotKey(key: .two, modifiers: [.command])
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main-AppWindow-1" }) {
			setupWindow(window)
		}
		
		hideWindow.isReleasedWhenClosed = false
		hideWindow.backgroundColor = NSColor.black
		redrawWindows()
		WindowHelper.refreshScripts()
		
		activationKey.keyDownHandler = {
			NSApplication.shared.activate(ignoringOtherApps: true)
		}
		
		arrangeSmallKey.keyDownHandler = {
			DispatchQueue(label: "windower", qos: .userInitiated).async {
				WindowHelper.arrangeSmall?.executeAndReturnError(nil)
			}
		}
		
		arrangeMediumKey.keyDownHandler = {
			DispatchQueue(label: "windower", qos: .userInitiated).async {
				WindowHelper.arrangeMedium?.executeAndReturnError(nil)
			}
		}
		
		arrangeMaxKey.keyDownHandler = {
			DispatchQueue(label: "windower", qos: .userInitiated).async {
				WindowHelper.arrangeMax?.executeAndReturnError(nil)
			}
		}
		
		arrangeLeftKey.keyDownHandler = {
			DispatchQueue(label: "windower", qos: .userInitiated).async {
				WindowHelper.arrangeLeft?.executeAndReturnError(nil)
			}
		}
		
		arrangeRightKey.keyDownHandler = {
			DispatchQueue(label: "windower", qos: .userInitiated).async {
				WindowHelper.arrangeRight?.executeAndReturnError(nil)
			}
		}
		
		// vera's
//		clickableKey.keyDownHandler = {
//			guard let window = NSApplication.shared.windows.first else { return }
//			if !window.ignoresMouseEvents {
//				window.ignoresMouseEvents = true
//				return
//			}
//			let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
//			let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
//			let task = Process()
//			task.launchPath = "/usr/bin/open"
//			task.arguments = [path]
//			task.launch()
//			exit(0)
//		}
		
			// code to make a new window, did not work very well
//			var rect = NSRect(x: 0, y: 0, width: 500, height: 500)
//			for window in NSApplication.shared.windows where window.isOnActiveSpace {
//				rect = window.frame
//				window.close()
//			}
//			var window = NSWindow( contentRect: rect, styleMask: [], backing: .buffered, defer: false)
//			self.setupWindow(window)
//			reattachKeyPress()
//			let view = TickerView()
//
//			window.contentfView = NSHostingView(rootView: view)
//			window.makeKeyAndOrderFront(nil)
		
		// Initialising the status bar
//		statusBar = StatusBarController.main
		
		let notificationCenter = NSWorkspace.shared.notificationCenter
		notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: nil, using: { _ in
			wakeFromSleepFunc?()
		})
		
		return
	}
	
	func setupWindow(_ window: NSWindow) {
		window.titleVisibility = .hidden
		window.titlebarAppearsTransparent = true
		window.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
		window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
		window.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
		window.isOpaque = false
		window.hasShadow = false
		window.level = .floating
		window.backgroundColor = NSColor.clear
		window.isReleasedWhenClosed = false
		window.isMovableByWindowBackground = true
		window.collectionBehavior = .canJoinAllSpaces
		window.titlebarSeparatorStyle = .none
		window.ignoresMouseEvents = true // comment this out for clickability (vera's)
		window.delegate = self
	}
	
//	// https://stackoverflow.com/questions/70091919/how-set-position-of-window-on-the-desktop-in-swiftui
//	func fakeWindowPositionPreferences() {
//		guard let main = NSScreen.main else { return }
//
//		let screenWidth = main.frame.width
//		let screenHeightWithoutMenuBar = main.frame.height - 32 // menu bar
//		let visibleFrame = main.visibleFrame
//
//		let contentWidth: CGFloat = 100
//		let contentHeight: CGFloat = 200 + 28 // window title bar
//
//		let windowX = visibleFrame.midX - contentWidth/2
//		let windowY = visibleFrame.midY - contentHeight/2
//
//		let newFramePreference = "\(Int(windowX)) \(Int(windowY)) \(Int(contentWidth)) \(Int(contentHeight)) 0 0 \(Int(screenWidth)) \(Int(screenHeightWithoutMenuBar))"
//		UserDefaults.standard.set("1450 0 44 126 0 0 1512 950 ", forKey: "NSWindow Frame cornerPos")
//	}
	
//	func application
	
	func windowShouldClose(_ sender: NSWindow) -> Bool {
		NSApplication.shared.hide(nil)
		NSApplication.shared.unhideWithoutActivation()
		return false
	}
}
