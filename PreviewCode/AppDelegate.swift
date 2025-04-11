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
                   NSTextViewDelegate {

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

    // Preferences Sheet
    @IBOutlet var preferencesWindow: NSWindow!
    @IBOutlet var fontSizeSlider: NSSlider!
    @IBOutlet var fontSizeLabel: NSTextField!
    @IBOutlet var themeTable: NSTableView!
    @IBOutlet var codeFontPopup: NSPopUpButton!
    @IBOutlet var displayModeSegmentedControl: NSSegmentedControl!
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
    private  var feedbackTask: URLSessionTask? = nil
    private  var codeFontSize: CGFloat = 16.0
    private  var codeFontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
    private  var doShowLightBackground: Bool = false
    private  var themeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME
    private  var themeDisplayMode: Int = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    private  var selectedThemeIndex: Int = 37
    private  var newThemeIndex: Int = 37
    private  var themes: [Any] = []
    private  var darkThemes: [Int] = []
    private  var lightThemes: [Int] = []
    // FROM 1.1.0
    internal var codeFonts: [PMFont] = []
    // FROM 1.2.1
    internal var codeStyleName: String = "Regular"
    // FROM 1.2.5
    //private  var havePrefsChanged: Bool = false
    internal var isMontereyPlus: Bool = false
    // FROM 1.3.0
    private  var lightThemeIndex: Int = 0
    private  var darkThemeIndex: Int = 0
    private  var newThemeDisplayMode: Int = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    private  var newLightThemeIndex: Int = 0
    private  var newDarkThemeIndex: Int = 0
    private var lineSpacing: CGFloat = BUFFOON_CONSTANTS.DEFAULT_LINE_SPACING

    /*
     Replace the following string with your own team ID. This is used to
     identify the app suite and so share preferences set by the main app with
     the previewer and thumbnailer extensions.
     */
    private  var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    
    
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
    @IBAction private func doClose(_ sender: Any) {
        
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
    @IBAction @objc private func doShowSites(sender: Any) {
        
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
    @IBAction private func doOpenSysPrefs(sender: Any) {

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    }
    
    
    /**
     Alternative route to help, from the **Preferences** panel.
     FROM 1.3.0
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowPrefsHelp(sender: Any) {
        
        let path: String = BUFFOON_CONSTANTS.MAIN_URL + "#customise-the-preview"
        NSWorkspace.shared.open(URL.init(string:path)!)

    }


    // MARK: - Report Functions
    
    /**
     Display a window in which the user can submit feedback, or report a bug.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doShowReportWindow(sender: Any) {
        
        // FROM 1.2.5
        // Hide menus we don't want used while the panel is open
        hidePanelGenerators()
        
        // Reset the UI
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""

        // Present the window
        self.window.beginSheet(self.reportWindow, completionHandler: nil)
    }


    /**
     User has clicked the Report window's 'Cancel' button, so just close the sheet.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doCancelReportWindow(sender: Any) {

        self.connectionProgress.stopAnimation(self)
        self.window.endSheet(self.reportWindow)
        
        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
    }


    /**
     User has clicked the Report window's 'Send' button.
     
     Get the message (if there is one) from the text field and submit it.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doSendFeedback(sender: Any) {

        let feedback: String = self.feedbackText.stringValue

        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.startAnimation(self)

            /*
             Add your own `func sendFeedback(_ feedback: String) -> URLSessionTask?` function
             */
            self.feedbackTask = sendFeedback(feedback)
            
            if self.feedbackTask != nil {
                // We have a valid URL Session Task, so start it to send
                self.feedbackTask!.resume()
            } else {
                // Report the error
                sendFeedbackError()
            }

            return
        }
        
        // No feedback, so close the sheet
        self.window.endSheet(self.reportWindow)
        
        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
        
        // NOTE sheet closes asynchronously unless there was no feedback to send,
        //      or an error occured with setting up the feedback session
    }


// MARK: - Preferences Functions
    
    /**
     Initialise and display the 'Preferences' sheet.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowPreferences(sender: Any) {
        
        // FROM 1.2.5
        // Hide menus we don't want used while the panel is open
        hidePanelGenerators()
        
        // FROM 1.2.5
        // Reset changed prefs flag
        // self.havePrefsChanged = false
        
        // Set the themes table's contents store, once per runtime
        if self.themes.count == 0 {
            // Load and prepare the list of themes
            loadThemeList()
        }
        
        // The suite name is the app group name, set in each the entitlements file of
        // the host app and of each extension
        if let defaults: UserDefaults = UserDefaults(suiteName: self.appSuiteName) {
            self.codeFontSize = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE))
            self.codeFontName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_FONT
            self.themeName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_THEME
            
            // FROM 1.3.0
            self.themeDisplayMode = defaults.integer(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            self.newThemeDisplayMode = self.themeDisplayMode
            
            let lightThemeName: String = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_THEME_LIGHT
            let darkThemeName: String  = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_THEME_DARK
            
            // Use the loaded theme names to find and set the human-reabable name in the UI
            for i in 0..<self.themes.count {
                let theme: [String: Any] = self.themes[i] as! [String: Any]
                let cName: String = codedName(i)
                
                if lightThemeName == cName {
                    self.lightThemeLabel.stringValue = theme["name"] as! String
                    self.lightThemeIndex = i
                    self.newLightThemeIndex = i
                }
                
                if darkThemeName == cName {
                    self.darkThemeLabel.stringValue = theme["name"] as! String
                    self.darkThemeIndex = i
                    self.newDarkThemeIndex = i
                }
            }
            
            // FROM 1.3.0
            self.lineSpacing = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING))
        }

        // Set the font size slider
        let index: Int = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.lastIndex(of: self.codeFontSize) ?? 3
        self.fontSizeSlider.floatValue = Float(index)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        
        // FROM 1.1.0
        // Set the font name popup
        // List the current system's monospace fonts
        self.codeFontPopup.removeAllItems()
        for i: Int in 0..<self.codeFonts.count {
            let font: PMFont = self.codeFonts[i]
            self.codeFontPopup.addItem(withTitle: font.displayName)
        }

        self.codeStylePopup.isEnabled = false
        selectFontByPostScriptName(self.codeFontName)

        // Load the table with themes
        loadTable()
        
        // FROM 1.3.0
        // Set the mode control
        switch(self.themeDisplayMode) {
            case BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT:
                self.lightRadioButton.state = .on
                self.lightThemeLabel.textColor = NSColor.labelColor
                self.darkThemeLabel.textColor = NSColor.gray
                self.darkThemeIcon.isOutlined = false
                self.lightThemeIcon.isOutlined = true
                self.themeHelpLabel.stringValue = "Always use the selected light theme"
            case BUFFOON_CONSTANTS.DISPLAY_MODE.DARK:
                self.darkRadioButton.state = .on
                self.lightThemeLabel.textColor = NSColor.gray
                self.darkThemeLabel.textColor = NSColor.labelColor
                self.darkThemeIcon.isOutlined = true
                self.lightThemeIcon.isOutlined = false
                self.themeHelpLabel.stringValue = "Always use the selected dark theme"
            default:
                self.autoRadioButton.state = .on
                self.lightThemeLabel.textColor = NSColor.labelColor
                self.darkThemeLabel.textColor = NSColor.labelColor
                self.darkThemeIcon.isOutlined = true
                self.lightThemeIcon.isOutlined = true
                self.themeHelpLabel.stringValue = "Use the selected theme based on the host Mac’s mode"
        }
        
        // FROM 1.3.0
        // Set the responder chain for keyed selection
        self.themeTable.nextResponder = self
        
        // FROM 1.3.0
        // Set the line spacing selector
        switch(round(self.lineSpacing * 100) / 100.0) {
            case 1.25:
                self.lineSpacingPopup.selectItem(at: 1)
            case 1.5:
                self.lineSpacingPopup.selectItem(at: 2)
            case 2.0:
                self.lineSpacingPopup.selectItem(at: 3)
            default:
                self.lineSpacingPopup.selectItem(at: 0)
        }

        // Display the sheet
        self.preferencesWindow.makeFirstResponder(self.themeTable)
        self.window.beginSheet(self.preferencesWindow, completionHandler: nil)
    }


    /**
     Close the **Preferences** sheet and save any settings that have changed.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doSavePreferences(sender: Any) {

        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            // Decode the font menu index value into a font list index
            
            // Set the chosen text size if it has changed
            let newValue: CGFloat = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
            if newValue != self.codeFontSize {
                defaults.setValue(newValue,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            }
            
            // FROM 1.1.0
            // Set the chosen font if it has changed
            // NOTE This covers both the font name and the style
            if let fontName: String = getPostScriptName() {
                if fontName != self.codeFontName {
                    self.codeFontName = fontName
                    defaults.setValue(fontName,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
                }
            }
            
            // FROM 1.3.0
            // Update the theme selections if they have changed
            if self.newLightThemeIndex != self.lightThemeIndex {
                self.lightThemeIndex = self.newLightThemeIndex
                defaults.setValue(codedName(self.lightThemeIndex),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            }
            
            if self.newDarkThemeIndex != self.darkThemeIndex {
                self.darkThemeIndex = self.newDarkThemeIndex
                defaults.setValue(codedName(self.darkThemeIndex),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            }
            
            if self.newThemeDisplayMode != self.themeDisplayMode {
                self.themeDisplayMode = self.newThemeDisplayMode
                defaults.setValue(self.themeDisplayMode,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            }
            
            // FROM 1.3.0
            // Save the selected line spacing
            let lineIndex: Int = self.lineSpacingPopup.indexOfSelectedItem
            var lineSpacing: CGFloat = 1.0
            switch(lineIndex) {
                case 1:
                    lineSpacing = 1.25
                case 2:
                    lineSpacing = 1.5
                case 3:
                    lineSpacing = 2.0
                default:
                    lineSpacing = 1.0
            }
            
            if (self.lineSpacing != lineSpacing) {
                self.lineSpacing = lineSpacing
                defaults.setValue(lineSpacing,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            }
        }
        
        // Remove the sheet now we have the data
        self.window.endSheet(self.preferencesWindow)
        
        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
    }
    
    
    /**
     Close the **Preferences** sheet without saving.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doClosePreferences(sender: Any) {
        
        if checkPrefs() {
            let alert: NSAlert = showAlert("You have made changes",
                                           "Do you wish to go back and save them, or ignore them? ",
                                           false)
            alert.addButton(withTitle: "Go Back")
            alert.addButton(withTitle: "Ignore Changes")
            alert.beginSheetModal(for: self.preferencesWindow) { (response: NSApplication.ModalResponse) in
                if response != NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user clicked 'Cancel'
                    self.closePrefsWindow()
                }
            }
        } else {
            closePrefsWindow()
        }
    }
    
    
    private func closePrefsWindow() {
        
        // Close the **Preferences** sheet
        self.window.endSheet(self.preferencesWindow)
        
        // Restore menus
        showPanelGenerators()
    }
    
    
    private func checkPrefs() -> Bool {
        
        var haveChanged: Bool = false
        
        // Check the chosen text size
        let newValue: CGFloat = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
        haveChanged = (newValue != self.codeFontSize)
        
        // Check the chosen font
        if let fontName: String = getPostScriptName() {
            if !haveChanged && fontName != self.codeFontName {
                haveChanged = true
            }
        }
        
        // Check the theme selections
        if !haveChanged {
            haveChanged = (self.newLightThemeIndex != self.lightThemeIndex)
        }
        
        if !haveChanged {
            haveChanged = (self.newDarkThemeIndex != self.darkThemeIndex)
        }
        
        if !haveChanged {
            haveChanged = (self.newThemeDisplayMode != self.themeDisplayMode)
        }
        
        // Check the selected line spacing
        let lineIndex: Int = self.lineSpacingPopup.indexOfSelectedItem
        var lineSpacing: CGFloat = 1.0
        switch(lineIndex) {
            case 1:
                lineSpacing = 1.25
            case 2:
                lineSpacing = 1.5
            case 3:
                lineSpacing = 2.0
            default:
                lineSpacing = 1.0
        }
        
        if !haveChanged {
            haveChanged = (round(self.lineSpacing * 100) / 100.0 != lineSpacing)
        }
        
        return haveChanged
    }
    
    /**
     When the font size slider is moved and released, this function updates the font size readout.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doMoveSlider(sender: Any) {
        
        let index: Int = Int(self.fontSizeSlider.floatValue)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        //self.havePrefsChanged = true
    }


    /**
     When a radio button is clicked, change the theme mode.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doSwitchMode(sender: Any) {
        
        // FROM 1.3.0
        // Support radio buttons for mode control:
        // Light only, dark only, or mixed mode.
        if self.lightRadioButton.state == .on {
            self.newThemeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT
            self.lightThemeLabel.textColor = NSColor.labelColor
            self.darkThemeLabel.textColor = NSColor.gray
            self.darkThemeIcon.isOutlined = false
            self.lightThemeIcon.isOutlined = true
            self.themeHelpLabel.stringValue = "Always use the selected light theme"
        } else if self.darkRadioButton.state == .on {
            self.newThemeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.DARK
            self.lightThemeLabel.textColor = NSColor.gray
            self.darkThemeLabel.textColor = NSColor.labelColor
            self.darkThemeIcon.isOutlined = true
            self.lightThemeIcon.isOutlined = false
            self.themeHelpLabel.stringValue = "Always use the selected dark theme"
        } else if self.autoRadioButton.state == .on {
            self.newThemeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
            self.lightThemeLabel.textColor = NSColor.labelColor
            self.darkThemeLabel.textColor = NSColor.labelColor
            self.darkThemeIcon.isOutlined = true
            self.lightThemeIcon.isOutlined = true
            self.themeHelpLabel.stringValue = "Use the selected theme based on the host Mac’s mode"
        }
        
        // Reload the table and its selection
        loadTable()
    }
    
    
    /**
     Called when the user selects a font from either list.

     FROM 1.1.0

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateFonts(sender: Any) {
        
        // From 1.2.1
        // If the user re-selects the current font family,
        // only update the style popup if a different family
        // has been selected
        //self.havePrefsChanged = true
        let item: NSPopUpButton = sender as! NSPopUpButton
        if item == self.codeFontPopup {
            let currentFontPSName: NSString = self.codeFontName as NSString
            let selectedFontName: String = item.titleOfSelectedItem ?? BUFFOON_CONSTANTS.DEFAULT_FONT_NAME
            if !(currentFontPSName.contains(selectedFontName)) {
                // Update the menu of available styles
                // because a different font has been selected
                setStylePopup(self.codeStylePopup.titleOfSelectedItem ?? "Regular")
                return
            }
        } else {
            // The user clicked the style popup, so record the style
            self.codeStyleName = self.codeStylePopup.titleOfSelectedItem ?? "Regular"
        }
    }
    
    
    // MARK: - What's New Functions
    
    /**
     Show the 'What's New' sheet.
 
     If we're on a new, non-patch version, of the user has explicitly
     asked to see it with a menu click See if we're coming from a menu click
     (`sender != self`) or directly in code from *appDidFinishLoading()*
     (`sender == self`)
 
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowWhatsNew(_ sender: Any) {
        
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
     @IBAction private func doCloseWhatsNew(_ sender: Any) {

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

    
    // MARK: - Table Data Functions
    
    /**
     Set up the themes table.
     */
    private func loadTable() {
        
        // De-select and update the themes table
        self.themeTable.reloadData()
        self.themeTable.deselectAll(self)
        
        // Select the chosen theme
        var index: Int = self.newLightThemeIndex
        if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            index = self.newDarkThemeIndex
        }
        
        // 'getSelectionIndex()' returns nil if nothing is selected
        // on the table, ie. a dark theme has been chosen but we're
        // viewing the light table
        if let idx: IndexSet = getSelectionIndex(index) {
            // We can use '.min()' because 'idx' should contain only one value
            let row: Int = idx.min()!
            self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
            self.themeTable.scrollRowToVisible(row)
        } else {
            self.themeTable.scrollRowToVisible(0)
        }
    }
    
    
    /**
     Generate a selection index for the displayed table.
     
     Bases the selection on whether the full data set is being displayed
     or only a subset.
     
     - Parameters:
        - indexInFullThemeList: the selected row's reference to an entry in the main list of themes.
     
     - Returns: The row to select
     */
    private func getSelectionIndex(_ indexInFullThemeList: Int) -> IndexSet? {
        
        // Assume we're showing all themes as the default
        var idx: IndexSet? = IndexSet.init(integer: indexInFullThemeList)
        
        // But check if we're actually viewing a subset
        if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            idx = nil
            for i: Int in 0..<self.darkThemes.count {
                if self.darkThemes[i] == indexInFullThemeList {
                    idx = IndexSet.init(integer: i)
                    break
                }
            }
        } else if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
            idx = nil
            for i: Int in 0..<self.lightThemes.count {
                if self.lightThemes[i] == indexInFullThemeList {
                    idx = IndexSet.init(integer: i)
                    break
                }
            }
        }
        
        return idx
    }
    
    /**
     Generate a row index for the displayed table.
     
     Bases the selection on whether the full data set is being displayed
     or only a subset.
     
     - Parameters:
        - indexInFullThemeList: the selected row's reference to an entry in the main list of themes.
     
     - Returns: The row to select
     */
    private func getRowIndex(_ indexInFullThemeList: Int) -> Int {
        
        // Assume we're showing all themes as the default
        var idx: Int = indexInFullThemeList
        
        // But check if we're actually viewing a subset
        if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            idx = 0
            for i: Int in 0..<self.darkThemes.count {
                if self.darkThemes[i] == indexInFullThemeList {
                    idx = i
                    break
                }
            }
        } else if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
            idx = 0
            for i: Int in 0..<self.lightThemes.count {
                if self.lightThemes[i] == indexInFullThemeList {
                    idx = i
                    break
                }
            }
        }
        
        return idx
    }
    
    
    /**
     Calculate a main theme list index from a sub-list index.
     If the mode is AUTO, just return the passed value.
     
     - Parameters:
        - subListIndex: The sub-list row index.
     
     - Returns: The full theme list index.
     */
    func getBaseIndex(_ subListIndex: Int) -> Int {
        
        var fullListIndex: Int = subListIndex
        
        if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            fullListIndex = self.darkThemes[subListIndex]
        } else if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
            fullListIndex = self.lightThemes[subListIndex]
        }
        
        return fullListIndex
    }
   
    
    // MARK: - Theme Loading Functions
    
    /**
     Read the list of themes from the file in the bundle into an array property.
     
     We also create two subset arrays, one for dark themes, the other for light ones.
     
     Should only be called once per run.
     */
    private func loadThemeList() {
        
        // Load in the current theme list
        guard let themesString: String = loadBundleFile(BUFFOON_CONSTANTS.FILE_THEME_LIST)
        else {
            // Error already posted by 'loadBundleFile()'
            return
        }
        
        // FROM 1.1.0
        // Theme list is now a JSON file
        var dict: [String: Any] = [:]
        if let data: Data = themesString.data(using: .utf8) {
            dict = try! JSONSerialization.jsonObject(with: data,
                                                     options: []) as! [String: Any]
        }
        
        // Set the theme selection
        // Remember this called only one per run
        self.themes = dict["themes"] as! [Any]
        for i: Int in 0..<self.themes.count {
            // FROM 1.1.0
            // Get the coded name, eg. 'dark.atom-one-dark', as this is what's
            // stored in prefs and used by Code Previewer and Code Thumbnailer
            let codedThemeName: String = codedName(i)
            if codedThemeName == self.themeName {
                self.selectedThemeIndex = i
            }
          
            // Also record themes by type: these arrays
            // record indices from from the main array
            let theme: [String: Any] = self.themes[i] as! [String: Any]
            let isDark: Bool = theme["dark"] as! Bool
            if isDark {
                self.darkThemes.append(i)
            } else {
                self.lightThemes.append(i)
            }
            
#if DEBUG
            print("\(i + 1) \(theme["name"] as! String) " + (isDark ? "[D]" : "[L]"))
#endif
        }
    }
    
    
    /**
     Load a known text file from the app bundle.
     
     - Parameters:
        - file: The name of the text file without its extension.
     
     - Returns: The contents of the loaded file
     */
    private func loadBundleFile(_ fileName: String, _ type: String = "json") -> String? {
        
        // Load the required resource and return its contents
        guard let filePath: String = Bundle.main.path(forResource: fileName, ofType: type)
        else {
            // TODO Post error
            return nil
        }
        
        do {
            let fileContents: String = try String.init(contentsOf: URL.init(fileURLWithPath: filePath))
            return fileContents
        } catch {
            // TODO Post error
        }
        
        return nil
    }
    
    
    /**
     Render all the themes as 512 x 268 PNG files.

     Run this from the **Help** menu in debug sessions.

     - Parameters:
        - sender: The object that triggered the action
     */
    @IBAction private func doRenderThemes(_ sender: Any) {

        let renderFrame: CGRect = NSMakeRect(0, 0, 256, 134)
        let fm: FileManager = FileManager.init()
        let homeFolder: String = fm.homeDirectoryForCurrentUser.path
        let common: Common = Common.init(false)

        // Load in the code sample we'll preview the themes with
        guard let loadedCode = loadBundleFile(BUFFOON_CONSTANTS.FILE_CODE_SAMPLE, "txt") else { return }

        if self.themes.count == 0 {
            loadThemeList()
        }

        for i: Int in 0..<self.themes.count {
            let name: String = codedName(i)
            common.updateTheme(name)
            let pas: NSAttributedString = common.getAttributedString(loadedCode, "swift")
            let ptv: PreviewTextView = PreviewTextView.init(frame: renderFrame)
            ptv.isSelectable = false

            if let renderTextStorage: NSTextStorage = ptv.textStorage {
                renderTextStorage.beginEditing()
                renderTextStorage.setAttributedString(pas)
                renderTextStorage.endEditing()
                ptv.backgroundColor = common.themeBackgroundColour
            }

            if let imageRep: NSBitmapImageRep = ptv.bitmapImageRepForCachingDisplay(in: renderFrame) {
                ptv.cacheDisplay(in: renderFrame, to: imageRep)
                if let data: Data = imageRep.representation(using: .png, properties: [:]) {
                    do {
                        let theme: [String: Any] = self.themes[i] as! [String: Any]
                        let filename: String = theme["css"] as! String
                        let path: String = homeFolder + "/" + filename + ".png"
                        try data.write(to: URL.init(fileURLWithPath: path))
                    } catch {
                        // NOP
                    }
                }
            }
        }
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
    
    
    /**
     Get the 'coded' name of a theme, eg. 'agate-dark' -> 'dark.agate-dark'.
     
     - Parameters:
        - themeIndex: The theme's index in the array.
     
     - Returns: The coded name as a string.
     */
    
    private func codedName(_ themeIndex: Int) -> String {
        
        let theme: [String: Any] = self.themes[themeIndex] as! [String: Any]
        let isDark: Bool = theme["dark"] as! Bool
        let cssName: String = theme["css"] as! String
        return (isDark ? "dark." : "light.") + cssName
    }


    // MARK: - NSTableView Data Source / Delegate Functions
    
    func numberOfRows(in tableView: NSTableView) -> Int {

        // Just return the number of themes available
        switch (self.newThemeDisplayMode) {
            case BUFFOON_CONSTANTS.DISPLAY_MODE.DARK:
                return self.darkThemes.count
            case BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT:
                return self.lightThemes.count
            default:
                return self.themes.count
        }
    }


    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        // Assemble the table cell view
        let cell: ThemeTableCellView? = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "previewcode-theme-cell"), owner: self) as? ThemeTableCellView
        
        if cell != nil {
            // Configure the cell's title and its theme preview
            
            // Get the index in the the main theme list,
            // and thus the theme from that list
            let index: Int = getBaseIndex(row)
            let theme: [String: Any] = self.themes[index] as! [String: Any]
            let themeName: String = theme["name"] as! String
            let themeCSS: String = theme["css"] as! String
            
            // Populate cell
            cell!.themePreviewTitle.stringValue = themeName
            cell!.themeIndex = index
            
            // FROM 1.1.0
            // Generate the theme preview view programmatically, and use
            // images rather then JIT-rendered NSTextViews (too slow)
            if let themePreview: NSImage = NSImage.init(named: themeCSS) {
                let imv: NSImageView = NSImageView.init(image: themePreview)
                imv.frame = NSMakeRect(2, 1, 128, 78)
                cell!.addSubview(imv)
            }
        }

        return cell
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        /* Get the clicked NSTableCellView and use it to get the table row
         * that we need to select.
         */
        
        // Make sure the table becomes first responder so that the selection
        // is highlighted correctly
        if self.themeTable.selectedRow != -1 {
            self.preferencesWindow.makeFirstResponder(self.themeTable)
        }
        
        // FROM 1.3.0
        // Make the changes according to the currently selected mode
        switch(self.newThemeDisplayMode) {
            case BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT:
                self.newLightThemeIndex = getBaseIndex(self.themeTable.selectedRow)
                let theme: [String: Any] = self.themes[self.newLightThemeIndex] as! [String: Any]
                self.lightThemeLabel.stringValue = theme["name"] as! String
            case BUFFOON_CONSTANTS.DISPLAY_MODE.DARK:
                self.newDarkThemeIndex = getBaseIndex(self.themeTable.selectedRow)
                let theme: [String: Any] = self.themes[self.newDarkThemeIndex] as! [String: Any]
                self.darkThemeLabel.stringValue = theme["name"] as! String
            default:
                // Get the referenced theme (all are listed) and use it to make the correct
                // theme selection: light or dark
                self.newThemeIndex = self.themeTable.selectedRow
                let theme: [String: Any] = self.themes[self.themeTable.selectedRow] as! [String: Any]
                if theme["dark"] as! Bool {
                    self.newDarkThemeIndex = self.themeTable.selectedRow
                    self.darkThemeLabel.stringValue = theme["name"] as! String
                } else {
                    self.newLightThemeIndex = self.themeTable.selectedRow
                    self.lightThemeLabel.stringValue = theme["name"] as! String
                }
        }
    }
    
    
    // MARK: - NSTextView Delegate Functions
    
    func textViewDidChangeSelection(_ notification: Notification) {
        
        /* Get the clicked NSTextView and use it to determine the parent
         * ThemeTableCellView, from which we get the table row that
         * we need to select.
         */
        
        let clickedView: PreviewTextView = notification.object as! PreviewTextView
        let parentView: ThemeTableCellView = clickedView.superview as! ThemeTableCellView
        
        // parentView.themeIndex -> index in self.themes
        if let idx: IndexSet = getSelectionIndex(parentView.themeIndex) {
            self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
            self.preferencesWindow.makeFirstResponder(self.themeTable)
            
            // FROM 1.3.0
            // Update the indices for each type
            if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
                self.newDarkThemeIndex = parentView.themeIndex
            } else if self.newThemeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
                self.newLightThemeIndex = parentView.themeIndex
            } else {
                self.newThemeIndex = parentView.themeIndex
            }
        }
    }
    
    
    // MARK: - NSResponder Functions
    
    override func keyUp(with event: NSEvent) {
        
        /* Check for alpha key presses so the Preferences theme table
         * can jump to the theme with the closest initial. Go on to the next
         * character if the is no theme with that initial, ie. if the user
         * hits `q` and there is no theme beginning with `q`, try `r` and
         * so on.
         */
        
        if let chars: String = event.charactersIgnoringModifiers {
            // Get the tapped character -- should be only one
            var char: String = String(chars.first!)
            if char.isEmpty || char.range(of: "[a-z]", options: .regularExpression) == nil {
                return
            }
            
            // Find a the first theme with that character
            while true {
                for i in 0..<self.themes.count {
                    let theme: [String: Any] = self.themes[i] as! [String: Any]
                    let cssName: String = theme["css"] as! String
                    
                    if cssName.starts(with: char) {
                        // Matched key to theme name initial:
                        // Select the row, scroll to it and exit
                        self.themeTable.scrollRowToVisible(getRowIndex(i))
                        self.preferencesWindow.makeFirstResponder(self.themeTable)
                        return
                    }
                }
                
                // Reached the end without a selection?
                // Select the last item on the list and exit
                if char == "z" {
                    if let idx: IndexSet = getSelectionIndex(self.themes.count - 1) {
                        self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
                        self.themeTable.scrollRowToVisible(getRowIndex(self.themes.count - 1))
                        self.preferencesWindow.makeFirstResponder(self.themeTable)
                        return
                    }
                }
                
                // Move to the next character in the alphabet and try it
                let scalars = char.unicodeScalars
                let val = scalars[scalars.startIndex].value
                char = String(Character(UnicodeScalar(val + 1) ?? "z"))
            }
        }
    }
    
    
    override func scrollWheel(with event: NSEvent) {
        
        // Relay scroll events to the NSScrollView
        
        self.themeScrollView.scrollWheel(with: event)
    }
    
}

