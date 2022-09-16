/*
 *  GenericFontExtensions.swift
 *  PreviewApps
 *
 *  These functions can be used by all PreviewApps
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2022 Tony Smith. All rights reserved.
 */


import Foundation
import Cocoa
import WebKit
import UniformTypeIdentifiers


extension AppDelegate {

    // MARK: - Font Management

    /**
     Build a list of available fonts.

     Should be called asynchronously. Two sets created: monospace fonts and regular fonts.
     Requires 'bodyFonts' and 'codeFonts' to be set as instance properties.
     Comment out either of these, as required.

     The final font lists each comprise pairs of strings: the font's PostScript name
     then its display name.
     */
    internal func asyncGetFonts() {

        var cf: [PMFont] = []
        let monoTrait: UInt = NSFontTraitMask.fixedPitchFontMask.rawValue
        let fm: NSFontManager = NSFontManager.shared
        let families: [String] = fm.availableFontFamilies
        for family in families {
            // Remove known unwanted fonts
            if family.hasPrefix(".") || family == "Apple Braille" || family == "Apple Color Emoji" {
                continue
            }

            // For each family, examine its fonts for suitable ones
            if let fonts: [[Any]] = fm.availableMembers(ofFontFamily: family) {
                // This will hold a font family: individual fonts will be added to
                // the 'styles' array
                var familyRecord: PMFont = PMFont.init()
                familyRecord.displayName = family

                for font: [Any] in fonts {
                    let fontTraits: UInt = font[3] as! UInt
                    if monoTrait & fontTraits != 0 {
                        // The font is good to use, so add it to the list
                        var fontRecord: PMFont = PMFont.init()
                        fontRecord.postScriptName = font[0] as! String
                        fontRecord.styleName = font[1] as! String
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

        DispatchQueue.main.async {
            self.codeFonts = cf
        }
    }
    
    
    /**
     Build and enable the font style popup.

     - Parameters:
        - styleName: The name of currently selected style, or nil to select the first one.
     */
    internal func setStylePopup(_ styleName: String? = nil) {
        
        if let selectedFamily: String = self.codeFontPopup.titleOfSelectedItem {
            self.codeStylePopup.removeAllItems()
            for family: PMFont in self.codeFonts {
                if selectedFamily == family.displayName {
                    if let styles: [PMFont] = family.styles {
                        self.codeStylePopup.isEnabled = true
                        for style: PMFont in styles {
                            self.codeStylePopup.addItem(withTitle: style.styleName)
                        }

                        if styleName != nil {
                            self.codeStylePopup.selectItem(withTitle: styleName!)
                        }
                    }
                }
            }
        }
    }

    
    /**
     Select the font popup using the stored PostScript name
     of the user's chosen font.
     
     - Parameters:
        - postScriptName: The PostScript name of the font.
     */
    internal func selectFontByPostScriptName(_ postScriptName: String) {

        for family: PMFont in self.codeFonts {
            if let styles: [PMFont] = family.styles {
                for style: PMFont in styles {
                    if style.postScriptName == postScriptName {
                        self.codeFontPopup.selectItem(withTitle: family.displayName)
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

        if let selectedFont: String = self.codeFontPopup.titleOfSelectedItem {
            let selectedStyle: Int = codeStylePopup.indexOfSelectedItem
            for family: PMFont in self.codeFonts {
                if family.displayName == selectedFont {
                    if let styles: [PMFont] = family.styles {
                        let font: PMFont = styles[selectedStyle]
                        return font.postScriptName
                    }
                }
            }
        }

        return nil
    }
}
