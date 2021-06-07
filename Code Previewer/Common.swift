/*
 *  Common.swift
 *  PreviewCode
 *  Code common to Code Previewer and Code Thumbnailer
 *
 *  Created by Tony Smith on 30/05/2021.
 *  Copyright © 2021 Tony Smith. All rights reserved.
 */


import Foundation
import AppKit
import Highlightr


// Use defaults for some user-selectable values
private var theme: String = BUFFOON_CONSTANTS.DEFAULT_THEME
private var themeBackgroundColor: NSColor = NSColor.black
private var isThemeDark: Bool = false

private var font: NSFont = NSFont.init(name: fontName, size: fontSize)!
private var fontSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.THEME_PREVIEW_FONT_SIZE)
private var fontName: String = BUFFOON_CONSTANTS.DEFAULT_FONT

private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
private var errAtts: [NSAttributedString.Key: Any] = [
    .foregroundColor: NSColor.red,
    .font: font
]
private var highlighter: Highlightr? = nil



// MARK:- Primary Function

func getAttributedString(_ codeFileString: String, _ language: String, _ isThumbnail: Bool) -> NSAttributedString {

    // Use Highlightr to render the input source file as an NSAttributedString, which is returned.
    
    // Run the specified code string through Highlightr/Highlight.js
    var renderedString: NSAttributedString? = nil
    
    if let highlightr: Highlightr = Highlightr.init() {
        highlightr.setTheme(to: theme)
        highlightr.theme.setCodeFont(font)
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


// MARK:- Formatting Functions

func setThemeValues(_ themeData: String) {
    
    // We record in prefs a string combinining the theme's Highlight.js name
    // and its 'mode' (light or dark), so we need to call this function at some
    // point to extract these two data points.
    //
    // It shuld be called before rendering, so we're not rewriting the values, with
    // the threading issues that raises. This is called by 'setBaseValues()' and
    // 'AppDelegate' (frequently, once for each theme)
    let themeParts: [String] = themeData.components(separatedBy: ".")
    theme = themeParts[1]
    isThemeDark = (themeParts[0] == "dark")

    // Set the background colour here
    if let highlightr: Highlightr = Highlightr.init() {
        highlightr.setTheme(to: theme)
        themeBackgroundColor = highlightr.theme.themeBackgroundColor
    }
}


func setBaseValues(_ isThumbnail: Bool) {

    // Set common base style values for the source code render
    // NOTE This should now be called only ONCE, before the code is rendered

    // The suite name is the app group name, set in each extension's entitlements, and the host app's
    if let defaults = UserDefaults(suiteName: appSuiteName) {
        // Read back the theme and typeface prefs
        defaults.synchronize()
        fontSize = CGFloat(isThumbnail
                           ? defaults.float(forKey: "com-bps-previewcode-thumb-font-size")
                           : defaults.float(forKey: "com-bps-previewcode-base-font-size"))
        fontName = defaults.string(forKey: "com-bps-previewcode-base-font-name") ?? BUFFOON_CONSTANTS.DEFAULT_FONT

        // NOTE We store the raw theme name, so 'setThemeValues()' is called
        //      to extract the actual name and its mode (light or dark)
        setThemeValues(defaults.string(forKey: "com-bps-previewcode-theme-name") ?? BUFFOON_CONSTANTS.DEFAULT_THEME)
    }

    // Just in case the above block reads in zero values
    if fontSize < BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0] ||
        fontSize > BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1] {
        fontSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    }

    // Choose a specific theme values for thumbnails
    if isThumbnail {
        setThemeValues(BUFFOON_CONSTANTS.DEFAULT_THUMB_THEME)
        fontSize = CGFloat(BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE)
    }

    // Generate the font we'll use, at the required size
    if let chosenFont: NSFont = NSFont.init(name: fontName, size: fontSize) {
        font = chosenFont
    } else {
        font = NSFont.systemFont(ofSize: fontSize)
    }
    
    // Set the error format attributes to the font chosen by the user
    errAtts = [
        .foregroundColor: NSColor.red,
        .font: font
    ]
}


func getMode() -> Bool {
    
    // Simple getter
    
    return isThemeDark
}


func getBackgroundColour() -> NSColor {
    
    // Simple getter

    return themeBackgroundColor
}


// MARK: - Utility Functions

func getLanguage(_ sourceFilePath: String, _ isForTag: Bool) -> String {

    // Determine the source file's language, and return
    // it as a string, eg. 'public.swift-source' -> 'swift'.
    //
    // If 'isForTag' is true, it returns the actual name of the language,
    // not the naming used by Highlight.js, which it returns if 'isForTag'
    // is false. This is because these are not always the same
    // eg. 'c++' vs 'cpp', or 'pascal' vs 'delphi'

    let sourceFileUTI: String = getSourceFileUTI(sourceFilePath)
    let sourceFileExtension: String = (sourceFilePath as NSString).pathExtension

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

    var sourceLanguage: String = BUFFOON_CONSTANTS.DEFAULT_LANGUAGE_UTI
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
    // in highlight.js, eg. 'objective-c' -> 'objectivec'; are accessed
    // as aliases, eg. 'pascal' -> 'delphi'; or all use the same language,
    // eg. all shells -> 'bash'
    switch(sourceLanguage) {
    case "objective-c":
        sourceLanguage = isForTag ? "obj-c" : "objectivec"
    case "objective-c-plus-plus":
        sourceLanguage = isForTag ? "obj-c++" : "objectivec"
    case "c-plus-plus":
        sourceLanguage = isForTag ? "c++" : "cpp"
    case "shell", "zsh", "csh", "ksh", "tsch":
        if !isForTag { sourceLanguage = "bash" }
    case "pascal":
        if !isForTag { sourceLanguage = "delphi" }
    case "assembly":
        if sourceFileExtension == "s" { sourceLanguage = isForTag ? "arm" : "armasm" }
        if sourceFileExtension == "asm" { sourceLanguage = isForTag ? "x86-64" : "x86asm" }
    case "nasm-assembly":
        sourceLanguage = isForTag ? "x86-64" : "x86asm"
    default:
        // NOP
        break
    }

    return sourceLanguage
}


func getSourceFileUTI(_ sourceFilePath: String) -> String {
    
    // Get the passed code file's UTI - we'll use it to
    // determine the file's programming language

    // Create a URL reference to the sample file
    var sourceFileUTI: String = ""
    let sourceFileURL = URL.init(fileURLWithPath: sourceFilePath)

    do {
        // Read back the UTI from the URL
        // NOTE '.typeIdentifier' yields an optional
        if let uti = try sourceFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
            sourceFileUTI = uti
        }
    } catch {
        // NOP
    }
    
    return sourceFileUTI
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


