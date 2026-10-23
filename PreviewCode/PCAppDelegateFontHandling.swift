/*
 *  PCAppDelegateFontHandling.swift
 *  PreviewCode
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2026 Tony Smith. All rights reserved.
 */

import AppKit
import WebKit


extension AppDelegate {

    // MARK: - Font Management

    /**
     Build a list of available fonts.

     Should be called asynchronously. Two sets created: monospace fonts and regular fonts.
     Requires `bodyFonts` and `codeFonts` to be set as instance properties.
     Comment out either of these, as required.

     The final font lists each comprise pairs of strings: the font's PostScript name
     then its display name.
     */
    internal func asyncGetFonts() {

        var cf: [PAFont] = []

        let monoTrait = NSFontTraitMask.fixedPitchFontMask.rawValue

        let fm = NSFontManager.shared
        let families = fm.availableFontFamilies
        for family in families {
            // Remove known unwanted fonts
            if family.hasPrefix(".") || family == "Apple Braille" || family == "Apple Color Emoji" {
                continue
            }

            // For each family, examine its fonts for suitable ones
            if let fonts = fm.availableMembers(ofFontFamily: family) {
                // This will hold a font family: individual fonts will be added to
                // the 'styles' array
                var familyRecord = PAFont()
                familyRecord.displayName = family

                for font in fonts {
                    let fontTraits = font[3] as? UInt ?? 0
                    if monoTrait & fontTraits != 0 {
                        var fontRecord = PAFont()
                        // We can be fairly sure the following a typeable as described
                        fontRecord.postScriptName = font[0] as? String ?? "error"
                        fontRecord.styleName = font[1] as? String ?? "error"
                        fontRecord.traits = fontTraits

                        if familyRecord.styles == nil {
                            familyRecord.styles = []
                        }

                        familyRecord.styles!.append(fontRecord)
                    }
                }

                if familyRecord.styles != nil && familyRecord.styles!.count > 0 {
                    cf.append(familyRecord)
                }
            }
        }

        // All done, update the main stores and begin to load
        // settings (which immediately updates the UI, via `displaySettings()`,
        // which itself requires the font store to be populated
        // FROM 2.2.4 - Switch to Swift Concurrency
        Task {
            // Run task on main thread

            /*
            // This version runs the closure on the main thread immediately,
            // blocking it until the closure completes
            await MainActor.run {
                self.fonts = cf
                self.loadSettings()
            }
             */

            // This version adds the closure to the main thread queue, so runs
            // when the main thread becomes free
            @MainActor in
                self.fonts = cf
                self.loadSettings()
        }
    }
    
    
    /**
     Build and enable the font style popup.

     - Parameters:
        - styleName: The name of currently selected style, or nil to select the first one.
     */
    internal func setStylePopup(_ styleToSelect: String? = nil) {
        
        if let selectedFamily = self.fontNamePopup.titleOfSelectedItem {
            self.fontFacePopup.removeAllItems()
            for family in self.fonts {
                if selectedFamily == family.displayName {
                    if let styles = family.styles {
                        self.fontFacePopup.isEnabled = true
                        for style in styles {
                            self.fontFacePopup.addItem(withTitle: style.styleName)
                        }

                        if styleToSelect != nil {
                            // Select an existing style, if we can
                            // NOTE This will deselect the menu if the selected font lacks the
                            //      currently selected file, eg. we go from Roboto Mono ExtraLight
                            //      to Andale (Regular only). So check and select the first style
                            //      on the list if that happens.
                            self.fontFacePopup.selectItem(withTitle: styleToSelect!)
                            if self.fontFacePopup.indexOfSelectedItem == -1 {
                                self.fontFacePopup.selectItem(at: 0)
                            }
                        } else {
                            // No style passed? Pick the first on the list (usually Regular)
                            self.fontFacePopup.selectItem(at: 0)
                        }
                        
                        return
                    }
                }
            }
        }
        
        // FROM 1.2.5
        // No style selected? Choose the default
        if self.fontFacePopup.indexOfSelectedItem == -1 {
            self.fontFacePopup.selectItem(at: 0)
        }
    }

    
    /**
     Select the font popup using the stored PostScript name
     of the user's chosen font.
     
     - Parameters:
        - postScriptName: The PostScript name of the font.
     */
    internal func selectFontByPostScriptName(_ postScriptName: String) {

        for family in self.fonts {
            if let styles = family.styles {
                for style in styles {
                    if style.postScriptName == postScriptName {
                        self.fontNamePopup.selectItem(withTitle: family.displayName)
                        setStylePopup(style.styleName)
                    }
                }
            }
        }
    }

    
    /**
     Get the PostScript name from the selected family and style.
     
     - Returns: The PostScript name as a string, or nil.
     */
    internal func getPostScriptName() -> String? {

        if let selectedFont = self.fontNamePopup.titleOfSelectedItem {
            let selectedStyle = fontFacePopup.indexOfSelectedItem

            // FROM 2.3.3 -- bail if there's no popup selection
            guard selectedStyle >= 0 else { return nil }

            for family in self.fonts {
                if family.displayName == selectedFont {
                    if let styles = family.styles {
                        if selectedStyle < styles.count {
                            let font = styles[selectedStyle]
                            return font.postScriptName
                        }
                    }
                }
            }
        }

        return nil
    }
}
