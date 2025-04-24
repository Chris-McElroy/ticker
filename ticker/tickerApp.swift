//
//  tickerApp.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI
import HotKey
import FirebaseCore

@main
struct tickerApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
    var body: some Scene {
        Settings { }
//		WindowGroup(id: "main") {
//			TickerView()
//        }
//		.windowResizability(.contentSize)
//        .windowStyle(.hiddenTitleBar)
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

var tickerWindow = MyWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 500), styleMask: [], backing: .buffered, defer: false)
var hideWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: [], backing: .buffered, defer: false)
var warningWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100), styleMask: [], backing: .buffered, defer: false)
var currentScreen = NSRect(x: 0, y: 0, width: 1000, height: 1000)
//var wakeFromSleepFunc: (() -> Void)? = nil

func redrawWindows() {
//    setBrightness()
    
	guard let screenSize = NSScreen.main?.frame else { return }
	hideWindow.setFrame(NSRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), display: false)
    warningWindow.setFrame(NSRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height), display: false)
	
//	guard let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main-AppWindow-1" }) else { return }
	tickerWindow.setFrameOrigin(NSPoint(x: screenSize.width - 500, y: 0))
}

func handleWarningUpdate() {
    if warning {
        if !warningWindow.isVisible { warningWindow.setIsVisible(true) }
//        warningWindow.makeKeyAndOrderFront(nil)
//        warningWindow.o´rderFront(nil)
    } else {
        warningWindow.close()
    }
}

class MyWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

//func setBrightness() {
//    let executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
//    if NSScreen.main?.frame.width ?? 0 > 1512 {
//        try! Process.run(executableURL, arguments: ["run", "dim"], terminationHandler: nil)
//    }
//}

//let projectKey = HotKey(key: .z, modifiers: [.option])
//let consumeKey = HotKey(key: .four, modifiers: [.option])

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//	var statusBar: StatusBarController?
	let activationKey = HotKey(key: .c, modifiers: [.control])
    let quitKey = HotKey(key: .c, modifiers: [.control, .option])
    
	// vera's keys:
//	let activationKey = HotKey(key: .z, modifiers: [.command, .option])
//	let clickableKey = HotKey(key: .a, modifiers: [.option, .shift])
	
//    let arrangeSmallKey = HotKey(key: .q, modifiers: [.command, .option])
//	let arrangeMediumKey = HotKey(key: .a, modifiers: [.command, .option])
//	let arrangeMaxKey = HotKey(key: .z, modifiers: [.command, .option])
//    let arrangeFullKey = HotKey(key: .return, modifiers: [.command, .option])
//    let arrangeLeftKey = HotKey(key: .one, modifiers: [.command])
//    let arrangeRightKey = HotKey(key: .two, modifiers: [.command])
    
    
//    let arrangeSmallerKey = HotKey(key: .downArrow, modifiers: [.command, .option])
//    let arrangeLargerKey = HotKey(key: .upArrow, modifiers: [.command, .option])
//    let arrangeCenterKey = HotKey(key: .rightShift, modifiers: [.command, .option])
//    let arrangeFullKey = HotKey(key: .return, modifiers: [.command, .option])
//    let arrangeLeftKey = HotKey(key: .leftArrow, modifiers: [.command, .option])
//    let arrangeRightKey = HotKey(key: .rightArrow, modifiers: [.command, .option])
	
	func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        setupWindow()
        
        NSApp.setActivationPolicy(.accessory)
		hideWindow.isReleasedWhenClosed = false
		hideWindow.backgroundColor = NSColor.black
        warningWindow.isReleasedWhenClosed = false
        warningWindow.ignoresMouseEvents = true
        warningWindow.level = .screenSaver
        warningWindow.backgroundColor = NSColor.magenta.withAlphaComponent(0.2)
		redrawWindows()
//		WindowHelper.refreshScripts()
		
		activationKey.keyDownHandler = {
			NSApplication.shared.activate(ignoringOtherApps: true)
		}
        
        quitKey.keyDownHandler = {
            NSApp.terminate(nil)
        }
		
//        arrangeSmallKey.keyDownHandler = {
//			DispatchQueue(label: "windower", qos: .userInitiated).async {
//				WindowHelper.arrangeSmall?.executeAndReturnError(nil)
//			}
//		}
//		
//        arrangeMediumKey.keyDownHandler = {
//			DispatchQueue(label: "windower", qos: .userInitiated).async {
//				WindowHelper.arrangeMedium?.executeAndReturnError(nil)
//			}
//		}
//        
//        arrangeMaxKey.keyDownHandler = {
//            DispatchQueue(label: "windower", qos: .userInitiated).async {
//                WindowHelper.arrangeMax?.executeAndReturnError(nil)
//            }
//        }
//        
//        arrangeFullKey.keyDownHandler = {
//            DispatchQueue(label: "windower", qos: .userInitiated).async {
//                WindowHelper.arrangeLeft?.executeAndReturnError(nil)
//            }
//        }
		
//		arrangeLeftKey.keyDownHandler = {
//			DispatchQueue(label: "windower", qos: .userInitiated).async {
//				WindowHelper.arrangeLeft?.executeAndReturnError(nil)
//			}
//		}
//		
//		arrangeRightKey.keyDownHandler = {
//			DispatchQueue(label: "windower", qos: .userInitiated).async {
//				WindowHelper.arrangeRight?.executeAndReturnError(nil)
//			}
//		}
		
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
		
//		let notificationCenter = NSWorkspace.shared.notificationCenter
//		notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: nil, using: { _ in
//			wakeFromSleepFunc?()
//		})
        
        // hiding and unhiding
//        notificationCenter.addObserver(forName: NSWorkspace.didHideApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
//        notificationCenter.addObserver(forName: NSWorkspace.didUnhideApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
        
        // activating and deactivating
//        notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
//        notificationCenter.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
        
        // launching
//        notificationCenter.addObserver(forName: NSWorkspace.willLaunchApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
//        notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: {
//            AppTimers.handleAppChange(for: $0)
//        })
        
		return
	}
	
	func setupWindow() {
        tickerWindow.contentView = NSHostingView(rootView: TickerView())
//        tickerWindow.styleMask = .borderless
        tickerWindow.level = .floating
        tickerWindow.backgroundColor = NSColor.clear
        tickerWindow.isMovableByWindowBackground = false
        tickerWindow.collectionBehavior = .canJoinAllSpaces
        tickerWindow.ignoresMouseEvents = true // comment this out for clickability (vera's)
        tickerWindow.delegate = self
        tickerWindow.orderFrontRegardless()
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
	
//	func windowShouldClose(_ sender: NSWindow) -> Bool {
//        print("got window close!")
//		NSApplication.shared.hide(nil)
//		NSApplication.shared.unhideWithoutActivation()
//		return false
//	}
}
