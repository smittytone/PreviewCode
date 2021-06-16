/*
 *  AppDelegate.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Cocoa
import CoreServices
import WebKit
import Highlighter


@main
class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   URLSessionDelegate,
                   URLSessionDataDelegate,
                   WKNavigationDelegate,
                   NSTableViewDelegate,
                   NSTableViewDataSource,
                   NSTextViewDelegate {

    // MARK:- Class UI Properies
    
    // Menu Items
    @IBOutlet var helpMenuPreviewCode: NSMenuItem!
    @IBOutlet var helpMenuAcknowledgments: NSMenuItem!
    @IBOutlet var helpAppStoreRating: NSMenuItem!
    @IBOutlet var helpMenuHighlightr: NSMenuItem!
    @IBOutlet var helpMenuHighlightjs: NSMenuItem!
    @IBOutlet var helpMenuHighlighterSwift: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewMarkdown: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewYaml: NSMenuItem!
    
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
    @IBOutlet var fontNamesPopup: NSPopUpButton!
    @IBOutlet var displayModeSegmentedControl: NSSegmentedControl!

    // What's New Sheet
    @IBOutlet var whatsNewWindow: NSWindow!
    @IBOutlet var whatsNewWebView: WKWebView!

    
    // MARK:- Private Properies
    
    private var feedbackTask: URLSessionTask? = nil
    private var whatsNewNav: WKNavigation? = nil
    private var previewFontSize: CGFloat = 16.0
    private var doShowLightBackground: Bool = false
    private var appSuiteName: String = MNU_SECRETS.PID + ".suite.preview-code"
    private var feedbackPath: String = MNU_SECRETS.ADDRESS.A
    private var previewFontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
    private var previewThemeName: String = BUFFOON_CONSTANTS.DEFAULT_THEME
    private var selectedThemeIndex: Int = 37
    private var newThemeIndex: Int = 37
    private var themes: [String] = []
    private var darkThemes: [Int] = []
    private var lightThemes: [Int] = []
    private var themeDisplayMode: Int = BUFFOON_CONSTANTS.DISPLAY_MODE.ALL
    private var sampleCodeString: String = ""
    
    
    // MARK:- Class Lifecycle Functions

    func applicationDidFinishLaunching(_ notification: Notification) {
        
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
        
        // Centre the main window and display
        self.window.center()
        self.window.makeKeyAndOrderFront(self)

        // Show the 'What's New' panel if we need to
        // (and set up the WKWebBiew: no elasticity, horizontal scroller)
        // NOTE Has to take place at the end of the function
        self.whatsNewWebView.enclosingScrollView?.hasHorizontalScroller = false
        self.whatsNewWebView.enclosingScrollView?.horizontalScrollElasticity = .none
        self.whatsNewWebView.enclosingScrollView?.verticalScrollElasticity = .none
        doShowWhatsNew(self)
    }


    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {

        // When the main window closed, shut down the app
        return true
    }


    // MARK:- Action Functions

    /**
     Called from the File menu's Close item and the various Quit controls.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doClose(_ sender: Any) {
        
        // Reset the QL thumbnail cache... just in case it helps
        _ = runProcess(app: "/usr/bin/qlmanage", with: ["-r", "cache"])
        
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
        if item == self.helpMenuPreviewCode {
            path += "#how-to-use-previewcode"
        } else if item == self.helpMenuAcknowledgments {
            path += "#acknowledgements"
        } else if item == self.helpAppStoreRating {
            path = BUFFOON_CONSTANTS.APP_STORE
        } else if item == self.helpMenuOthersPreviewMarkdown {
            path = "https://apps.apple.com/us/app/previewmarkdown/id1492280469?ls=1"
        } else if item == self.helpMenuOthersPreviewYaml {
            path = "https://apps.apple.com/us/app/previewyaml/id1564574724?ls=1"
        } else if item == self.helpMenuHighlightr {
            path = "https://github.com/raspu/Highlightr"
        } else if item == self.helpMenuHighlightjs {
            path = "https://github.com/highlightjs/highlight.js"
        } else if item == self.helpMenuHighlighterSwift {
            path = "https://github.com/smittytone/HighlighterSwift"
        }
        
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


    // MARK: Report Functions
    
    /**
     Display a window in which the user can submit feedback, or report a bug.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doShowReportWindow(sender: Any) {

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
            
            self.feedbackTask = submitFeedback(feedback)
            
            if self.feedbackTask != nil {
                // We have a valid URL Session Task, so start it to send
                self.feedbackTask!.resume()
                return
            } else {
                // Report the error
                sendFeedbackError()
            }
        }
        
        // No feedback, so close the sheet
        self.window.endSheet(self.reportWindow)
        
        // NOTE sheet closes asynchronously unless there was no feedback to send,
        //      or an error occured with setting up the feedback session
    }
    
    
    /**
     Send the feedback string etc.
     
     - Parameters:
        - feedback: The text of the user's comment.
     
     - Returns: A URLSessionTask primed to send the comment, or `nil` on error.
     */
    private func submitFeedback(_ feedback: String) -> URLSessionTask? {
        
        // First get the data we need to build the user agent string
        let userAgent: String = getUserAgentForFeedback()
        let endPoint: String = MNU_SECRETS.ADDRESS.B
        
        // Get the date as a string
        let dateString: String = getDateForFeedback()

        // Assemble the message string
        let dataString: String = """
         *FEEDBACK REPORT*
         *Date:* \(dateString)
         *User Agent:* \(userAgent)
         *FEEDBACK:*
         \(feedback)
         """

        // Build the data we will POST:
        let dict: NSMutableDictionary = NSMutableDictionary()
        dict.setObject(dataString,
                        forKey: NSString.init(string: "text"))
        dict.setObject(true, forKey: NSString.init(string: "mrkdwn"))
        
        // Make and return the HTTPS request for sending
        if let url: URL = URL.init(string: self.feedbackPath + endPoint) {
            var request: URLRequest = URLRequest.init(url: url)
            request.httpMethod = "POST"

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: dict,
                                                              options:JSONSerialization.WritingOptions.init(rawValue: 0))

                request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                request.addValue("application/json", forHTTPHeaderField: "Content-type")

                let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
                let session: URLSession = URLSession.init(configuration: config,
                                                          delegate: self,
                                                          delegateQueue: OperationQueue.main)
                return session.dataTask(with: request)
            } catch {
                // NOP
            }
        }
        
        return nil
    }


    // MARK: Preferences Functions
    
    /**
     Initialise and display the 'Preferences' sheet.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowPreferences(sender: Any) {

        // The suite name is the app group name, set in each the entitlements file of
        // the host app and of each extension
        if let defaults: UserDefaults = UserDefaults(suiteName: self.appSuiteName) {
            self.previewFontSize = CGFloat(defaults.float(forKey: "com-bps-previewcode-base-font-size"))
            self.previewFontName = defaults.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT
            self.previewThemeName = defaults.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME
        }

        // Set the font size slider
        let index: Int = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.lastIndex(of: self.previewFontSize) ?? 3
        self.fontSizeSlider.floatValue = Float(index)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        
        // Set the font name popup
        // List the current system's monospace fonts
        // TODO Some outliers here, which we may want to remove manually
        let fm: NSFontManager = NSFontManager.shared
        self.fontNamesPopup.removeAllItems()
        if let fonts: [String] = fm.availableFontNames(with: .fixedPitchFontMask) {
            for font in fonts {
                if !font.hasPrefix(".") {
                    // Set the font's display name...
                    var fontDisplayName: String? = nil
                    if let namedFont: NSFont = NSFont.init(name: font, size: self.previewFontSize) {
                        fontDisplayName = namedFont.displayName
                    }
                    
                    if fontDisplayName == nil {
                        fontDisplayName = font.replacingOccurrences(of: "-", with: " ")
                    }
                    
                    // ...and add it to the popup
                    self.fontNamesPopup.addItem(withTitle: fontDisplayName!)
                    
                    // Retain the font's PostScript name for use later
                    if let addedMenuItem: NSMenuItem = self.fontNamesPopup.item(at: self.fontNamesPopup.itemArray.count - 1) {
                        addedMenuItem.representedObject = font
                        
                        if font == self.previewFontName {
                            self.fontNamesPopup.select(addedMenuItem)
                        }
                    }
                }
            }
        }
        
        // Set the themes table's contents store, once per runtime
        if self.themes.count == 0 {
            // Load in the code sample we'll preview the themes with
            if let loadedCode = loadBundleFile(BUFFOON_CONSTANTS.FILE_CODE_SAMPLE) {
                self.sampleCodeString = loadedCode
            }
            
            // Load and prepare the list of themes
            loadThemeList()
        }
        
        // Load the table with themes
        // 'newThemeIndex' starts as the current selection, but may change
        // NOTE These should always indicted an index in the full list of themes
        self.newThemeIndex = self.selectedThemeIndex
        loadTable()
        
        // Set the mode control
        var selectedMode: Int = 0
        if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK { selectedMode = 1 }
        if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT { selectedMode = 2 }
        self.displayModeSegmentedControl.selectedSegment = selectedMode
        
        // Display the sheet
        self.preferencesWindow.makeFirstResponder(self.themeTable)
        self.window.beginSheet(self.preferencesWindow, completionHandler: nil)
    }


    /**
        When the font size slider is moved and released, this function updates the font size readout.
     
        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doMoveSlider(sender: Any) {
        
        let index: Int = Int(self.fontSizeSlider.floatValue)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
    }


    /**
        When the NSSegmentedContro is clicked, change the theme mode.
     
        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doSwitchMode(sender: Any) {

        let mode: Int = self.displayModeSegmentedControl.selectedSegment
        switch (mode) {
        case 1:
            self.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.DARK
        case 2:
            self.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT
        default:
            self.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.ALL
        }
        
        // Reload the table and its selection
        loadTable()
    }
    
    
    /**
        Close the **Preferences** sheet without saving.
     
        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doClosePreferences(sender: Any) {

        self.window.endSheet(self.preferencesWindow)
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
            if newValue != self.previewFontSize {
                defaults.setValue(newValue,
                                  forKey: "com-bps-previewcode-base-font-size")
            }
            
            // Set the chosen font if it has changed
            if let selectedMenuItem: NSMenuItem = self.fontNamesPopup.selectedItem {
                let selectedName: String = selectedMenuItem.representedObject as! String
                if selectedName != self.previewFontName {
                    self.previewFontName = selectedName
                    defaults.setValue(selectedName, forKey: "com-bps-previewcode-base-font-name")
                }
            }
            
            // Update the theme selection if it has changed
            if self.newThemeIndex != self.selectedThemeIndex {
                self.selectedThemeIndex = self.newThemeIndex
                let selectedThemeName = self.themes[self.newThemeIndex]
                defaults.setValue(selectedThemeName, forKey: "com-bps-previewcode-theme-name")
            }

            // Sync any changes
            defaults.synchronize()
        }
        
        // Remove the sheet now we have the data
        self.window.endSheet(self.preferencesWindow)
    }
    
    
    // MARK: What's New Functions
    
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
                let key: String = "com-bps-previewcode-do-show-whats-new-" + getVersion()
                doShowSheet = defaults.bool(forKey: key)
            }
        }
      
        // Configure and show the sheet: first, get the folder path
        if doShowSheet {
            let htmlFolderPath = Bundle.main.resourcePath! + "/new"

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
            let key: String = "com-bps-previewcode-do-show-whats-new-" + getVersion()
            defaults.setValue(false, forKey: key)

            #if DEBUG
            print("\(key) reset back to true")
            defaults.setValue(true, forKey: key)
            #endif

            defaults.synchronize()
        }
    }

    
    // MARK:- Table Data Functions
    
    /**
     Set up the themes table.
     */
    private func loadTable() {
        
        // De-select and update the themes table
        self.themeTable.reloadData()
        self.themeTable.deselectAll(self)
        
        // Select the chosen theme
        // 'getSelectionIndex()' returns nil if nothing is selected
        // on the table, ie. a dark theme has been chosen but we're
        // viewing the light table
        if let idx: IndexSet = getSelectionIndex(self.newThemeIndex) {
            // We can use '.min()' because 'idx' should contain only one value
            let row: Int = idx.min()!
            self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
            self.themeTable.scrollRowToVisible(row)
            
            // If we're viewing a subset of the themes, converted
            // the selected row value to the row that would be selected
            // if all the data was being shown.
            self.newThemeIndex = (self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.ALL)
                ? self.themeTable.selectedRow
                : getBaseIndex(row)
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
     
     - Returns: the row to select
     */
    private func getSelectionIndex(_ indexInFullThemeList: Int) -> IndexSet? {
        
        // Assume we're showing all themes as the default
        var idx: IndexSet? = IndexSet.init(integer: indexInFullThemeList)
        
        // But check if we're actually viewing a subset
        if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            idx = nil
            for i: Int in 0..<self.darkThemes.count {
                if self.darkThemes[i] == indexInFullThemeList {
                    idx = IndexSet.init(integer: i)
                    break
                }
            }
        } else if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
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
     Calculate a main theme list index from a sub-list index.
     
     - Parameters:
        - subListIndex: The sub-list row index.
     
     - Returns: The full theme list index.
     */
    func getBaseIndex(_ subListIndex: Int) -> Int {
        
        var fullListIndex: Int = -1
        
        if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            fullListIndex = self.darkThemes[subListIndex]
        } else if self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
            fullListIndex = self.lightThemes[subListIndex]
        }
        
        return fullListIndex
    }
   
    
    // MARK:- Theme Loading Functions
    
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
        
        let themes: [String] = themesString.components(separatedBy: "\n")
        
        if themes.count > 0 {
            for theme: String in themes {
                if theme.count > 0 {
                    self.themes.append(theme)
                }
            }
        }
        
        // Set the theme selection
        // Remember this called only one per run
        for i: Int in 0..<self.themes.count {
            if self.themes[i] == self.previewThemeName {
                self.selectedThemeIndex = i
            }
            
            // Also record themes by type: these arrays
            // record indices from from the main array
            if self.themes[i].hasPrefix("d") {
                self.darkThemes.append(i)
            } else {
                self.lightThemes.append(i)
            }
        }
    }
    
    
    /**
     Load a known text file from the app bundle.
     
     - Parameters:
        - file: The name of the text file without its extension.
     
     - Returns: The contents of the loaded file
     */
    private func loadBundleFile(_ fileName: String) -> String? {
        
        // Load the required resource and return its contents
        guard let filePath: String = Bundle.main.path(forResource: fileName, ofType: "txt")
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
    
    
    // MARK:- Process Handling Functions
    
    /**
     Generic macOS process creation and run function.
     
     Make sure we clear the preference flag for this minor version, so that
     the sheet is not displayed next time the app is run (unless the version changes)
     
     - Parameters:
        - app: The location of the app.
        - with: Array of arguments to pass to the app
        
     - Returns: `true` if the operation was successful, otherwise `false`
     */
     private func runProcess(app path: String, with args: [String]) -> Bool {

        let task: Process = Process()
        task.executableURL = URL.init(fileURLWithPath: path)
        task.arguments = args

        // Pipe out the output to avoid putting it in the log
        let outputPipe: Pipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        do {
            try task.run()
        } catch {
            return false
        }

        // Block until the task has completed (short tasks ONLY)
        task.waitUntilExit()

        if !task.isRunning {
            if (task.terminationStatus != 0) {
                // Command failed -- collect the output if there is any
                let outputHandle: FileHandle = outputPipe.fileHandleForReading
                var outString: String = ""
                if let line = String(data: outputHandle.availableData, encoding: String.Encoding.utf8) {
                    outString = line
                }

                if outString.count > 0 {
                    print("\(outString)")
                } else {
                    print("Error", "Exit code \(task.terminationStatus)")
                }
                return false
            }
        }

        return true
    }


    // MARK: - Misc Functions

    /**
     Present an error message specific to sending feedback.
     
     This is called from multiple locations: if the initial request can't be created,
     there was a send failure, or a server error
     */
     private func sendFeedbackError() {

        let alert: NSAlert = showAlert("Feedback Could Not Be Sent",
                                       "Unfortunately, your comments could not be send at this time. Please try again later.")
        alert.beginSheetModal(for: self.reportWindow,
                              completionHandler: nil)
        
    }


    /**
     Generic alert generator.
     
     - Parameters:
        - head:    The alert's title.
        - message: The alert's message.
     
     - Returns: The NSAlert
     */
     private func showAlert(_ head: String, _ message: String) -> NSAlert {

        let alert: NSAlert = NSAlert()
        alert.messageText = head
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        return alert
    }


    /**
     Called by the app at launch to register its initial defaults.
     */
     private func registerPreferences() {

        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            // Check if each preference value exists -- set if it doesn't
            // Preview body font size, stored as a CGFloat
            // Default: 16.0
            let previewFontSizeDefault: Any? = defaults.object(forKey: "com-bps-previewcode-base-font-size")
            if previewFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE),
                                  forKey: "com-bps-previewcode-base-font-size")
            }

            // Thumbnail view base font size, stored as a CGFloat, not currently used
            // Default: 32.0
            let thumbFontSizeDefault: Any? = defaults.object(forKey: "com-bps-previewcode-thumb-font-size")
            if thumbFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE),
                                  forKey: "com-bps-previewcode-thumb-font-size")
            }

            // Font for previews and thumbnails
            // Default: Courier
            let codeFontName: Any? = defaults.object(forKey: "com-bps-previewcode-base-font-name")
            if codeFontName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULT_FONT,
                                  forKey: "com-bps-previewcode-base-font-name")
            }
            
            // Theme for previews
            let themeName: Any? = defaults.object(forKey: "com-bps-previewcode-theme-name")
            if themeName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULT_THEME, forKey: "com-bps-previewcode-theme-name")
            }

            // Use light background even in dark mode, stored as a bool
            // Default: false
            // NOTE Currently unused
            let useLightDefault: Any? = defaults.object(forKey: "com-bps-previewcode-do-use-light")
            if useLightDefault == nil {
                defaults.setValue(false,
                                  forKey: "com-bps-previewcode-do-use-light")
            }

            // Show the What's New sheet
            // Default: true
            // This is a version-specific preference suffixed with, eg, '-2-3'. Once created
            // this will persist, but with each new major and/or minor version, we make a
            // new preference that will be read by 'doShowWhatsNew()' to see if the sheet
            // should be shown this run
            let key: String = "com-bps-previewcode-do-show-whats-new-" + getVersion()
            let showNewDefault: Any? = defaults.object(forKey: key)
            if showNewDefault == nil {
                defaults.setValue(true, forKey: key)
            }
            
            // Sync any additions
            defaults.synchronize()
        }

    }
    
    
    /**
     Build a basic 'major.manor' version string for prefs usage.
     
     - Returns: The version string
     */
     private func getVersion() -> String {

        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let parts: [String] = (version as NSString).components(separatedBy: ".")
        return parts[0] + "-" + parts[1]
    }
    
    
    /**
     Build a date string string for feedback usage.
     
     - Returns: The date string
     */
     private func getDateForFeedback() -> String {

        let date: Date = Date()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date)
    }


    /**
     Build a user-agent string string for feedback usage.
     
     - Returns: The user-agent string
     */
     private func getUserAgentForFeedback() -> String {

        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let bundle: Bundle = Bundle.main
        let app: String = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version: String = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return "\(app)/\(version)-\(build) (Mac macOS \(sysVer.majorVersion).\(sysVer.minorVersion).\(sysVer.patchVersion))"
    }

    
    // MARK: - URLSession Delegate Functions

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {

        // Some sort of connection error - report it
        self.connectionProgress.stopAnimation(self)
        sendFeedbackError()
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // The operation to send the comment completed
        self.connectionProgress.stopAnimation(self)
        if let _ = error {
            // An error took place - report it
            sendFeedbackError()
        } else {
            // The comment was submitted successfully
            let alert: NSAlert = showAlert("Thanks For Your Feedback!",
                                           "Your comments have been received and we’ll take a look at them shortly.")
            alert.beginSheetModal(for: self.reportWindow) { (resp) in
                // Close the feedback window when the modal alert returns
                let _: Timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
                    self.window.endSheet(self.reportWindow)
                }
            }
        }
    }


    // MARK: - NSTableView Data Source / Delegate Functions
    
    func numberOfRows(in tableView: NSTableView) -> Int {

        // Just return the number of themes available
        switch (self.themeDisplayMode) {
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
            let index: Int = (self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.ALL) ? row : getBaseIndex(row)
            let theme: String = self.themes[index]
            let themeParts: [String] = theme.components(separatedBy: ".")
            cell!.themePreviewTitle.stringValue = themeParts[1].replacingOccurrences(of: "-", with: " ").capitalized
            cell!.themeIndex = index
            
            // Generate the theme preview view programmatically
            let ptv: PreviewTextView = PreviewTextView.init(frame: NSMakeRect(3, 4, 256, 134))
            
            // We want the text view to be selectable but not editable
            ptv.isEditable = false

            if let renderTextStorage: NSTextStorage = ptv.textStorage {
                setThemeValues(self.themes[index])
                renderTextStorage.beginEditing()
                renderTextStorage.setAttributedString(getAttributedString(self.sampleCodeString, "swift", false))
                renderTextStorage.endEditing()
                ptv.backgroundColor = getBackgroundColour()
            }
            
            // Add the new view to the cell
            cell!.addSubview(ptv)
            
            // IMPORTANT Don't set the delegate until the PreviewTextView has
            //           been added to the superview
            ptv.delegate = self
        }

        return cell
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        /* Get the clicked NSTableCellView and use it to d get the table row
         * that we need to select
         */
        
        self.newThemeIndex = (self.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.ALL)
            ? self.themeTable.selectedRow
            : getBaseIndex(self.themeTable.selectedRow)
        
        // Make sure the table becomes first responder so that the selection
        // is highlighted correctly
        if self.themeTable.selectedRow != -1 {
            self.preferencesWindow.makeFirstResponder(self.themeTable)
        }
    }
    
    
    // MARK: - NSTextView Delegate Functions
    
    func textViewDidChangeSelection(_ notification: Notification) {
        
        /* Get the clicked NSTextView and use it to determine the parent
         * ThemeTableCellView, from which we get the table row that
         * we need to select
         */
        
        let clickedView: PreviewTextView = notification.object as! PreviewTextView
        let parentView: ThemeTableCellView = clickedView.superview as! ThemeTableCellView
        if let idx: IndexSet = getSelectionIndex(parentView.themeIndex) {
            self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
            self.newThemeIndex = parentView.themeIndex
            self.preferencesWindow.makeFirstResponder(self.themeTable)
        }
    }
    
    
    // MARK: - WKWebViewNavigation Delegate Functions
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        /*
         * Asynchronously show the sheet once the HTML has loaded
         * (triggered by delegate method)
         */
        
        if let nav = self.whatsNewNav {
            if nav == navigation {
                // Display the sheet
                self.window.beginSheet(self.whatsNewWindow, completionHandler: nil)
            }
        }
    }

}

