//
//  AppTimers.swift
//  ticker
//
//  Created by 4 on '24.7.24.
//

import SwiftUI

class AppTimers {
    static var anyAppsEnabled: Bool = false
    static var enabledList: [Character: Bool] = [:]
    static var allApps: [String: AppInfo] = [:]
    
    static func handleAppChange(for notification: Notification) {
        guard let info = notification.userInfo?["NSWorkspaceApplicationKey"], let app = info as? NSRunningApplication else { return }
        // add to list of apps
        if allApps[app.id] == nil { allApps[app.id] = AppInfo(app) }
        // check if allowed
        guard !appAllowed(app) else { return }
        // check if hidden
        if app.isTerminated || app.isHidden {
            print("fixed", app.id, app.isTerminated, app.isHidden, app.isActive)
            allApps[app.id]?.fixAttemps = nil
            return
        }
        // try to hide
        app.hide()
        // start tracking for later
        if allApps[app.id]?.fixAttemps == nil {
            allApps[app.id]?.fixAttemps = 0
        }
        print("trying to hide", app.id)
    }
    
    static func appAllowed(_ app: NSRunningApplication) -> Bool {
        // for testing
//        if app.id == apps.xcode.id { return true }
        // avoiding hide fighting
        if app.id == apps.finder.id || app.id == apps.ticker.id {
            if app.id == apps.finder.id { allApps[apps.finder.id] = AppInfo(app) } // TODO remove
            return true
        }
        // background apps
        if app.id == apps.endel.id { return true }
        // main app rules
        if app.id == apps.spotify.id { return enabledList["3", default: false] }
        if app.id == apps.texts.id || app.id == apps.signal.id || app.id == apps.imessage.id { return enabledList["a", default: false] }
        if app.id == apps.mail.id { return enabledList["v", default: false] }
        if app.id == apps.safari.id { return enabledList["w", default: false] }
        if app.id == apps.xcode.id { return enabledList["x", default: false] }
        if [apps.zotero.id, apps.word.id, apps.excel.id, apps.teams.id].contains(app.id) { return enabledList["c", default: false] }
        // other app rule
        return anyAppsEnabled
    }

    static func updateAppTimers(with tickers: [Ticker]) {
        // update which apps are enabled
        let charList = "1234qwerasdfzxcv"
        let appTimerTickers: [Ticker] = tickers.filter { $0.name != "" && $0.name.allSatisfy({ charList.contains($0) }) && $0.wasNegative }
        anyAppsEnabled = !appTimerTickers.isEmpty
        for char in charList {
            enabledList[char] = appTimerTickers.contains { $0.name.contains(char) }
        }
        
        // check current apps
        for (id, app) in allApps {
            guard let fixAttempts = app.fixAttemps else { continue }
            if appAllowed(app.main) {
                app.fixAttemps = nil
                continue
            }
            // TODO use app.main.ownsMenuBar that's so much better
            // and see if i can find a way to get apps to unfullscreen themselves if they do
            if app.main.isTerminated || app.main.isHidden {
                print("fixed 2", id, app.main.isTerminated, app.main.isHidden, app.main.isActive)
                app.fixAttemps = nil
                continue
            }
            if fixAttempts == 6 {
                allApps[apps.finder.id]?.main.activate()
            }
            
            if fixAttempts == 10 {
                app.main.unhide()
                app.main.activate(options: .activateAllWindows)
                allApps[apps.finder.id]?.main.activate()
            }
            if fixAttempts == 30 {
                app.main.terminate()
            }
            app.fixAttemps = fixAttempts + 1
        }
    }

    enum apps: String {
        case xcode = "com.apple.dt.Xcode"
        case finder = "com.apple.finder"
        case ticker = "chris.ticker"
        case spotify = "com.spotify.client"
        case texts = "com.kishanbagaria.jack"
        case safari = "com.apple.Safari"
        case signal = "org.whispersystems.signal-desktop"
        case imessage = "com.apple.MobileSMS"
        case mail = "com.apple.mail"
        case zotero = "org.zotero.zotero-beta"
        case word = "com.microsoft.Word"
        case excel = "com.microsoft.Excel"
        case teams = "com.microsoft.teams2"
        case endel = "com.endel.endel"
        
        var id: String { rawValue }
    }

    class AppInfo {
        var main: NSRunningApplication
        var fixAttemps: Int? = nil
        
        init(_ main: NSRunningApplication) {
            self.main = main
        }
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

    
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { t in
//            //        if repeats == 0 && launched { app.activate(options: .activateAllWindows); app.unhide(); finderApp?.activate() }
//            //        print("hiding!", app.bundleIdentifier ?? "", app.isHidden ? "hidden" : "visible", app.isActive ? "active" : "")
//            guard !appAllowed(app) else { t.invalidate(); return }
//            //        if repeats == 7 && app.isActive { print("redoing"); app.activate(options: .activateAllWindows); app.unhide(); finderApp?.activate() }
//            if app.isActive {
//                print(app.bundleIdentifier ?? "", "still active", app.isHidden)
//            }
//            app.hide()
//            repeats += 1
//            if repeats == 10 { t.invalidate() }
//        })
}

extension NSRunningApplication {
    var id: String { bundleIdentifier ?? "" }
}

