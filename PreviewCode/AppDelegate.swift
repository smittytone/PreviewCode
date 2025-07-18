/*
 *  AppDelegate.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Cocoa
import CoreServices
import WebKit
import Highlighter


@main
class AppDelegate: NSResponder,
                   NSApplicationDelegate,
                   URLSessionDelegate,
                   URLSessionDataDelegate,
                   WKNavigationDelegate,
                   NSTableViewDelegate,
                   NSTableViewDataSource,
                   NSTextViewDelegate,
                   NSControlTextEditingDelegate {

    // MARK: - Class UI Properies
    
    // Menu Items
    @IBOutlet var helpMenuOnlineHelp: NSMenuItem!
    @IBOutlet var helpMenuAcknowledgments: NSMenuItem!
    @IBOutlet var helpMenuAppStoreRating: NSMenuItem!
    @IBOutlet var helpMenuHighlightr: NSMenuItem!
    @IBOutlet var helpMenuHighlightjs: NSMenuItem!
    @IBOutlet var helpMenuHighlighterSwift: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewMarkdown: NSMenuItem!
    //@IBOutlet var helpMenuOthersPreviewYaml: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewJson: NSMenuItem!
    @IBOutlet var helpMenuRenderThemes: NSMenuItem!
    // FROM 1.2.5
    @IBOutlet var helpMenuWhatsNew: NSMenuItem!
    @IBOutlet var helpMenuReportBug: NSMenuItem!
    //@IBOutlet var helpMenuOthersPreviewText: NSMenuItem!
    @IBOutlet var mainMenuSettings: NSMenuItem!
    
    // Panel Items
    @IBOutlet var versionLabel: NSTextField!
    
    // Windows
    @IBOutlet var window: NSWindow!

    // Report Sheet
    @IBOutlet var reportWindow: NSWindow!
    @IBOutlet var feedbackText: NSTextField!
    @IBOutlet var connectionProgress: NSProgressIndicator!
    // FROM 1.3.6
    @IBOutlet var messageSizeLabel: NSTextField!
    @IBOutlet var messageSendButton: NSButton!

    // Preferences Sheet
    @IBOutlet var preferencesWindow: NSWindow!
    @IBOutlet var fontSizeSlider: NSSlider!
    @IBOutlet var fontSizeLabel: NSTextField!
    @IBOutlet var themeTable: NSTableView!
    @IBOutlet var codeFontPopup: NSPopUpButton!
    //@IBOutlet var displayModeSegmentedControl: NSSegmentedControl!
    // FROM 1.1.0
    @IBOutlet weak var codeStylePopup: NSPopUpButton!
    // FROM 1.3.0
    @IBOutlet var darkRadioButton: NSButton!
    @IBOutlet var lightRadioButton: NSButton!
    @IBOutlet var autoRadioButton: NSButton!
    @IBOutlet var darkThemeLabel: NSTextField!
    @IBOutlet var lightThemeLabel: NSTextField!
    @IBOutlet var darkThemeIcon: PCImageView!
    @IBOutlet var lightThemeIcon: PCImageView!
    @IBOutlet var themeHelpLabel: NSTextField!
    @IBOutlet var themeScrollView: NSScrollView!
    @IBOutlet var lineSpacingPopup: NSPopUpButton!
    @IBOutlet var helpButton: NSButton!
    
    // What's New Sheet
    @IBOutlet var whatsNewWindow: NSWindow!
    @IBOutlet var whatsNewWebView: WKWebView!

    
    // MARK: - Private Properies

    internal var whatsNewNav: WKNavigation? = nil
    internal var feedbackTask: URLSessionTask? = nil
    internal var codeFontSize: CGFloat = 16.0
    internal var codeFontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
    private  var doShowLightBackground: Bool = false
    internal var themeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME
    internal var themeDisplayMode: Int = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    internal var selectedThemeIndex: Int = 37
    internal var newThemeIndex: Int = 37
    internal var themes: [Any] = []
    internal var darkThemes: [Int] = []
    internal var lightThemes: [Int] = []
    // FROM 1.1.0
    internal var codeFonts: [PMFont] = []
    // FROM 1.2.1
    internal var codeStyleName: String = "Regular"
    // FROM 1.2.5
    //private  var havePrefsChanged: Bool = false
    internal var isMontereyPlus: Bool = false
    // FROM 1.3.0
    internal var lightThemeIndex: Int = 0
    internal var darkThemeIndex: Int = 0
    internal var newThemeDisplayMode: Int = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    internal var newLightThemeIndex: Int = 0
    internal var newDarkThemeIndex: Int = 0
    internal var lineSpacing: CGFloat = BUFFOON_CONSTANTS.DEFAULT_LINE_SPACING

    /*
     Replace the following string with your own team ID. This is used to
     identify the app suite and so share preferences set by the main app with
     the previewer and thumbnailer extensions.
     */
    internal var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    
    
    // MARK: - Class Lifecycle Functions

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // FROM 1.1.0
        // Use for rendering theme selection graphics
#if DEBUG
        self.helpMenuRenderThemes.isHidden = false
#endif

        // FROM 1.1.0
        // Asynchronously get the list of code fonts
        DispatchQueue.init(label: "com.bps.previecode.async-queue").async {
            self.asyncGetFonts()
        }
        
        // Set application group-level defaults
        registerPreferences()
        
        // Add the app's version number to the UI
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.stringValue = "Version \(version) (\(build))"

        // Disable the Help menu Spotlight features
        let dummyHelpMenu: NSMenu = NSMenu.init(title: "Dummy")
        let theApp = NSApplication.shared
        theApp.helpMenu = dummyHelpMenu
        
        // FROM 1.2.0
        // Output language list for debugging
#if DEBUG
        if let hr: Highlighter = Highlighter.init() {
            let list: [String] = hr.supportedLanguages()
            print("***** Languages  *****")
            for language in list {
                print(language)
            }
            print("**********************")
        }
#endif
        
        // Centre the main window and display
        self.window.center()
        self.window.makeKeyAndOrderFront(self)

        // Show the 'What's New' panel if we need to
        // NOTE Has to take place at the end of the function
        doShowWhatsNew(self)
    }


    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {

        // When the main window closed, shut down the app
        return true
    }


    // MARK: - Action Functions

    /**
     Called from the File menu's Close item and the various Quit controls.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doClose(_ sender: Any) {
        
        // Reset the QL thumbnail cache... just in case it helps
        _ = runProcess(app: "/usr/bin/qlmanage", with: ["-r", "cache"])
        
        // FROM 1.2.5
        // Check for open panels
        if self.preferencesWindow.isVisible {
            if checkPrefs() {
                let alert: NSAlert = showAlert("You have unsaved settings",
                                               "Do you wish to cancel and save them, or quit the app anyway?",
                                               false)
                alert.addButton(withTitle: "Quit")
                alert.addButton(withTitle: "Cancel")
                alert.beginSheetModal(for: self.preferencesWindow) { (response: NSApplication.ModalResponse) in
                    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                        // The user clicked 'Quit'
                        self.preferencesWindow.close()
                        self.window.close()
                    }
                }
                
                return
            }
            
            self.preferencesWindow.close()
        }
        
        if self.whatsNewWindow.isVisible {
            self.whatsNewWindow.close()
        }
        
        if self.reportWindow.isVisible {
            if self.feedbackText.stringValue.count > 0 {
                let alert: NSAlert = showAlert("You have unsent feedback",
                                               "Do you wish to cancel and send it, or quit the app anyway?",
                                               false)
                alert.addButton(withTitle: "Quit")
                alert.addButton(withTitle: "Cancel")
                alert.beginSheetModal(for: self.reportWindow) { (response: NSApplication.ModalResponse) in
                    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                        // The user clicked 'Quit'
                        self.reportWindow.close()
                        self.window.close()
                    }
                }
                
                return
            }
            
            self.reportWindow.close()
        }

        
        // Close the window... which will trigger an app closure
        self.window.close()
    }
    
    
    /**
     Called from the Help menu's items to open various websites.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    @objc
    private func doShowSites(sender: Any) {
        
        // Open the websites for contributors, help and suc
        let item: NSMenuItem = sender as! NSMenuItem
        var path: String = BUFFOON_CONSTANTS.MAIN_URL
        
        // Depending on the menu selected, set the load path
        if item == self.helpMenuOnlineHelp {
            path += "#how-to-use-previewcode"
        } else if item == self.helpMenuAcknowledgments {
            path += "#acknowledgements"
        } else if item == self.helpMenuAppStoreRating {
            path = BUFFOON_CONSTANTS.APP_STORE + "?action=write-review"
        } else if item == self.helpMenuHighlightr {
            path = "https://github.com/raspu/Highlightr"
        } else if item == self.helpMenuHighlightjs {
            path = "https://github.com/highlightjs/highlight.js"
        } else if item == self.helpMenuHighlighterSwift {
            path = "https://github.com/smittytone/HighlighterSwift"
        } else if item == self.helpMenuOthersPreviewMarkdown {
            path = BUFFOON_CONSTANTS.APP_URLS.PM
        //} else if item == self.helpMenuOthersPreviewYaml {
        //    path = BUFFOON_CONSTANTS.APP_URLS.PY
        } else if item == self.helpMenuOthersPreviewJson {
            path = BUFFOON_CONSTANTS.APP_URLS.PJ
        } //else if item == self.helpMenuOthersPreviewText {
        //    path = BUFFOON_CONSTANTS.APP_URLS.PT
        //}
        
        // Open the selected website
        NSWorkspace.shared.open(URL.init(string:path)!)
    }


    /**
     Open the System Preferences app at the Extensions pane.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doOpenSysPrefs(sender: Any) {

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    }
    
    
    /**
     Alternative route to help, from the **Preferences** panel.
     FROM 1.3.0
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doShowPrefsHelp(sender: Any) {
        
        let path: String = BUFFOON_CONSTANTS.MAIN_URL + "#customise-the-preview"
        NSWorkspace.shared.open(URL.init(string:path)!)

    }


    // MARK: - Misc Functions

    /**
     Called by the app at launch to register its initial defaults.
     */
     private func registerPreferences() {

        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            // Check if each preference value exists -- set if it doesn't
            // Preview body font size, stored as a CGFloat
            // Default: 16.0
            let codeFontSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            if codeFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            }

            // Thumbnail view base font size, stored as a CGFloat, not currently used
            // Default: 32.0
            let thumbFontSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_FONT_SIZE)
            if thumbFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_FONT_SIZE)
            }

            // Font for previews and thumbnails
            // Default: Menlo
            let codeFontName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
            if codeFontName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULT_FONT,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
            }
            
            // Theme for previews
            // NOTE Unused from 1.3.0
            var themeName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_NAME)
            if themeName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULT_THEME,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_NAME)
                themeName = BUFFOON_CONSTANTS.DEFAULT_THEME
            }

            // Use light background even in dark mode, stored as a bool
            // Default: false
            // NOTE Currently unused
            let useLightDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            if useLightDefault == nil {
                defaults.setValue(false,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            }
            
            // FROM 1.3.0
            // Establish new defaults to store light and dark theme names.
            // But check for an existing one so the user's choice is at least
            // partially maintained, ie. if they selected a dark theme before, that
            // will become the chosen dark them now
            var darkThemeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME_DARK
            var lightThemeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME_LIGHT
            let previousVersionKey: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + "-1-2"
            let previousVersionDefault: Any? = defaults.object(forKey: previousVersionKey)
            if previousVersionDefault != nil {
                // A previous version's defaults exist,
                // so use the theme setting
                let aThemeName = themeName as! String
                if aThemeName.starts(with: "dark.") {
                    darkThemeName = aThemeName
                } else {
                    lightThemeName = aThemeName
                }
            }
            
            let newDarkThemeName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            if newDarkThemeName == nil {
                defaults.setValue(darkThemeName,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            }
            
            let newLightThemeName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            if newLightThemeName == nil {
                defaults.setValue(lightThemeName,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            }
            
            let defaultDisplayMode: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            if defaultDisplayMode == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            }
            
            // FROM 1.3.0
            // Line spacing
            // Default: 1.0
            let lineSpacing:Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            if lineSpacing == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULT_LINE_SPACING,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            }

            // Show the What's New sheet
            // Default: true
            // This is a version-specific preference suffixed with, eg, '-2-3'. Once created
            // this will persist, but with each new major and/or minor version, we make a
            // new preference that will be read by 'doShowWhatsNew()' to see if the sheet
            // should be shown this run
            let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
            let showNewDefault: Any? = defaults.object(forKey: key)
            if showNewDefault == nil {
                defaults.setValue(true, forKey: key)
            }
        }
    }
}

