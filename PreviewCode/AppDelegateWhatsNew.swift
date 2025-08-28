/*
 *  AppDelegateWhatsNew.swift
 *  PreviewCode
 *  Extension for AppDelegate providing What's New sheet functionality.
 *
 *  Created by Tony Smith on 18/07/2025.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import AppKit
import WebKit


extension AppDelegate {

    /**
     Show the 'What's New' sheet.
 
     If we're on a new, non-patch version, of the user has explicitly
     asked to see it with a menu click See if we're coming from a menu click
     (`sender != self`) or directly in code from *appDidFinishLoading()*
     (`sender == self`)
 
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    internal func doShowWhatsNew(_ sender: Any) {
        
        // Check how we got here
        var doShowSheet: Bool = type(of: self) != type(of: sender)
        
        if !doShowSheet {
            // We are coming from the 'appDidFinishLoading()' so check
            // if we need to show the sheet by the checking the prefs
            if let defaults = UserDefaults(suiteName: self.appSuiteName) {
                // Get the version-specific preference key
                let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
                doShowSheet = defaults.bool(forKey: key)
            }
        }
      
        // Configure and show the sheet
        if doShowSheet {
            // FROM 1.2.5
            // Hide menus we don't want used while the panel is open
            hidePanelGenerators()
            
            // First, get the folder path
            let htmlFolderPath = Bundle.main.resourcePath! + "/new"

            //Set up the WKWebBiew: no elasticity, horizontal scroller
            self.whatsNewWebView.enclosingScrollView?.hasHorizontalScroller = false
            self.whatsNewWebView.enclosingScrollView?.horizontalScrollElasticity = .none
            self.whatsNewWebView.enclosingScrollView?.verticalScrollElasticity = .none
            self.whatsNewWebView.configuration.suppressesIncrementalRendering = true

            // Just in case, make sure we can load the file
            if FileManager.default.fileExists(atPath: htmlFolderPath) {
                let htmlFileURL = URL.init(fileURLWithPath: htmlFolderPath + "/new.html")
                let htmlFolderURL = URL.init(fileURLWithPath: htmlFolderPath)
                self.whatsNewNav = self.whatsNewWebView.loadFileURL(htmlFileURL, allowingReadAccessTo: htmlFolderURL)
            }
        }
    }


    /**
     Close the 'What's New' sheet.
     
     Make sure we clear the preference flag for this minor version, so that
     the sheet is not displayed next time the app is run (unless the version changes)
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doCloseWhatsNew(_ sender: Any) {

         // Close the sheet
         self.window.endSheet(self.whatsNewWindow)
        
         // Scroll the web view back to the top
         self.whatsNewWebView.evaluateJavaScript("window.scrollTo(0,0)", completionHandler: nil)

         // Set this version's preference
         if let defaults = UserDefaults(suiteName: self.appSuiteName) {
             let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
             defaults.setValue(false, forKey: key)

#if DEBUG
             print("\(key) reset back to true")
             defaults.setValue(true, forKey: key)
#endif
         }
         
         // FROM 1.2.5
         // Restore menus
         showPanelGenerators()
    }


    // MARK: - WKWebNavigation Delegate Functions

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        // Asynchronously show the sheet once the HTML has loaded
        // (triggered by delegate method)

        if let nav = self.whatsNewNav {
            if nav == navigation {
                // Display the sheet
                // FROM 1.3.2 -- add timer to prevent 'white flash'
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { timer in
                    timer.invalidate()
                    self.window.beginSheet(self.whatsNewWindow, completionHandler: nil)
                }
            }
        }
    }
}
