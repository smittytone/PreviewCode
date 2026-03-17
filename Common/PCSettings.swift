/*
 *  PCSettings.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 08/10/2024.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import Foundation


/**
 Internal settings record structure.
 Values are pre-set to the app defaults.
 */

class PCSettings {

    // MARK: Properties
    var fontName: String                    = BUFFOON_CONSTANTS.DEFAULTS.FONT
    var fontSize: CGFloat                   = CGFloat(BUFFOON_CONSTANTS.DEFAULTS.FONT_SIZE)
    var lineSpacing: CGFloat                = BUFFOON_CONSTANTS.DEFAULTS.LINE_SPACING
    var darkThemeName: String               = BUFFOON_CONSTANTS.DEFAULTS.DARK_THEME
    var lightThemeName: String              = BUFFOON_CONSTANTS.DEFAULTS.LIGHT_THEME
    var themeDisplayMode: Int               = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    var doShowLineNumbers: Bool             = false
    // FROM 2.2.3
    var doShowMargin: Bool                  = false                                             // Advanced
    var previewMarginWidth: CGFloat         = BUFFOON_CONSTANTS.PREVIEW_MARGIN_WIDTH            // Advanced
    var previewWindowScale: CGFloat         = BUFFOON_CONSTANTS.SCALERS.WINDOW_SIZE_L           // Advanced
    var thumbnailMatchFinderMode: Bool      = false                                             // Advanced

    // MARK: Retrieve and Persist Functions

    /**
     Populate the current settings value with those read from disk.

     - Parameters:
        - suite The App Suite name under which the defaults are recorded.
     */
    func loadSettings(_ suite: String) {
        
        // The suite name is the app group name, set in each extension's entitlements, and the host app's
        if let defaults = UserDefaults(suiteName: suite) {
            self.fontName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME) ?? BUFFOON_CONSTANTS.DEFAULTS.FONT
            self.fontSize = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE))
            self.lineSpacing = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING))
            self.darkThemeName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME) ?? BUFFOON_CONSTANTS.DEFAULTS.DARK_THEME
            self.lightThemeName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME) ?? BUFFOON_CONSTANTS.DEFAULTS.LIGHT_THEME
            self.themeDisplayMode = defaults.integer(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            self.doShowLineNumbers = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_LINE_NUMBERS)
            // FROM 2.2.3
            self.doShowMargin = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN)
            self.previewMarginWidth = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_MARGIN))
            self.previewWindowScale = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_WINDOW_SCALE))
            self.thumbnailMatchFinderMode = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MATCH_MODE)
        }
    }


    /**
     Write Settings page state values to disk, but only those that have been changed.
     If this happens, also update the current settings store

     - Parameters:
        - suite The App Suite name under which the defaults are recorded.
     */
    func saveSettings(_ suite: String) {
        
        if let defaults = UserDefaults(suiteName: suite) {
            // TO-DO Test each on to see if the setting needs to be saved
            defaults.setValue(self.fontName, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
            defaults.setValue(self.fontSize, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            defaults.setValue(self.lineSpacing, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            defaults.setValue(self.darkThemeName, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            defaults.setValue(self.lightThemeName, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            defaults.setValue(self.themeDisplayMode, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            defaults.setValue(self.doShowLineNumbers, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_LINE_NUMBERS)
            // FROM 2.2.3
            defaults.setValue(self.doShowMargin, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN)
            defaults.setValue(self.previewMarginWidth, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_MARGIN)
            defaults.setValue(self.previewWindowScale, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_WINDOW_SCALE)
            defaults.setValue(self.thumbnailMatchFinderMode, forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MATCH_MODE)
        }
    }


    /**
     Called by the app at launch to register its initial defaults.

     MOVED HERE 2.2.3

     - Paramters:
        - suite:   The app suite name.
        - version: The app version number.
     */
    func registerSettings(_ suite: String, _ version: String) {

        if let defaults = UserDefaults(suiteName: suite) {
            // Check if each preference value exists -- set if it doesn't
            // Preview body font size, stored as a CGFloat
            // Default: 16.0
            let codeFontSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            if codeFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.DEFAULTS.FONT_SIZE),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            }
            
            // Font for previews and thumbnails
            // Default: Menlo
            let codeFontName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
            if codeFontName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULTS.FONT,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
            }
            
            // FROM 1.3.0
            // Line spacing
            // Default: 1.0
            let lineSpacing:Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            if lineSpacing == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULTS.LINE_SPACING,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            }
            
            // FROM 1.3.0
            // Establish new defaults to store light and dark theme names.
            // But check for an existing one so the user's choice is at least
            // partially maintained, ie. if they selected a dark theme before, that
            // will become the chosen dark them now
            let newDarkThemeName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            if newDarkThemeName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULTS.DARK_THEME,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME)
            }
            
            let newLightThemeName: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            if newLightThemeName == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DEFAULTS.LIGHT_THEME,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME)
            }
            
            let defaultDisplayMode: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            if defaultDisplayMode == nil {
                defaults.setValue(BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            }
            
            // Show the What's New sheet
            // Default: true
            // This is a version-specific preference suffixed with, eg, '-2-3'. Once created
            // this will persist, but with each new major and/or minor version, we make a
            // new preference that will be read by 'doShowWhatsNew()' to see if the sheet
            // should be shown this run
            let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + version
            let showNewDefault: Any? = defaults.object(forKey: key)
            if showNewDefault == nil {
                defaults.setValue(true, forKey: key)
            }
            
            // FROM 2.0.0
            // Do we show line numbers on previews?
            // Default: No
            let showLineNumbers: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_LINE_NUMBERS)
            if showLineNumbers == nil {
                defaults.setValue(false,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_LINE_NUMBERS)
            }
            
            // FROM 2.2.3
            // Thumbnail should match macOS mode
            if defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MATCH_MODE) == nil {
                defaults.setValue(false, forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MATCH_MODE)
            }
            
            // Preview window scale factor (fraction of main screen size)
            if defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_WINDOW_SCALE) == nil {
                defaults.setValue(BUFFOON_CONSTANTS.SCALERS.WINDOW_SIZE_L, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_WINDOW_SCALE)
            }
            
            // Preview inset margin width
            if defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN) == nil {
                defaults.setValue(false, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN)
            }

            // Preview inset margin width
            if defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_MARGIN) == nil {
                defaults.setValue(BUFFOON_CONSTANTS.PREVIEW_MARGIN_WIDTH, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_MARGIN)
            }
        }
    }
}
