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
	
    var body: some Scene {
		WindowGroup() {
			TickerView()
        }
		.windowResizability(.contentSize)
    }
}

var deleteTimer: () -> Void = {}

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
//			NSApplication.shared.activate(ignoringOtherApps: true)
//		}
//	}
//}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//	var statusBar: StatusBarController?
	let activationKey = HotKey(key: .three, modifiers: [.command])
//	let clickableKey = HotKey(key: .three, modifiers: [.command, .shift])
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		if let window = NSApplication.shared.windows.first {
			setupWindow(window)
		}
		
		activationKey.keyDownHandler = {
			NSApplication.shared.activate(ignoringOtherApps: true)
		}
		
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
//			window.contentView = NSHostingView(rootView: view)
//			window.makeKeyAndOrderFront(nil)
		
		//Initialising the status bar
//		statusBar = StatusBarController.main
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
		window.ignoresMouseEvents = true
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
	
	func windowShouldClose(_ sender: NSWindow) -> Bool {
		deleteTimer()
		return false
	}
}
