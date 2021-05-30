/*
 *  Common.swift
 *  PreviewYaml
 *  Code common to Yaml Previewer and Yaml Thumbnailer
 *
 *  Created by Tony Smith on 22/04/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */

import Foundation
import Highlightr
import AppKit



// Use defaults for some user-selectable values
private var doShowLightBackground: Bool = false
private var codeTheme: String = "atom-one-light"
private var fontBaseSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)


// YAML string attributes...
private var keyAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: getColour(0),
    .font: NSFont.systemFont(ofSize: fontBaseSize)
]

// String artefacts...
private var hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                                    attributes: [.strikethroughStyle: NSUnderlineStyle.patternDot.rawValue,
                                                 .strikethroughColor: NSColor.labelColor])
private var newLine: NSAttributedString = NSAttributedString.init(string: "\n", attributes: keyAtts)


// MARK: Primary Function

func getAttributedString(_ codeFileString: String, _ language: String, _ isThumbnail: Bool) -> NSAttributedString {

    // Use YamlSwift to render the input YAML as an NSAttributedString, which is returned.
    // NOTE Set the font colour according to whether we're rendering a thumbail or a preview
    //      (thumbnails always rendered black on white; previews may be the opposite [dark mode])

    // Set up the base string
    var renderedString: NSAttributedString?
    
    // Parse the code file
    if let highlightr: Highlightr = Highlightr() {
        highlightr.setTheme(to: codeTheme)
        renderedString = highlightr.highlight(codeFileString, as: language)
    }
    
    if let rs: NSAttributedString = renderedString {
        return rs
    } else {
        return NSAttributedString.init(string: "Could not render source code", attributes: keyAtts)
    }
}


// MARK: Formatting Functions

func setBaseValues(_ isThumbnail: Bool) {

    // Set common base style values for the markdown render
    // NOTE This should now be called only once

    // The suite name is the app group name, set in each extension's entitlements, and the host app's
    if let defaults = UserDefaults(suiteName: MNU_SECRETS.PID + ".suite.preview-code") {
        defaults.synchronize()
        fontBaseSize = CGFloat(isThumbnail
                              ? defaults.float(forKey: "com-bps-previewcode-thumb-font-size")
                              : defaults.float(forKey: "com-bps-previewcode-base-font-size"))
        doShowLightBackground = defaults.bool(forKey: "com-bps-previewcode-do-use-light")
        codeTheme = defaults.string(forKey: "com-bps-previewcode-code-theme") ?? "atom-one-light"
    }

    // Just in case the above block reads in zero values
    // NOTE The other valyes CAN be zero
    if fontBaseSize < 1.0 || fontBaseSize > 28.0 {
        fontBaseSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    }

    // Set the YAML key:value fonts and sizes
    var font: NSFont
    if codeFontIndex == 0 {
        font = NSFont.systemFont(ofSize: fontBaseSize)
    } else {
        if let otherFont = NSFont.init(name: codeFonts[codeFontIndex], size: fontBaseSize) {
            font = otherFont
        } else {
            font = NSFont.systemFont(ofSize: fontBaseSize)
        }
    }
    
    keyAtts = [
        .foregroundColor: getColour(0),
        .font: font
    ]
    
    hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                            attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                                         .strikethroughColor: (isThumbnail || doShowLightBackground ? NSColor.black : NSColor.white)])
    
    newLine = NSAttributedString.init(string: "\n",
                                      attributes: keyAtts)
}


func getColour(_ index: Int) -> NSColor {

    // Return the colour from the selection

    switch index {
        case 0:
            return NSColor.systemPurple
        case 1:
            return NSColor.systemBlue
        case 2:
            return NSColor.systemRed
        case 3:
            return NSColor.systemGreen
        case 4:
            return NSColor.systemOrange
        case 5:
            return NSColor.systemPink
        case 6:
            return NSColor.systemTeal
        case 7:
            return NSColor.systemBrown
        case 8:
            return NSColor.systemYellow
        case 9:
            return NSColor.systemIndigo
        default:
            return NSColor.systemGray
    }
}
    

func setError(_ code: Int) -> NSError {
    
    // NSError generation function
    
    var errDesc: String
    
    switch(code) {
    case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_INACCESSIBLE
    case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_WONT_OPEN
    case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_TS_STRING
    case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_MD_STRING:
        errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_MD_STRING
    default:
        errDesc = "UNKNOWN ERROR"
    }

    let bundleID = Bundle.main.object(forInfoDictionaryKey: "CFBundleID") as! String
    return NSError(domain: bundleID,
                   code: code,
                   userInfo: [NSLocalizedDescriptionKey: errDesc])
}


func getLanguage(_ path: String) -> String {
    
    var sourceLanguage: String = "public.swift-source"
    let sourceUTI: String = getSourceFileUTI(path)
    let parts = sourceUTI.components(separatedBy: ".")
    if parts.count > 0 {
        if let endIndex = parts[1].range(of: "-source")?.lowerBound {
            sourceLanguage = String(parts[1][..<endIndex])
        }
    }
    
    return sourceLanguage
}


func getSourceFileUTI(_ path: String) -> String {
    
    // This is not PII. It used solely for debugging purposes
    
    var sourceUTI: String = "UNKNOWN"
    if FileManager.default.fileExists(atPath: path) {
        // Create a URL reference to the sample file
        let fileURL = URL.init(fileURLWithPath: path)
        
        do {
            // Read back the UTI from the URL
            if let uti = try fileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                sourceUTI = uti
            }
        } catch {
            // NOP
        }
    }
    
    return sourceUTI
}


