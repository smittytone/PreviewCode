/*
 *  AppDelegateSettings.swift
 *  PreviewCode
 *  Extension for AppDelegate providing settings handling functionality.
 *
 *  Created by Tony Smith on 18/07/2025.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */

import AppKit


extension AppDelegate {



    /**
     Update UI when we are about to switch to it
     */
    internal func willShowSettingsPage() {

        // Set the themes table's contents store, once per runtime
        if self.themes.count == 0 {
            // Load and prepare the list of themes
            loadThemeList()
        }

        // Load the table with themes
        loadTable()

        // Enable the Apply button if something has changed
        self.applyButton.isEnabled = checkSettingsOnQuit()
    }


    // MARK: - User Action Functions
    
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
     Called when the user selects a font from either list.

     FROM 1.1.0

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doUpdateFonts(sender: Any) {

        // From 1.2.1
        // If the user re-selects the current font family,
        // only update the style popup if a different family
        // has been selected
        //self.havePrefsChanged = true
        let item: NSPopUpButton = sender as! NSPopUpButton
        if item == self.fontNamePopup {
            let currentFontPSName: NSString = self.currentSettings.fontName as NSString
            let selectedFontName: String = item.titleOfSelectedItem ?? BUFFOON_CONSTANTS.DEFAULT_FONT_NAME
            if !(currentFontPSName.contains(selectedFontName)) {
                // Update the menu of available styles
                // because a different font has been selected
                setStylePopup(self.fontFacePopup.titleOfSelectedItem ?? "Regular")
                return
            }
        } else {
            // The user clicked the style popup, so record the style
            self.codeStyleName = self.fontFacePopup.titleOfSelectedItem ?? "Regular"
        }
    }


    /**
     Handler for controls whose values are read.

     FROM 2.0.0

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    internal func doChangeValue(sender: Any) {

        willShowSettingsPage()
    }


    /**
     The user has clicked on the Settings > Apply button.

     FROM 2.0.0

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    internal func doApplyCurrentSettings(sender: Any) {

         // First, make sure changes have been made
         if checkSettingsOnQuit() {
             // Changes are present, so save them.
             // NOTE This call updates the current settings values from the Settings tab UI.
             saveSettings()
             willShowSettingsPage()
         }
    }


    /**
     The user has clicked on the Settings > Defaults button.

     NOTE This does not save the settings, it only updates Settings tab UI state.

     FROM 2.0.0

     - Parameters:
        - sender: The source of the action.
     */
   @IBAction
   internal func doApplyDefaultSettings(sender: Any) {

       displaySettings(PCSettings())
       willShowSettingsPage()
    }


    // MARK: - Settings Maintenance Functions

    /**
     Update the UI with the supplied settings.

     FROM 2.0.0

     - Parameters:
        - settings: An instance holding the settings to show in the UI.
     */
    internal func displaySettings(_ settings: PCSettings) {

        // Set the font size slider
        let index: Int = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.lastIndex(of: settings.fontSize) ?? 3
        self.fontSizeSlider.floatValue = Float(index)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"

        // FROM 1.1.0
        // Set the font name popup
        // List the current system's monospace fonts
        self.fontNamePopup.removeAllItems()
        for i: Int in 0..<self.fonts.count {
            let font: PMFont = self.fonts[i]
            self.fontNamePopup.addItem(withTitle: font.displayName)
        }

        // Set the style popup
        self.fontFacePopup.isEnabled = false
        selectFontByPostScriptName(settings.fontName)

        // Set the themes table's contents store, once per runtime
        // (needed for the section below, but should have been done)
        if self.themes.count == 0 {
            // Load and prepare the list of themes
            loadThemeList()
        }

        // Use the loaded theme names to find and set the human-reabable name in the UI
        for i in 0..<self.themes.count {
            let theme: [String: Any] = self.themes[i] as! [String: Any]
            let cName: String = codedName(i)

            if settings.lightThemeName == cName {
                self.lightThemeLabel.stringValue = theme["name"] as! String
                //self.lightThemeIndex = i
                //self.newLightThemeIndex = i
            }

            if settings.darkThemeName == cName {
                self.darkThemeLabel.stringValue = theme["name"] as! String
                //self.darkThemeIndex = i
                //self.newDarkThemeIndex = i
            }
        }

        // Load the table with themes
        loadTable(settings)

        // FROM 1.3.0
        // Set the mode control
        switch(settings.themeDisplayMode) {
            case BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT:
                self.lightRadioButton.state = .on
                self.lightThemeLabel.textColor = NSColor.labelColor
                self.lightThemeIcon.isOutlined = true
                self.darkThemeLabel.textColor = NSColor.gray
                self.darkThemeIcon.isOutlined = false
                self.themeHelpLabel.stringValue = "Always use the selected light theme"
            case BUFFOON_CONSTANTS.DISPLAY_MODE.DARK:
                self.darkRadioButton.state = .on
                self.lightThemeLabel.textColor = NSColor.gray
                self.lightThemeIcon.isOutlined = false
                self.darkThemeLabel.textColor = NSColor.labelColor
                self.darkThemeIcon.isOutlined = true
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
        //self.themeTable.nextResponder = self

        // FROM 1.3.0
        // Set the line spacing selector
        switch(round(settings.lineSpacing * 100) / 100.0) {
            case 1.25:
                self.lineSpacingPopup.selectItem(at: 1)
            case 1.5:
                self.lineSpacingPopup.selectItem(at: 2)
            case 2.0:
                self.lineSpacingPopup.selectItem(at: 3)
            default:
                self.lineSpacingPopup.selectItem(at: 0)
        }
    }


    /**
     Generate a set of settings derived from the state of the UI - except for the colour values,
     as these are stored directly in the current settings store. THIS WILL CHANGE

     FROM 2.0.0

     - Returns A settings instance.
     */
    internal func settingsFromDisplay() -> PCSettings {

        let displayedSettings = PCSettings()
        displayedSettings.fontSize = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
        displayedSettings.fontName = getPostScriptName() ?? BUFFOON_CONSTANTS.DEFAULT_FONT

        if self.lightRadioButton.state == .on {
            displayedSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT
        } else if self.darkRadioButton.state == .on {
            displayedSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.DARK
        } else {
            displayedSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
        }

        // NOTE These use the current settings. This is WRONG - should use the UI
        displayedSettings.darkThemeIndex = self.currentSettings.darkThemeIndex
        displayedSettings.lightThemeIndex = self.currentSettings.lightThemeIndex

        displayedSettings.darkThemeName = codedName(displayedSettings.darkThemeIndex)
        displayedSettings.lightThemeName = codedName(displayedSettings.lightThemeIndex)

        let linespacingValues: [CGFloat] = [1.0, 1.15, 1.5, 2.0]
        assert(self.lineSpacingPopup.indexOfSelectedItem < linespacingValues.count)
        displayedSettings.lineSpacing = linespacingValues[self.lineSpacingPopup.indexOfSelectedItem]

        // FROM 2.0.0
        //displayedSettings.doShowMargin = self.showMarginCheckbox.state == .on

        return displayedSettings
    }


    /**
     Called by the app at launch to register its initial defaults.
     */
     internal func registerSettings() {

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
     Populate the current settings value with those read from disk.
     */
    internal func loadSettings() {

        // Get the settings off the disk
        self.currentSettings.loadSettings(self.appSuiteName)

        if let index = getIndex(of: self.currentSettings.darkThemeName) {
            self.currentSettings.darkThemeIndex = index
        }

        if let index = getIndex(of: self.currentSettings.lightThemeName) {
            self.currentSettings.lightThemeIndex = index
        }

        // Use the loaded settings to update the Settings UI
        displaySettings(self.currentSettings)

        if !self.initialLoadDone {
            // Settings page elements have been set to reflect the current settings,
            // either default values at the start, or custom values subsequently.
            self.initialLoadDone = true
        }
    }


    /**
     Write Settings page state values to disk, but only those that have been changed.
     If this happens, also update the current settings store.
     */
    internal func saveSettings() {

        // Update the current settings store with values from the UI
        // NOTE We need to preserve the `displayColours` values, so copy them to
        //      the temporary store first.
        let displayedSettings = settingsFromDisplay()
        self.currentSettings = displayedSettings
        self.currentSettings.saveSettings(self.appSuiteName)
    }


    public func getIndex(of themename: String) -> Int? {

        // Set the themes table's contents store, once per runtime
        if self.themes.count == 0 {
            // Load and prepare the list of themes
            loadThemeList()
        }

        var outer = -1
        for i in 0..<self.themes.count {
            if themename == codedName(i) {
                outer = i
                break
            }
        }

        for i in 0..<self.darkThemes.count {
            if self.darkThemes[i] == outer {
                return i
            }
        }

        for i in 0..<self.lightThemes.count {
            if self.lightThemes[i] == outer {
                return i
            }
        }

        // ERROR: Theme not found
        return nil
    }


    /**
     Compare the current Settings page values to those we have stored in `currentSettings`.
     If any are different, we need to warn the user.

     FROM 2.0.0

     - Returns:
        `true` if one or more settings has changed, otherwise `false`.
     */
    internal func checkSettingsOnQuit() -> Bool {

        let displayedSettings = settingsFromDisplay()
        var settingsHaveChanged = self.currentSettings.fontSize != displayedSettings.fontSize

        if !settingsHaveChanged {
            settingsHaveChanged = !self.currentSettings.lineSpacing.isClose(to: displayedSettings.lineSpacing)
        }

        if !settingsHaveChanged {
            settingsHaveChanged = self.currentSettings.fontName != displayedSettings.fontName
        }

        if !settingsHaveChanged {
            settingsHaveChanged = self.currentSettings.themeDisplayMode != displayedSettings.themeDisplayMode
        }

        if !settingsHaveChanged {
            settingsHaveChanged = self.currentSettings.darkThemeName != displayedSettings.darkThemeName
        }

        if !settingsHaveChanged {
            settingsHaveChanged = self.currentSettings.lightThemeName != displayedSettings.lightThemeName
        }

        // FROM 2.0.0
        //if !settingsHaveChanged {
        //    settingsHaveChanged = self.currentSettings.doShowMargin != displayedSettings.doShowMargin
        //}

        return settingsHaveChanged
    }





    /**
     Close the **Preferences** sheet and save any settings that have changed.
     
     - Parameters:
        - sender: The source of the action.

    @IBAction
    private func doSavePreferences(sender: Any) {

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
        //self.window.endSheet(self.preferencesWindow)

        // FROM 1.2.5
        // Restore menus
        showPanelGenerators()
    }
     */

    /**
     Close the **Preferences** sheet without saving.
     
     - Parameters:
        - sender: The source of the action.

    @IBAction
    private func doClosePreferences(sender: Any) {
        
        if checkPrefs() {
            let alert: NSAlert = showAlert("You have made changes",
                                           "Do you wish to go back and save them, or ignore them? ",
                                           false)
            alert.addButton(withTitle: "Go Back")
            alert.addButton(withTitle: "Ignore Changes")
            alert.beginSheetModal(for: self.window) { (response: NSApplication.ModalResponse) in
                if response != NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user clicked 'Cancel'
                    //self.closePrefsWindow()
                }
            }
        } else {
            //closePrefsWindow()
        }
    }
    */

    /*
    private func closePrefsWindow() {
        
        // Close the **Preferences** sheet
        self.window.endSheet(self.preferencesWindow)
        
        // Restore menus
        showPanelGenerators()
    }

    internal func checkPrefs() -> Bool {
        
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
     */

    /**
     When a radio button is clicked, change the theme mode.
     
     - Parameters:
        - sender: The source of the action.
     */
    @IBAction
    private func doSwitchMode(sender: Any) {
        
        // FROM 1.3.0
        // Support radio buttons for mode control:
        // Light only, dark only, or mixed mode.
        if self.lightRadioButton.state == .on {
            self.currentSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT
            self.lightThemeLabel.textColor = NSColor.labelColor
            self.darkThemeLabel.textColor = NSColor.gray
            self.darkThemeIcon.isOutlined = false
            self.lightThemeIcon.isOutlined = true
            self.themeHelpLabel.stringValue = "Always use the selected light theme"
        } else if self.darkRadioButton.state == .on {
            self.currentSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.DARK
            self.lightThemeLabel.textColor = NSColor.gray
            self.darkThemeLabel.textColor = NSColor.labelColor
            self.darkThemeIcon.isOutlined = true
            self.lightThemeIcon.isOutlined = false
            self.themeHelpLabel.stringValue = "Always use the selected dark theme"
        } else if self.autoRadioButton.state == .on {
            self.currentSettings.themeDisplayMode = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
            self.lightThemeLabel.textColor = NSColor.labelColor
            self.darkThemeLabel.textColor = NSColor.labelColor
            self.darkThemeIcon.isOutlined = true
            self.lightThemeIcon.isOutlined = true
            self.themeHelpLabel.stringValue = "Use the selected theme based on the host Mac’s mode"
        }
        
        // Reload the table and its selection
        loadTable()
    }


    // MARK: - Table Data Functions
    
    /**
     Set up the themes table.
     */
    private func loadTable(_ settings: PCSettings? = nil) {

        // De-select and update the themes table
        self.themeTable.reloadData()
        self.themeTable.deselectAll(self)
        
        // Select the chosen theme
        var index: Int = settings != nil ? settings!.lightThemeIndex : self.currentSettings.lightThemeIndex
        if self.currentSettings.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            index = settings != nil ? settings!.darkThemeIndex : self.currentSettings.darkThemeIndex
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

        self.themeTable.nextResponder = self
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
        if self.currentSettings.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
            idx = nil
            for i: Int in 0..<self.darkThemes.count {
                if self.darkThemes[i] == indexInFullThemeList {
                    idx = IndexSet.init(integer: i)
                    break
                }
            }
        } else if self.currentSettings.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
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
    internal func loadThemeList() {
        
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
            //let codedThemeName: String = codedName(i)
            //if codedThemeName == self.themeName {
            //    self.selectedThemeIndex = i
            //}

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
    @IBAction
    private func doRenderThemes(_ sender: Any) {

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

        // Just return the number of themes available, using the
        // three lists prepare of dark, light and all themes, and
        // the current preferred mode
        switch (self.currentSettings.themeDisplayMode) {
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
        //if self.themeTable.selectedRow != -1 {
            //self.preferencesWindow.makeFirstResponder(self.themeTable)
        //}

        // FROM 1.3.0
        // Make the changes according to the currently selected mode
        switch(self.currentSettings.themeDisplayMode) {
            case BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT:
                self.currentSettings.lightThemeIndex = getBaseIndex(self.themeTable.selectedRow)
                let theme: [String: Any] = self.themes[self.currentSettings.lightThemeIndex] as! [String: Any]
                self.lightThemeLabel.stringValue = theme["name"] as! String
            case BUFFOON_CONSTANTS.DISPLAY_MODE.DARK:
                self.currentSettings.darkThemeIndex = getBaseIndex(self.themeTable.selectedRow)
                let theme: [String: Any] = self.themes[self.currentSettings.darkThemeIndex] as! [String: Any]
                self.darkThemeLabel.stringValue = theme["name"] as! String
            default:
                // Get the referenced theme (all are listed) and use it to make the correct
                // theme selection: light or dark
                self.newThemeIndex = self.themeTable.selectedRow
                let theme: [String: Any] = self.themes[self.themeTable.selectedRow] as! [String: Any]
                if theme["dark"] as! Bool {
                    self.currentSettings.darkThemeIndex = self.themeTable.selectedRow
                    self.darkThemeLabel.stringValue = theme["name"] as! String
                } else {
                    self.currentSettings.lightThemeIndex = self.themeTable.selectedRow
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
            //self.preferencesWindow.makeFirstResponder(self.themeTable)

            // FROM 1.3.0
            // Update the indices for each type
            if self.currentSettings.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.DARK {
                self.currentSettings.darkThemeIndex = parentView.themeIndex
            } else if self.currentSettings.themeDisplayMode == BUFFOON_CONSTANTS.DISPLAY_MODE.LIGHT {
                self.currentSettings.lightThemeIndex = parentView.themeIndex
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
                        //self.preferencesWindow.makeFirstResponder(self.themeTable)
                        return
                    }
                }
                
                // Reached the end without a selection?
                // Select the last item on the list and exit
                if char == "z" {
                    if let idx: IndexSet = getSelectionIndex(self.themes.count - 1) {
                        self.themeTable.selectRowIndexes(idx, byExtendingSelection: false)
                        self.themeTable.scrollRowToVisible(getRowIndex(self.themes.count - 1))
                        //self.preferencesWindow.makeFirstResponder(self.themeTable)
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
