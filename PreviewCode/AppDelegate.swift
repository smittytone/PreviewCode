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
                   NSControlTextEditingDelegate,
                   NSWindowDelegate {

    // MARK: - Class UI Properies
    
    // Menu Items
    @IBOutlet var helpMenuOnlineHelp: NSMenuItem!
    @IBOutlet var helpMenuAcknowledgments: NSMenuItem!
    @IBOutlet var helpMenuAppStoreRating: NSMenuItem!
    @IBOutlet var helpMenuHighlightr: NSMenuItem!
    @IBOutlet var helpMenuHighlightjs: NSMenuItem!
    @IBOutlet var helpMenuHighlighterSwift: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewMarkdown: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewJson: NSMenuItem!
    @IBOutlet var helpMenuRenderThemes: NSMenuItem!
    // FROM 1.2.5
    @IBOutlet var helpMenuWhatsNew: NSMenuItem!
    @IBOutlet var helpMenuReportBug: NSMenuItem!
    @IBOutlet var mainMenuSettings: NSMenuItem!
    
    // Main Widnow
    @IBOutlet var window: NSWindow!
    @IBOutlet weak var infoButton: NSButton!
    @IBOutlet weak var settingsButton: NSButton!
    @IBOutlet weak var feedbackButton: NSButton!
    @IBOutlet weak var mainTabView: NSTabView!

    // Window > Info Tab Items
    @IBOutlet var versionLabel: NSTextField!
    @IBOutlet var infoLabel: NSTextField!

    // Window > Settings Tab Items
    @IBOutlet weak var fontSizeSlider: NSSlider!
    @IBOutlet weak var fontSizeLabel: NSTextField!
    @IBOutlet weak var fontNamePopup: NSPopUpButton!
    @IBOutlet weak var fontFacePopup: NSPopUpButton!
    @IBOutlet weak var darkRadioButton: NSButton!
    @IBOutlet weak var lightRadioButton: NSButton!
    @IBOutlet weak var autoRadioButton: NSButton!
    @IBOutlet weak var darkThemeLabel: NSTextField!
    @IBOutlet weak var lightThemeLabel: NSTextField!
    @IBOutlet weak var darkThemeIcon: PCImageView!
    @IBOutlet weak var lightThemeIcon: PCImageView!
    @IBOutlet weak var themeHelpLabel: NSTextField!
    @IBOutlet weak var lineSpacingPopup: NSPopUpButton!
    @IBOutlet weak var themeScrollView: NSScrollView!
    @IBOutlet weak var themeTable: NSTableView!
    @IBOutlet weak var applyButton: NSButton!
    // FROM 2.0.0
    @IBOutlet weak var showLineNumbersCheckbox: NSButton!
    @IBOutlet weak var settingsHelpButton: NSButton!
    @IBOutlet weak var defaultsButton: NSButton!

    // Window > Feedback Tab Items
    @IBOutlet weak var feedbackText: PCTextField!
    @IBOutlet weak var connectionProgress: NSProgressIndicator!
    @IBOutlet weak var messageSizeLabel: NSTextField!
    @IBOutlet weak var messageSendButton: NSButton!

    // What's New Sheet
    @IBOutlet var whatsNewWindow: NSWindow!
    @IBOutlet var whatsNewWebView: WKWebView!


    // MARK: - Private Properies

    internal var currentSettings: PCSettings    = PCSettings()
    internal var whatsNewNav: WKNavigation?     = nil
    internal var feedbackTask: URLSessionTask?  = nil
    internal var fonts: [PMFont]                = []
    internal var themes: [Any]                  = []
    internal var darkThemes: [Int]              = []
    internal var lightThemes: [Int]             = []
    internal var themeDisplayMode: Int          = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    internal var darkThemeIndex: Int            = 30    // atom-one-dark
    internal var lightThemeIndex: Int           = 29    // atom-one-light
    // FROM 2.0.0
    private  var tabManager: PMTabManager       = PMTabManager()
    internal var hasSentFeedback: Bool          = false

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
        DispatchQueue(label: "com.bps.previecode.async-queue").async {
            self.asyncGetFonts()
        }
        
        // Set application group-level defaults
        registerSettings()
        
        // Add the app's version number to the UI
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.stringValue = "Version \(version) (\(build))"

        // Disable the Help menu Spotlight features
        let dummyHelpMenu: NSMenu = NSMenu(title: "Dummy")
        let theApp = NSApplication.shared
        theApp.helpMenu = dummyHelpMenu
        
        // FROM 1.2.0
        // Output language list for debugging
#if DEBUG
        if let hr: Highlighter = Highlighter() {
            let list: [String] = hr.supportedLanguages()
            print("***** Languages  *****")
            for language in list {
                print(language)
            }
            print("**********************")
        }
#endif

        // FROM 2.0.0
        // Configure the tab manager
        self.tabManager.parent = self
        self.tabManager.buttons.append(self.infoButton)
        self.tabManager.buttons.append(self.settingsButton)
        self.tabManager.buttons.append(self.feedbackButton)
        self.infoButton.toolTip = "About PreviewCode 2"
        self.settingsButton.toolTip = "Set preview styles and content"
        self.feedbackButton.toolTip = "Send feedback to the developer"
        self.infoButton.alphaValue = 1.0
        self.settingsButton.alphaValue = 1.0
        self.feedbackButton.alphaValue = 1.0

        // Add callback closures, one per tab, to the tab manager
        self.tabManager.callbacks.append(nil)   // Info tab
        self.tabManager.callbacks.append {      // Settings tab
            self.willShowSettingsPage()
        }
        self.tabManager.callbacks.append {
            self.willShowFeedbackPage()         // Feedback tab
        }

        // Clear the `Feedback` tab
        // NOTE Don't initialise the Settings tab here too:
        //      It must happen after we've got a list of fonts
        initialiseFeedback()

        // Set the `Settings` tab's tooltips
        initialiseSettings()

        // Show the `What's New` panel if we need to
        // NOTE Has to take place at the end of the function
        doShowWhatsNew(self)

        // Centre the main window and display
        setInfoText()
        self.window.initialFirstResponder = self.themeTable
        self.window.delegate = self
        self.window.center()
        self.window.makeKeyAndOrderFront(self)
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

        // FROM 2.0.0
        closeBasics()
        closeSettings()
    }


    /**
     Close sheets and perform other general close-related tasks.

     FROM 2.0.0
     */
    internal func closeBasics() {

        // FROM 1.3.0
        // Reset the QL thumbnail cache... just in case (don't think this does anything)
        _ = runProcess(app: "/usr/bin/qlmanage", with: ["-r", "cache"])

        // Close the What's New sheet if it's open
        if self.whatsNewWindow.isVisible {
            self.whatsNewWindow.close()
        }
    }


    /**
     Handle a settings-change call to action, if there is one, and either bail (to allow the user
     to save the settings) or move on to the feedback check.

     FROM 2.0.0
     */
    internal func closeSettings() {

        // Are there any unsaved changes to the settings?
        if checkSettingsOnQuit() {
            let alert: NSAlert = showAlert("You have unsaved settings",
                                           "Do you wish to cancel and save or change them, or quit the app anyway?",
                                           false)
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: self.window) { (response: NSApplication.ModalResponse) in
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user clicked 'Quit': now check for feedback changes
                    self.closeFeedback()
                }
            }

            // Exit the close process to allow the user to save their changed settings
            return
        }

        // Move on to the next phase: the feedback check
        closeFeedback()
    }


    /**
     Handle a feedback-unsent call to action, if one is needed, and either bail (to all the user
     to send the feedback) or close the main window.

     FROM 2.0.0
     */
    internal func closeFeedback() {

        // Does the feeback page contain text? If so let the user know
        if self.feedbackText.stringValue.count > 0 && !self.hasSentFeedback {
            let alert: NSAlert = showAlert("You have unsent feedback",
                                           "Do you wish to cancel and send it, or quit the app anyway?",
                                           false)
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: self.window) { (response: NSApplication.ModalResponse) in
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user clicked 'Quit'
                    self.window.close()
                }
            }

            // Exit the close process to allow the user to send their entered feedback
            return
        }

        // No feedback text to send/ignore so close the window which will trigger an app closure
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
        } else if item == self.helpMenuOthersPreviewJson {
            path = BUFFOON_CONSTANTS.APP_URLS.PJ
        }
        
        // Open the selected website
        NSWorkspace.shared.open(URL(string:path)!)
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
        NSWorkspace.shared.open(URL(string:path)!)

    }


    /**
     Open the System Preferences app at the Extensions pane.

     UNUSED 2.0.0

     - Parameters:
        - sender: The source of the action.

    @IBAction
    private func doOpenSysPrefs(sender: Any) {

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    }
     */


    @IBAction
    private func doSwitchTab(sender: NSButton) {

        // FROM 2.0.0
        self.tabManager.buttonClicked(sender)
    }


    @IBAction
    private func doShowSettings(sender: Any) {

        // FROM 2.0.0
        self.tabManager.programmaticallyClickButton(at: 1)
    }


    @IBAction
    private func doShowFeedback(sender: Any) {

        // FROM 2.0.0
        self.tabManager.programmaticallyClickButton(at: 2)
    }


    // MARK: - Window Set Up Functions

    /**
     Create and display the information text label. This is done programmatically
     because we're using an NSAttributedString rather than a plain string.
     */
    private func setInfoText() {

        // Set the attributes
        let bodyAtts: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13.0),
            .foregroundColor: NSColor.labelColor
        ]

        let boldAtts : [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13.0, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]

        let infoText: NSMutableAttributedString = NSMutableAttributedString(string: "You need only run this app once, to register its Code Previewer and Code Thumbnailer application extensions with macOS. You can then manage these extensions in ", attributes: bodyAtts)
        let boldText: NSAttributedString = NSAttributedString(string: "System Settings > Extensions > Quick Look", attributes: boldAtts)
        infoText.append(boldText)
        infoText.append(NSAttributedString(string: ".\n\nCases where previews cannot be rendered can usually be resolved by logging out of your Mac, logging in again and running this app once more.", attributes: bodyAtts))
        self.infoLabel.attributedStringValue = infoText
    }


    // MARK: - NSWindowDelegate Functions

    /**
     Catch when the user clicks on the window's red close button.

     FROM 2.0.0
     */
    func windowShouldClose(_ sender: NSWindow) -> Bool {

        if !checkFeedbackOnQuit() && !checkSettingsOnQuit() {
            // No unsaved settings or unsent feedback, so we're good to close
            return true
        }

        // Close mmanually
        // NOTE The above check will fail if there are settings changes and/or
        //      unsent feedback, in which case the following calls will trigger
        //      alerts
        closeBasics()
        closeSettings()
        return false
    }
}

