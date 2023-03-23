//
//  KeyPressHelper.swift
//  ticker
//
//  Created by Chris McElroy on 11/10/22.
//

import SwiftUI

var reattachKeyPress: () -> Void = {}

// based off https://stackoverflow.com/a/61155272/8222178
struct KeyPressHelper: NSViewRepresentable {
	let view: KeyView = KeyView()
	
	init(_ keyDownFunc: @escaping (NSEvent) -> Void) {
		view.keyDownFunc = keyDownFunc
	}
	
	class KeyView: NSView {
		var keyDownFunc: (NSEvent) -> Void = { _ in }
		
		override var acceptsFirstResponder: Bool { true }
		
		override func keyDown(with event: NSEvent) {
			keyDownFunc(event)
		}
		
		override func flagsChanged(with event: NSEvent) {
			if event.modifierFlags.contains(.control) {
				showSeconds.toggle()
				Storage.set(showSeconds, for: .showSeconds)
			} else if event.modifierFlags.contains(.capsLock) { // option for chris, capsLock for vera
				showDays.toggle()
				Storage.set(showDays, for: .showDays)
			}
		}
	}

	func makeNSView(context: Context) -> NSView {
		DispatchQueue.main.async { // wait till next event cycle
			view.window?.makeFirstResponder(view)
		}
		reattachKeyPress = reattachKeyPressHelper
		return view
	}

	func updateNSView(_ nsView: NSView, context: Context) {
	}
	
	func reattachKeyPressHelper() {
		DispatchQueue.main.async { // wait till next event cycle
			view.window?.makeFirstResponder(view)
		}
	}
}
