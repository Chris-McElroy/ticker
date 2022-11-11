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
        WindowGroup {
			TickerView()
        }
		.windowResizability(.contentSize)
	
    }
}

var deleteTimer: () -> Void = {}

// juicy shit https://stackoverflow.com/questions/64949572/how-to-create-status-bar-icon-menu-with-swiftui-like-in-macos-big-sur
// how i got the quit button, could be useful for other items in the future https://sarunw.com/posts/how-to-make-macos-menu-bar-app/
class StatusBarController {
	static var main: StatusBarController = StatusBarController()
	private var statusBar: NSStatusBar
	private var statusItem: NSStatusItem
	let hotKey = HotKey(key: .t, modifiers: [.command, .option])
	
	init() {
		statusBar = NSStatusBar.init()
		// Creating a status bar item having a fixed length
		statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
		
		if let statusBarButton = statusItem.button {
			statusBarButton.title = "  '  "
		}
		
		// Add a menu and a menu item
		let menu = NSMenu()
		menu.addItem(NSMenuItem(title: "quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
		statusItem.menu = menu
		
		hotKey.keyDownHandler = {
			NSApplication.shared.activate(ignoringOtherApps: true)
		}
	}
	
	@objc func something() {
		print("printing")
	}
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	var statusBar: StatusBarController?
	
	func applicationDidFinishLaunching(_ notification: Notification) {
		if let window = NSApplication.shared.windows.first {
			window.titleVisibility = .hidden
			window.titlebarAppearsTransparent = true
			window.standardWindowButton(NSWindow.ButtonType.closeButton)!.isHidden = true
			window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
			window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
			window.isOpaque = false
			window.hasShadow = false
			window.level = .floating
			window.backgroundColor = NSColor.clear
			window.isReleasedWhenClosed = false
			window.isMovableByWindowBackground = true
			window.collectionBehavior = .canJoinAllSpaces
			window.titlebarSeparatorStyle = .none
			window.delegate = self
		}
		
		//Initialising the status bar
		statusBar = StatusBarController.main
		return
	}
	
	func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
		print("resizing")
		if let window = NSApplication.shared.windows.first {
			window.moveUp(sender)
		}
		return frameSize
	}
	
	func windowWillMove(_ notification: Notification) {
		print("moving")
	}
	
	func windowWillStartLiveResize(_ notification: Notification) {
		print("hiwoef")
	}
	
	func windowShouldClose(_ sender: NSWindow) -> Bool {
		deleteTimer()
		return false
	}
}
