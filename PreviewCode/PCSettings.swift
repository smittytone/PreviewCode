/*
 *  PCSettings.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 08/10/2024.
 *  Copyright © 2025 Tony Smith. All rights reserved.
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
        }
    }
}
