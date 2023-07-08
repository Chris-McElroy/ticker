//
//  WindowHelper.swift
//  ticker
//
//  Created by Chris McElroy on 7/8/23.
//

import SwiftUI

struct WindowHelper {
	static var arrangeSmall: NSAppleScript? = nil
	static var arrangeMedium: NSAppleScript? = nil
	static var arrangeMax: NSAppleScript? = nil
	static var arrangeLeft: NSAppleScript? = nil
	static var arrangeRight: NSAppleScript? = nil
	
	static func refreshScripts() {
		// visible frame should let me avoid the weird menu bar math
		guard let screen = NSScreen.main?.visibleFrame else { return }
		
		arrangeSmall = NSAppleScript(source: getScriptText(
			pos: "{\(screen.width/2 - 400), \(screen.height/2 - 275)}",
			size: "{800, 550}"
		))
		
		arrangeMedium = NSAppleScript(source: getScriptText(
			pos: "{\(screen.width/2 - 650), \(screen.height/2 - 450)}",
			size: "{1300, 900}"
		))
		
		arrangeMax = NSAppleScript(source: getScriptText(
			pos: "{0, 0}",
			size: "{\(screen.width), \(screen.height)}"
		))
		
		arrangeLeft = NSAppleScript(source: getScriptText(
			pos: "{0, 0}",
			size: "{\(screen.width/2), \(screen.height)}"
		))
		
		arrangeRight = NSAppleScript(source: getScriptText(
			pos: "{\(screen.width/2), 0}",
			size: "{\(screen.width/2), \(screen.height)}"
		))
		
		DispatchQueue(label: "windowerCompiler", qos: .userInitiated).async {
			arrangeSmall?.compileAndReturnError(nil)
			arrangeMedium?.compileAndReturnError(nil)
			arrangeMax?.compileAndReturnError(nil)
			arrangeLeft?.compileAndReturnError(nil)
			arrangeRight?.compileAndReturnError(nil)
		}
	}
	
	private static func getScriptText(pos: String, size: String) -> String {
		"""
tell application "System Events" to tell first process where it is frontmost
  set position of window 1 to \(pos)
  set size of window 1 to \(size)
end tell
"""
	}
}
