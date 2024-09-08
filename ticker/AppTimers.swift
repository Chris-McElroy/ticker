//
//  AppTimers.swift
//  ticker
//
//  Created by 4 on '24.7.24.
//

import SwiftUI

class AppTimers {
    static var anyAppsEnabled: Bool = false
    static var enabledList: Set<Character> = []
    static var allApps: [String: AppInfo] = [:]
    
    static func handleAppChange(for notification: Notification) {
        guard let info = notification.userInfo?["NSWorkspaceApplicationKey"], let apphandle = info as? NSRunningApplication else { return }
        handleWarningUpdate()
        // add to list of apps
        let app = AppInfo(apphandle)
        if allApps[app.id] == nil { allApps[app.id] = app }
        // check if allowed
        guard !appAllowed(app) else { return }
        // check if hidden
        if app.main.isTerminated || app.main.isHidden {
            print("fixed", app.id, app.main.isTerminated, app.main.isHidden, app.main.isActive)
            allApps[app.id]?.fixAttemps = nil
            return
        }
        // try to hide
        app.main.hide()
        // start tracking for later
        if allApps[app.id]?.fixAttemps == nil {
            allApps[app.id]?.fixAttemps = 0
        }
        print("trying to hide", app.id)
    }
    
    static func appAllowed(_ app: AppInfo) -> Bool {
        // everything allowed while ticker is front
        if allApps[apps.ticker.id]?.main.isActive ?? false { return true }
        
        // for testing
//        if app.id == apps.xcode.id { return true }
        // avoiding hide fighting
        if app.id == apps.finder.id || app.id == apps.ticker.id {
            return true
        }
        // main app rules
        if let key = app.key {
            return enabledList.contains(key)
        }
        // other app rule
        return anyAppsEnabled
    }

    static func updateAppTimers(with tickers: [Ticker]) {
        // update which apps are enabled
        let charList = "1234qwerasdfgzxcv "
        let appTimerTickers: [Ticker] = tickers.filter { $0.name.drop(while: { $0 == " " }) != "" && $0.name.allSatisfy({ charList.contains($0) }) && ($0.wasNegative || $0.flashing) }
        anyAppsEnabled = !appTimerTickers.isEmpty
        let newEnabledList: Set<Character> = Set(appTimerTickers.flatMap({ $0.name }))
        let checkAllApps = newEnabledList == enabledList
        enabledList = newEnabledList
        
        // check current apps
        for (id, app) in allApps {
            if !checkAllApps {
                guard app.fixAttemps != nil else { continue }
            }
            if appAllowed(app) {
                app.fixAttemps = nil
                continue
            } else if app.fixAttemps == nil {
                app.main.hide()
                app.fixAttemps = 0
                continue
            }
            // TODO use app.main.ownsMenuBar that's so much better
            // and see if i can find a way to get apps to unfullscreen themselves if they do
            if app.main.isTerminated || app.main.isHidden {
                print("fixed 2", id, app.main.isTerminated, app.main.isHidden, app.main.isActive)
                app.fixAttemps = nil
                continue
            }
            if app.fixAttemps == 6 {
                allApps[apps.finder.id]?.main.activate()
            }
            
            if app.fixAttemps == 10 {
                app.main.unhide()
                app.main.activate(options: .activateAllWindows)
                allApps[apps.finder.id]?.main.activate()
            }
            if app.fixAttemps == 30 {
                app.main.terminate()
            }
            app.fixAttemps = (app.fixAttemps ?? -1) + 1
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
        case music = "com.apple.Music"
        case orion = "com.kagi.kagimacOS"
        case arc = "company.thebrowser.Browser"
        case chrome = "com.google.Chrome"
        case firefox = "org.mozilla.firefox"
        case whatsapp = "net.whatsapp.WhatsApp"
        case settings = "com.apple.systempreferences"
        case alfred = "com.runningwithcrayons.Alfred-Preferences"
        case shortcuts = "com.apple.shortcuts"
        case shortery = "com.shortery-app.Shortery"
        case tinkertool = "com.bresink.system.tinkertool"
        case btt = "com.hegenberg.BetterTouchTool"
        case karabiner = "org.pqrs.Karabiner-Elements.Settings"
        case cubetimer = "org.cubesense.cubesenseapp"
        case vscode = "com.microsoft.VSCode"
        case rstudio = "com.rstudio.desktop"
        case warp = "dev.warp.Warp-Stable"
        case sublime = "com.sublimetext.4"
        case powerpoint = "com.microsoft.Powerpoint"
        case outlook = "com.microsoft.Outlook"
        case pdfreader = "com.pspdfkit.viewer"
        case books = "com.apple.iBooksX"
        
        var id: String { rawValue }
        
        func key() -> Character? {
            switch self {
            case .spotify, .music: return "3"
            case .pdfreader, .books: return "4"
            case .safari, .orion, .arc, .chrome, .firefox: return "w"
            case .texts, .signal, .imessage, .whatsapp: return "a"
            case .settings, .alfred, .shortcuts, .shortery, .tinkertool, .btt, .karabiner: return "g"
            case .cubetimer: return "z"
            case .xcode, .vscode, .rstudio, .warp, .sublime: return "x"
            case .zotero, .word, .excel, .teams, .powerpoint: return "c"
            case .mail, .outlook: return "v"
            default: return nil
            }
        }
    }

    class AppInfo {
        var main: NSRunningApplication
        var fixAttemps: Int? = nil
        let id: String
        let key: Character?
        
        init(_ main: NSRunningApplication) {
            self.main = main
            self.id = main.id
            self.key = apps(rawValue: main.id)?.key()
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

