/*
 *  Common.swift
 *  PreviewCode
 *  Code common to Code Previewer and Code Thumbnailer
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */

import Foundation
import Highlightr
import AppKit



// Use defaults for some user-selectable values
private var codeTheme: String = BUFFOON_CONSTANTS.DEFAULT_THEME
private var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
private var fontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT
private var fontBase: NSFont = NSFont.systemFont(ofSize: fontSize)
private var backgroundColour: NSColor = NSColor.black
private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME

private var errAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor.red,
    .font: fontBase
]


// MARK: Primary Function

func getAttributedString(_ codeFileString: String, _ language: String, _ isThumbnail: Bool) -> NSAttributedString {

    // Use Highlightr to render the input source file as an NSAttributedString, which is returned.

    // Parse the code file
    var renderedString: NSAttributedString? = nil
    
    if let highlightr: Highlightr = Highlightr.init() {
        highlightr.setTheme(to: codeTheme)
        backgroundColour = highlightr.theme.themeBackgroundColor
        highlightr.theme.setCodeFont(fontBase)
        renderedString = highlightr.highlight(codeFileString, as: language)
    }
    
    // If the rendered string is good, return it
    if let rs: NSAttributedString = renderedString {
        // Trap any incorrectly parsed language names
        if (rs.string != "undefined") {
            return rs
        }
    }
    
    // Return an error message
    return NSAttributedString.init(string: "Could not render source code (\(language))", attributes: errAtts)
}


// MARK: Formatting Functions

func setBaseValues(_ isThumbnail: Bool) {

    // Set common base style values for the source code render
    // NOTE This should now be called only ONCE, before the code is rendered

    // The suite name is the app group name, set in each extension's entitlements, and the host app's
    if let defaults = UserDefaults(suiteName: appSuiteName) {
        defaults.synchronize()
        fontSize = CGFloat(isThumbnail
                           ? defaults.float(forKey: "com-bps-previewcode-thumb-font-size")
                           : defaults.float(forKey: "com-bps-previewcode-base-font-size"))
        codeTheme   = defaults.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME
        fontName    = defaults.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT
    }

    // Just in case the above block reads in zero values
    if fontSize < 1.0 || fontSize > 28.0 {
        fontSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    }

    // Set a specific theme for thumbnails
    if isThumbnail {
        codeTheme = "xcode"
    }

    // Set the font and its sizes
    if let chosenFont: NSFont = NSFont.init(name: fontName, size: fontSize) {
        fontBase = chosenFont
    } else {
        fontBase = NSFont.systemFont(ofSize: fontSize)
    }
    
    // Set the error format to the font chosen by the user
    errAtts = [
        .foregroundColor: NSColor.red,
        .font: fontBase
    ]
}


func getLanguage(_ sourceFilePath: String) -> String {
    
    // Determine the source file's language, and return
    // it as a string, eg. 'public.swift-source' -> 'swift'
    
    var sourceLanguage: String = "public.swift-source"
    let sourceFileUTI: String = getSourceFileUTI(sourceFilePath)
    
    // Trap 'non-standard' UTIs
    if sourceFileUTI.hasPrefix("com.apple.applescript") {
        return "applescript"
    }
    
    if sourceFileUTI == "public.script" {
        return "bash"
    }
    
    if sourceFileUTI == "public.css" {
        return "css"
    }
    
    let parts = sourceFileUTI.components(separatedBy: ".")
    if parts.count > 0 {
        let index: Int = parts.count - 1
        var endIndex: Range<String.Index>? = parts[index].range(of: "-source")
        if endIndex == nil { endIndex = parts[index].range(of: "-header") }
        if endIndex == nil { endIndex = parts[index].range(of: "-script") }
        
        if let anEndIndex = endIndex {
            sourceLanguage = String(parts[index][..<anEndIndex.lowerBound])
        }
    }
    
    // Address those languages that are referenced slightly differently
    // in highlight.js, eg. 'objective-c' -> 'objectivec'
    if sourceLanguage == "objective-c" || sourceLanguage == "objective-c-plus-plus" {
        return "objectivec"
    }
    
    if sourceLanguage == "shell" || sourceLanguage == "zsh" ||
        sourceLanguage == "csh" || sourceLanguage == "tcsh" ||
        sourceLanguage == "ksh" {
        return "bash"
    }
    
    if sourceLanguage == "toml" {
        return "ini"
    }
    
    if sourceLanguage == "pascal" {
        return "delphi"
    }
    
    if sourceLanguage == "assembly" {
        return "armasm"
    }
    
    return sourceLanguage
}


func getSourceFileUTI(_ sourceFilePath: String) -> String {
    
    // Get the passed code file's UTI - we'll use it to]
    // determine the programming language
    
    var sourceFileUTI: String = ""
    
    // Just in case, but this shouldn't be necessary
    // (we wouldn't have got this far otherwise)
    if FileManager.default.fileExists(atPath: sourceFilePath) {
        // Create a URL reference to the sample file
        let sourceFileURL = URL.init(fileURLWithPath: sourceFilePath)
        
        do {
            // Read back the UTI from the URL
            if let uti = try sourceFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                sourceFileUTI = uti
            }
        } catch {
            // NOP
        }
    }
    
    return sourceFileUTI
}


func getStyle() -> String {
    
    // Simple getter
    
    return codeTheme
}


func getBackgroundColour() -> NSColor {
    
    // Simple getter
    
    return backgroundColour
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



