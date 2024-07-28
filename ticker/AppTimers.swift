//
//  AppTimers.swift
//  ticker
//
//  Created by 4 on '24.7.24.
//

import SwiftUI

var spotifyEnabled: Bool = false
var anyTimer: Bool = false
var hidesRemaining: [pid_t: Int] = [:]
var finderApp: NSRunningApplication? = nil
//var hideTimer: Timer?

func tryToHide(app: NSRunningApplication, launched: Bool = false) {
    guard !appAllowed(app) else { return }
    app.hide()
    var repeats = 0
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { t in
        if repeats == 0 && launched { app.activate(options: .activateAllWindows); app.unhide(); finderApp?.activate() }
//        print("hiding!", app.bundleIdentifier ?? "", app.isHidden ? "hidden" : "visible", app.isActive ? "active" : "")
        guard !appAllowed(app) else { t.invalidate(); return }
        if repeats == 7 && app.isActive { print("redoing"); app.activate(options: .activateAllWindows); app.unhide(); finderApp?.activate() }
        app.hide()
        repeats += 1
        if repeats == 10 { t.invalidate() }
    })
}

func appAllowed(_ app: NSRunningApplication) -> Bool {
    let appID = app.bundleIdentifier
    // for testing
//    if appID == "com.apple.dt.Xcode" { return true }
    // avoiding hide fighting
    if appID == "com.apple.finder" || appID == "chris.ticker" {
        if appID == "com.apple.finder" { finderApp = app }
        return true
    }
    // spotify rule
    if appID == "com.spotify.client" { return spotifyEnabled }
    // other app rule
    return anyTimer
}

//func startHideTimer() {
//    hideTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
//        if !hidesRemaining.isEmpty { print("hiding!") }
//        for pid in hidesRemaining.keys {
//            guard let app = NSRunningApplication(processIdentifier: pid) else { print("problem!"); return }
//            if appAllowed(app) { hidesRemaining[pid] = nil }
//            app.hide()
//            hidesRemaining[pid, default: 1] -= 1
//            if hidesRemaining[pid, default: 0] <= 0 { hidesRemaining[pid] = nil }
//        }
//    })
//}


