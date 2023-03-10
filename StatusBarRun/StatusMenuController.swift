//
//  StatusMenuController.swift
//  StatusBarRun
//
//  Created by Simon Meusel on 11.06.17.
//  Copyright © 2017 Simon Meusel. All rights reserved.
//

import Cocoa
import Foundation
import SwiftyJSON

class StatusMenuController: NSObject, NSApplicationDelegate {
    
    let zeroWidthSpace = "​";
    
    // Create status item in system status bar
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    // Status menu
    let statusMenu = NSMenu()
    // StatusBarRun submenu
    @IBOutlet weak var statusBarRunMenuItem: NSMenuItem!
    
    var hotkeyManager: HotkeyManager?
    var map: [String:JSON] = [:]
    
    @IBAction func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func enableLoginItem(_ sender: NSMenuItem) {
        LoginItem.setEnabled(enabled: true)
    }
    
    @IBAction func disableLoginItem(_ sender: NSMenuItem) {
        LoginItem.setEnabled(enabled: false)
    }
    
    @IBAction func editConfig(_ sender: NSMenuItem) {
        // Open config in default editor
        let process = Process();
        process.launchPath = "/usr/bin/open"
        process.arguments = [Config.URL.path]
        process.launch()
    }
    
    @IBAction func reloadConfig(_ sender: NSMenuItem) {
        updateMenu()
    }
    
    override func awakeFromNib() {
//        statusItem.button?.title = "R"
//        statusItem.button?.image = NSImage(named: "AppIcon")
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusIcon");
        }
        statusItem.menu = statusMenu
        hotkeyManager = HotkeyManager(statusMenuController: self)
        updateMenu()
    }
    
    func updateMenu() {
        // Clear map and hotkeys
        map = [:]
        hotkeyManager!.hotkeys = []
        
        // Load items from config
        let data = Config.load();
        // Clear items in menu
        statusMenu.removeAllItems();
        
        // Add items to menu
        for (_, items) : (String, JSON) in data {
            statusMenu.addItem(generateMenu(items: items, nesting: 1))
        }
        statusMenu.addItem(.separator());
        // Add status bar run sub menu
        statusMenu.addItem(statusBarRunMenuItem)
    }
    
    func generateMenu(items: JSON, nesting: Int) -> NSMenuItem {
        if (items["launchPath"] == JSON.null) {
            checkCfg(items: items, mustHasChildren: true)
            // MenuItem with submenu
            let menuItem = NSMenuItem(title: items["title"].stringValue, action: nil, keyEquivalent: "")
            menuItem.submenu = NSMenu(title: items["title"].stringValue)
            for (_, subItems) : (String, JSON) in items["children"] {
                menuItem.submenu?.addItem(generateMenu(items: subItems, nesting: nesting + 1))
            }
            return menuItem;
        } else {
            checkCfg(items: items, mustHasChildren: false);
            
            // MenuItem without submenu
            let prefixedTitle = getPrefix(nesting: nesting) + items["title"].stringValue.replacingOccurrences(of: zeroWidthSpace, with: "");
            // Save action
            map[prefixedTitle] = items
            // Create item
            let menuItem = NSMenuItem(title: prefixedTitle, action: #selector(StatusMenuController.run(sender:)), keyEquivalent: "")
            menuItem.target = self
            // Create hotkey
            if (items["hotkey"] != JSON.null) {
                hotkeyManager!.registerHotkey(hotkeyOptions: items["hotkey"], item: menuItem)
            }
            if (items["label"] != JSON.null) {
                let labelOptions = items["label"];
                runProcess(options: labelOptions, terminationHandler: {(label) -> Void in
                    var text = label
                    let trimOutput = labelOptions["trimOutput"]
                    if (trimOutput.exists() && (trimOutput.type == .string || (trimOutput.type == .bool && trimOutput.boolValue))) {
                        var characters = " \n"
                        
                        if (trimOutput.type == .string) {
                            characters = trimOutput.stringValue
                        }
                        
                        text = text.trimmingCharacters(in: CharacterSet(charactersIn: characters))
                    }
                    menuItem.title = labelOptions["prefix"].stringValue + text + labelOptions["suffix"].stringValue;
                })
            }

            return menuItem;
        }
    }
    
    func getPrefix(nesting: Int) -> String {
        // Generate prefix for a given amount of nestings
        if (nesting == 1) {
            // No zero width space
            return "";
        }
        // One or more zero width spaces
        var prefix = zeroWidthSpace;
        for _ in 2..<nesting {
            prefix += zeroWidthSpace;
        }
        return prefix;
    }
    
    @objc func run(sender: NSMenuItem) {
        let options = map[sender.title]
        if (options != nil) {
            runProcess(options: options!, terminationHandler: nil)
        }
    }
    
    func runProcess(options: JSON, terminationHandler: ((String) -> Void)?) {
        let process = Process();
        process.launchPath = options["launchPath"].stringValue
        process.arguments = options["arguments"].arrayObject as? [String]
        var pipe: Pipe?;
        if (terminationHandler != nil) {
            pipe = Pipe()
            process.standardOutput = pipe
            process.terminationHandler = {(process) -> Void in
                let data = pipe!.fileHandleForReading.availableData
                terminationHandler!(String(data: data, encoding: String.Encoding.utf8)!)
            }
        }
        process.launch()
    }
    
    func showAlert(title:String, message:String, quit: Bool) {
        let alert: NSAlert = NSAlert();
        alert.messageText = title.isEmpty ? "Alert" : title;
        alert.informativeText = message;
        alert.alertStyle = NSAlert.Style.warning;
        alert.addButton(withTitle: "Ok");
        alert.runModal();
        
        if(quit){
            NSApplication.shared.terminate(self);
        }
    }
    
    ///
    /// check the config
    func checkCfg(items:JSON, mustHasChildren:Bool){
        if items["title"] == JSON.null {
            showAlert(title: "The config file is invalid", message: "title attribute missing", quit: true);
        }
        if(mustHasChildren && items["children"] == JSON.null){
            showAlert(title: "The config file is invalid", message: "children attribute missing: you must set launchPath attr or children attr", quit: true);
        }
    }
    
//    @available(OSX 10.15, *)
//    func openTerminal(at url: URL?){
//        guard let url = url,
//              let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
//        else { return }
//
//        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration() )
//    }
}
