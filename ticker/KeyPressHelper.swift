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
	
	init(_ keyDownFunc: @escaping (NSEvent) -> Void, _ keyUpFunc: @escaping (NSEvent) -> Void) {
		view.keyDownFunc = keyDownFunc
        view.keyUpFunc = keyUpFunc
	}
	
	class KeyView: NSView {
		var keyDownFunc: (NSEvent) -> Void = { _ in }
        var keyUpFunc: (NSEvent) -> Void = { _ in }
		
		override var acceptsFirstResponder: Bool { true }
		
		override func keyDown(with event: NSEvent) {
			keyDownFunc(event)
		}
        
        override func keyUp(with event: NSEvent) {
            keyUpFunc(event)
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
