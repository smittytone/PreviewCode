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

    // Savable Settings
    var fontName: String                    = BUFFOON_CONSTANTS.DEFAULT_FONT
    var fontSize: CGFloat                   = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    var lineSpacing: CGFloat                = BUFFOON_CONSTANTS.DEFAULT_LINE_SPACING
    var darkThemeName: String               = BUFFOON_CONSTANTS.DEFAULT_THEME_DARK
    var lightThemeName: String              = BUFFOON_CONSTANTS.DEFAULT_THEME_LIGHT
    var themeDisplayMode: Int               = BUFFOON_CONSTANTS.DISPLAY_MODE.AUTO
    // FROM 2.0.0
    var doShowMargin: Bool                  = false

    // Non-saved Settings
    var lightThemeIndex: Int                = 0
    var newLightThemeIndex: Int             = 0
    var darkThemeIndex: Int                 = 0
    var newDarkThemeIndex: Int              = 0

    // UNUSED
    var thumbFontSize: CGFloat              = CGFloat(BUFFOON_CONSTANTS.BASE_THUMBNAIL_FONT_SIZE)
    var themeName: String                   = BUFFOON_CONSTANTS.DEFAULT_THEME
    var useLight: Bool                      = false


    /**
     Populate the current settings value with those read from disk.
     */
    func loadSettings(_ suite: String) {
        
        // The suite name is the app group name, set in each extension's entitlements, and the host app's
        if let defaults = UserDefaults(suiteName: suite) {
            self.fontName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_FONT
            self.fontSize = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE))
            self.lineSpacing = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING))
            self.darkThemeName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_DARK_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_THEME_DARK
            self.lightThemeName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LIGHT_NAME) ?? BUFFOON_CONSTANTS.DEFAULT_THEME_LIGHT
            self.themeDisplayMode = defaults.integer(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_THEME_MODE)
            //self.useLight = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            //self.doShowMargin = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN)
        }
    }


    /**
     Write Settings page state values to disk, but only those that have been changed.
     If this happens, also update the current settings store
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
            //defaults.setValue(self.useLight, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            //defaults.setValue(self.doShowMargin, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_SHOW_MARGIN)
        }
    }
}
